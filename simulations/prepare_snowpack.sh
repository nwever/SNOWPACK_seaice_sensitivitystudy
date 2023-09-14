setup_model () {
	inifile=./cfgfiles/io_C0_${experiment}.ini

	#
	# Create sno file
	#
	python3 create_snofile.py -stn mosseb_level2v3seaice_CO -lat 85.618 -lon 125.832 -nodata -999 -date 2019-10-31T00:00 -s1 0 -s2 40 -s3 60 -s4 90 > ./input/C0_${experiment}.sno

	#
	# Create ini file
	#
	echo "IMPORT_BEFORE		=	./io_base.ini" > ${inifile}
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


# Default experiment
experiment=DFLT
setup_model
