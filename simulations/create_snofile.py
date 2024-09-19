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


def calcbrinesal(thermalmodel, T):
	Tc = T - 273.15
	if (thermalmodel == "IGNORE"):
		sys.stderr.write(__file__ + ": function calcbrinesal() should not be called for thermal model \"IGNORE\", as, in that case, brine salinity is fully independent from temperature.\n")
		quit()
	elif (thermalmodel == "ASSUR1958"):
		# See: Assur, A., Composition of sea ice and its tensile strength, in Arctic Sea Ice, N.  A.  S. N.  R.  C. Publ., 598, 106-138, 1958.
		return Tc / (-0.054)
	elif (thermalmodel == "VANCOPPENOLLE2019"):
		# See Eq. 10 in: Vancoppenolle, M., Madec, G., Thomas, M., & McDougall, T. J. (2019). Thermodynamics of sea ice phase composition revisited. Journal of Geophysical Research: Oceans, 124, 615–634. doi: 10.1029/2018JC014611 
		a1 = -0.00535
		a2 = -0.519
		a3 = -18.7
		return a1*Tc*Tc*Tc + a2*Tc*Tc + a3*Tc
	elif (thermalmodel == "VANCOPPENOLLE2019_M"):
		# A quadratic fit to Eq. 10 in Vancoppenolle et al. (2019)
		a1 = -0.16055612425953938
		a2 = -13.296596377964793
		return a1*Tc*Tc + a2*Tc
	else:
		sys.stderr.write(__file__ + ": Unknown thermal model specified.\n")
		quit()


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
parser.add_argument('-bulk_sal', nargs=1, default=nodata)
parser.add_argument('-thermalmodel', nargs=1, default="ASSUR1958")	# Options are: ASSUR1958, VANCOPPENOLLE2019 or VANCOPPENOLLE2019_M
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

if args.bulk_sal is not None:
	bulk_sal = int(args.bulk_sal[0])

if args.thermalmodel is not None:
	thermalmodel = args.thermalmodel[0]

if args.marksnowiceinterface is False:
	mark = False
else:
	mark = True


WriteHeader()
if (s4 == 0 and s3 == 0 and s2 == 0 and s1 == 0):
	exit


t_bot=-1.85+273.15
t_top=-10+273.15


# Now calculate total weight:
mass = 0
n = 0
for i in range(s4,s3,-1):
	temp = temperature(i, t_bot, t_top, (s4 - s1))
	if (thermalmodel == "IGNORE"):
		theta_water = 0.05	# Just assume a liquid water content
		brine_sal = bulk_sal / theta_water
	else:
		brine_sal = calcbrinesal(thermalmodel, temp)
		theta_water = bulk_sal / brine_sal
	#if theta_water > 0.1:
	#	theta_water = 0.1
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

	#Calculate other variables given the bulk_sal
	if (thermalmodel == "IGNORE"):
		theta_water = 0.05	# Just assume a liquid water content
		brine_sal = bulk_sal / theta_water
	else:
		brine_sal = calcbrinesal(thermalmodel, temp)
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

	#if theta_water > 0.1:
	#	theta_water = 0.1
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




