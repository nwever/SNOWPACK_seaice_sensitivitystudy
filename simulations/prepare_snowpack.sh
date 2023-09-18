setup_model () {
	inifile=./cfgfiles/io_C0_${experiment}.ini

	#
	# Create sno file
	#
	domain=($(echo ${ice_thickness_below_sealevel} ${ice_thickness_above_sealevel} ${snow_thickness} | mawk -v L=${layer_thickness} '{print 0, $3/L, ($2+$3)/L, ($1+$2+$3)/L}'))
	python3 create_snofile.py -stn mosseb_level2v3seaice_CO -lat ${lat} -lon ${lon} -nodata ${nodata} -date 2019-10-31T00:00 -s1 ${domain[0]} -s2 ${domain[1]} -s3 ${domain[2]} -s4 ${domain[3]} > ./input/C0_${experiment}.sno

	#
	# Create ini file
	#
	echo "IMPORT_BEFORE	=	./io_base.ini" > ${inifile}
	echo "" >> ${inifile}
	echo "[INPUT]" >> ${inifile}
	echo "STATION1		=	seaice_CO1.smet" >> ${inifile}
	echo "SNOWFILE1		=	C0_${experiment}.sno" >> ${inifile}
	echo "" >> ${inifile}
	echo "[OUTPUT]" >> ${inifile}
	echo "EXPERIMENT	=	${experiment}" >> ${inifile}

	#
	# Add SNOWPACK run command
	#
	> to_exec.lst
	echo "snowpack -b 2019-11-01T00:00 -c ${inifile} -e NOW" >> to_exec.lst
}


# Location settings
lat=85.618
lon=125.832
nodata=-999


# Default settings
ice_thickness_below_sealevel=60		# in cm
ice_thickness_above_sealevel=20		# in cm
snow_thickness=20			# in cm
layer_thickness=2.0			# in cm, 2 cm is the assumption in create_snofile.py


# Default experiment
experiment=DFLT
setup_model
