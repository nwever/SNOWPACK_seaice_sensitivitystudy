#!/usr/bin/python
from __future__ import print_function
import sys, os
import argparse
import inspect
import numpy as np

from numpy import pi
from numpy import arctan
from numpy import arctan2
from numpy import sqrt

#
# Settings
#
nodata = -999			# Value indicating nodata


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def UsageMessage(errmsg):
	"""Displays a usage message."""
	sys.stderr.write(__file__ + ": This program generates a consistent *.sno file for sea ice simulations.\n")
	sys.stderr.write("  Provide the required settings.\n")
	quit()


def WriteHeader():
	sys.stdout.write("SMET 1.1 ASCII\n")
	sys.stdout.write("[HEADER]\n")
	sys.stdout.write("station_id    = " + stn + "\n")
	sys.stdout.write("station_name  = " + stn + "\n")
	sys.stdout.write("latitude      = " + str(lat) + "\n")
	sys.stdout.write("longitude     = " + str(lon) + "\n")
	sys.stdout.write("altitude      = 0\n")
	sys.stdout.write("nodata        = " + str(nodata) + "\n")
	sys.stdout.write("tz            = 1\n")
	sys.stdout.write("source        = AWI and SLF\n")
	sys.stdout.write("ProfileDate   = " + str(date) + "\n")
	sys.stdout.write("HS_Last       = 0\n")
	sys.stdout.write("SlopeAngle    = 0\n")
	sys.stdout.write("SlopeAzi      = 0\n")
	sys.stdout.write("nSoilLayerData= 0\n")
	sys.stdout.write("nSnowLayerData= " + str(int(s4-s1)) + "\n")
	sys.stdout.write("SoilAlbedo    = 0.09\n")
	sys.stdout.write("BareSoil_z0   = 0.2\n")
	sys.stdout.write("CanopyHeight   = " + str((s4-s3)*0.02) + "\n")
	sys.stdout.write("CanopyLeafAreaIndex = 0\n")
	sys.stdout.write("CanopyDirectThroughfall = 1\n")
	sys.stdout.write("WindScalingFactor = 1\n")
	sys.stdout.write("ErosionLevel      = 0\n")
	sys.stdout.write("TimeCountDeltaHS  = 0\n")
	sys.stdout.write("fields        = timestamp Layer_Thick  T  Vol_Frac_I  Vol_Frac_W  Vol_Frac_V  Vol_Frac_S Rho_S Conduc_S HeatCapac_S  rg  rb  dd  sp  mk mass_hoar ne CDot metamo Sal h\n")
	sys.stdout.write("[DATA]\n")


def temperature(z, t_bot, t_top, h):
	# Linear interpolation
	return t_top + (t_bot - t_top) * (z / h)


# Check command line parameters
parser = argparse.ArgumentParser(description='Create sno file for sea ice.')
parser.error = UsageMessage
parser.add_argument('-stn', nargs=1, default=nodata)
parser.add_argument('-lat', nargs=1, default=nodata)
parser.add_argument('-lon', nargs=1, default=nodata)
parser.add_argument('-nodata', nargs=1, default=nodata)
parser.add_argument('-date', nargs=1, default=nodata)
parser.add_argument('-s1', nargs=1, default=nodata)
parser.add_argument('-s2', nargs=1, default=nodata)
parser.add_argument('-s3', nargs=1, default=nodata)
parser.add_argument('-s4', nargs=1, default=nodata)
parser.add_argument('--marksnowiceinterface', action="store_true", default=False)
args = parser.parse_args()


if args.stn is not None:
	stn = args.stn[0]

if args.lat is not None:
	lat = float(args.lat[0])

if args.lon is not None:
	lon = float(args.lon[0])

if args.date is not None:
	date = args.date[0]

if args.s1 is not None:
	s1 = int(args.s1[0])

if args.s2 is not None:
	s2 = int(args.s2[0])

if args.s3 is not None:
	s3 = int(args.s3[0])

if args.s4 is not None:
	s4 = int(args.s4[0])

if args.marksnowiceinterface is False:
	mark = False
else:
	mark = True


WriteHeader()
if (s4 == 0 and s3 == 0 and s2 == 0 and s1 == 0):
	exit


t_bot=-1.85
t_top=-10


# Now calculate total weight:
mass = 0
n = 0
for i in range(s4,s3,-1):
	temp = temperature(i, t_bot, t_top, (s4 - s1))
	bulk_sal = 2.0
	brine_sal = ((temp - 273.15) / -0.054)
	theta_water = bulk_sal / brine_sal
	if theta_water > 0.1:
		theta_water = 0.1
	theta_air = theta_water * (1000. / 917.) - theta_water
	theta_ice = 1. - theta_air - theta_water
	mass = mass + 0.02 * (917. * theta_ice + (1000. + 0.824 * brine_sal) * theta_water)

for i in range(s3,s2,-1):
	mass = mass + 917. * 0.95 * 0.02

for i in range(s2,s1,-1):
	mass = mass + 917. * 0.03 * 0.02

hbottom = mass / (1000. + 0.824 * 35.);
#hbottom = (s4 - s3) * 0.02

n = 0
ntot = 0
for i in range(s4,s3,-1):
	# Ice under water
	temp = temperature(i, t_bot, t_top, (s4 - s1))
	#When you want to apply a bulk salinity profile
	#if s4 - s3 == 1:
	#	bulk_sal = 1.5
	#else:
	#	bulk_sal = 3.0 - (s4 - i) * ((3.0 - 1.5) / (s4 - s3 - 1))

	# -- or --

	#When you want to apply a constant bulk salinity
	bulk_sal=1.75


	#Calculate other variables given the bulk_sal
	brine_sal = ((temp - 273.15) / -0.054)
	rho_2 = (1000. + 0.824 * brine_sal)
	theta_water = bulk_sal / brine_sal

	#Determine h for a constant bulk_sal
	if s4 - s3 - 1 > 0:
		h = hbottom - (s4 - i) * ( (hbottom - -0.006170506747972) / (s4 - s3 - 1))
	else:
		h = hbottom
	h = h * rho_2

	if theta_water == 0:
		h = -999
	#elif i == s4:
	#	h = (hbottom - 0.01) * rho_2	# +0.01 == center at the bottom element, which has depth 0.02
	#else:
	#	h = h - 0.02 * 0.5 * (rho_2 + rho_1)

	if theta_water > 0.1:
		theta_water = 0.1
	theta_air = theta_water * (1000. / 917.) - theta_water
	#if 1. - theta_air - theta_water > 0.99:
	#	theta_air = 0.01 - theta_water
	theta_ice = 1. - theta_air - theta_water

	if h == -999:
		#print(date, 0.02, temp[t_idx], theta_ice, theta_water, theta_air, "0.00 0.00 0.00 0.00 3.00 2.00 1.00 0.00 7.00 0.00 1 0 0.00", bulk_sal, -999)
		print(date, 0.02, temp, "0.95 0.00 0.05 0.00 0.00 0.00 0.00 3.00 2.00 1.00 0.00 7.00 0.00 1 0 0.00 0 -999")
	else:
		if (h / rho_2 < -0.006170506747972):
			h_out = -0.006170506747972
		else:
			h_out = h / rho_2
		print(date, 0.02, temp, theta_ice, theta_water, theta_air, "0.00 0.00 0.00 0.00 3.00 2.00 1.00 0.00 7.00 0.00 1 0 0.00", bulk_sal, h_out)
		#print(date, 0.02, temp[t_idx], "0.95 0.00 0.05 0.00 0.00 0.00 0.00 3.00 2.00 1.00 0.00 7.00 0.00 1 0 0.00 0 -999")
	n = n + 1
	ntot = ntot + 1
	rho_1 = rho_2


for i in range(s3,s2,-1):
	# Ice above water
	temp = temperature(i, t_bot, t_top, (s4 - s1))
	if i==s3:
		print(date, 0.02, temp, "0.95 0.00 0.05 0.00 0.00 0.00 0.00 3.00 2.00 1.00 0.00 7.00 0.00 1 0 0.00 0.5 -999")
	else:
		print(date, 0.02, temp, "0.95 0.00 0.05 0.00 0.00 0.00 0.00 3.00 2.00 1.00 0.00 7.00 0.00 1 0 0.00 0 -999")
	ntot = ntot + 1
	n = n + 1

n = 0
for i in range(s2,s1,-1):
	# Snow
	temp = temperature(i, t_bot, t_top, (s4 - s1))
	if i == s2 and mark:
		mk = 9000
	else:
		mk = 0
	print(date, 0.02, temp, "0.3 0.00 0.7 0.00 0.00 0.00 0.00 0.15 0.09 0.00 0.00", mk, "0.00 1 0 0.00 0 -999")
	ntot = ntot + 1
	n = n + 1


if ntot != (s4 - s1):
	eprint("ntot!=(s4-s1): ", s1, s2, s3, s4)




