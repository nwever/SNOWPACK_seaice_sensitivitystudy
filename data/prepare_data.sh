writeSMETheader() {
	echo "SMET 1.1 ASCII" > ${smetfile}
	echo "[HEADER]" >> ${smetfile}
	echo "station_id    = ${stnname}" >> ${smetfile}
	echo "station_name  = ${stnid}" >> ${smetfile}
	echo "latitude      = 85.618" >> ${smetfile}
	echo "longitude     = 125.832" >> ${smetfile}
	echo "COORDSYS      = UPS" >> ${smetfile}
	echo "COORPARAM     = N" >> ${smetfile}
	echo "altitude      = 0" >> ${smetfile}
	echo "nodata        = -999" >> ${smetfile}
	echo "tz            = 0" >> ${smetfile}
	echo "fields        = ${fields}" >> ${smetfile}
	echo "[DATA]" >> ${smetfile}
}

writeSMETdata() {
	cat ${datafile} | sed 's/--/-999/g' | awk '(NR>1) {if($5!=-999 && $6!=-999) {vw=sqrt($5*$5+$6*$6)} else {vw=-999}; print $1, $2, $3, $4, vw, $7, $8}' >> ${smetfile}
}


#
# Download data if not yet present
#
if [ ! -e "asfs30.zip" ]; then
	# Get mosmet.asfs30.level3.4, doi: 10.18739/A2FF3M18K
	wget -c -O asfs30.zip https://arcticdata.io/metacat/d1/mn/v2/packages/application%2Fbagit-1.0/resource_map_doi%3A10.18739%2FA2FF3M18K
fi
if [ ! -e "asfs40.zip" ]; then
	# Get mosmet.asfs40.level3.4, doi: 10.18739/A25X25F0P
	wget -c -O asfs40.zip https://arcticdata.io/metacat/d1/mn/v2/packages/application%2Fbagit-1.0/resource_map_doi%3A10.18739%2FA25X25F0P
fi
if [ ! -e "asfs50.zip" ]; then
	# Get mosmet.asfs50.level3.4, doi: 10.18739/A2XD0R00S
	wget -c -O asfs50.zip https://arcticdata.io/metacat/d1/mn/v2/packages/application%2Fbagit-1.0/resource_map_doi%3A10.18739%2FA2XD0R00S
fi
if [ ! -e "metcity.zip" ]; then
	# Get Met City, doi: 10.18739/A2PV6B83F
	wget -c -O metcity.zip https://arcticdata.io/metacat/d1/mn/v2/packages/application%2Fbagit-1.0/resource_map_doi%3A10.18739%2FA2PV6B83F
fi
if [ ! -e "2019S96.tab" ]; then
	# Get buoy 2019S96: https://doi.org/10.1594/PANGAEA.925326
	wget -c -O 2019S96.tab https://doi.pangaea.de/10.1594/PANGAEA.925326?format=textfile&charset=UTF-8
fi
if [ ! -e "2019T62.zip" ]; then
	# Get buoy 2019T62: https://doi.org/10.1594/PANGAEA.940231
	wget -c -O 2019T62.zip https://doi.pangaea.de/10.1594/PANGAEA.940231?format=zip&charset=UTF-8
fi


#
# Unzip and unpack data if not yet done
#
mkdir -p ./data/
if [ ! -e ./data/asfs30/ ]; then
	unzip -j -d ./data/asfs30/ asfs30.zip *10min*nc
	python3 convert_data.py data/asfs30/ > data/asfs30.txt
fi
if [ ! -e ./data/asfs40/ ]; then
	unzip -j -d ./data/asfs40/ asfs40.zip *10min*nc
	python3 convert_data.py data/asfs40/ > data/asfs40.txt
fi
if [ ! -e ./data/asfs50/ ]; then
	unzip -j -d ./data/asfs50/ asfs50.zip *10min*nc
	python3 convert_data.py data/asfs50/ > data/asfs50.txt
fi
if [ ! -e ./data/metcity/ ]; then
	unzip -j -d ./data/metcity/ metcity.zip *10min*nc
	python3 convert_data.py data/metcity/ > data/metcity.txt
fi


#
# Process pluvio data
#
# Citation: Atmospheric Radiation Measurement (ARM) user facility. 2019. Weighing Bucket Precipitation Gauge (WBPLUVIO2). 2019-10-17 to 2019-12-11, ARM Mobile Facility (MOS) Collocated Instruments on ice (S3).  Compiled by D. Wang, M. Jane, E. Cromwell, M. Sturm, K. Irving, J. Delamere and M. Mockaitis. ARM Data Center. Data set accessed 2023-12-06 at http://dx.doi.org/10.5439/1338194.
# @misc{wang_jane_cromwell_sturm_irving_delamere_mockaitis,
#       title={Weighing Bucket Precipitation Gauge (WBPLUVIO2)},
#       DOI={10.5439/1338194},
#       journal={Atmospheric Radiation Measurement (ARM) user facility},
#       author={Wang, Die and Jane, Mary and Cromwell, Erol and Sturm, Matthew and Irving, Kenneth and Delamere, Jennifer and Mockaitis, Matthew}
# }
fields="timestamp PSUM"
stnname="WBPLUVIO2"
stnid=${stnname}
smetfile="./smet/${stnname}.smet"
writeSMETheader
awk -F, '(NR>1) {print substr($1,1,10) "T" substr($1,12,8), $6}' ./source/WBPLUVIO2/ascii-csv/moswbpluvio2S3.a1.20191017.000000..20200918.000000.custom.csv >> ${smetfile}


#
#
#
# Citation: Hardin, J., Hunzinger, A., Schuman, E., Matthews, A., Bharadwaj, N., Varble, A., Johnson, K., Giangrande, S., Feng, Y.-C., Lindenmaier, I., Rocque, M., Deng, M., Wendler, T., & Castro, V. Ka ARM Zenith Radar (KAZRCFRGEQC). Atmospheric Radiation Measurement (ARM) User Facility. https://doi.org/10.5439/1615726
# @misc{hardin_hunzinger_schuman_matthews_bharadwaj_varble_johnson_giangrande_feng_lindenmaier,
#       title={Ka ARM Zenith Radar (KAZRCFRGEQC)},
#       DOI={10.5439/1615726},
#       journal={Atmospheric Radiation Measurement (ARM) user facility},
#       author={Hardin, Joseph and Hunzinger, Alexis and Schuman, Eddie and Matthews, Alyssa and Bharadwaj, Nitin and Varble, Adam and Johnson, Karen and Giangrande, Scott and Feng, Ya-Chien and Lindenmaier, Iosif and et al.}
# }
#
#
# NOT IMPLEMENTED YET


#
#
# Create *smet files
#
mkdir -p ./smet/
fields="timestamp TA RH TSS VW ILWR ISWR"
for stnname in asfs30 asfs40 asfs50 metcity
do
	stnid=${stnname}
	smetfile="./smet/${stnname}.smet"
	datafile="./data/${stnname}.txt"
	writeSMETheader
	writeSMETdata
done


#
# Combine meteo data in one smet file
#
mkdir -p ./smet_combi/
if [ -z $(which meteoio_timeseries) ]; then
	echo "ERROR: meteoio_timeseries not found. Make sure to set \$PATH correctly, such that it includes meteoio/bin!"
else
	meteoio_timeseries -s 10 -c io.ini -b 2019-10-06T00:00:00 -e 2020-09-20T00:00:00
fi


#
# Get Buoy data
#

# First, the snow depth buoy: https://doi.pangaea.de/10.1594/PANGAEA.925326
wget -c -O 2019S96.tab "https://doi.pangaea.de/10.1594/PANGAEA.925326?format=textfile&charset=UTF-8"

# Then the IMB
# 1: manually determined interfaces: https://doi.pangaea.de/10.1594/PANGAEA.938228
wget -c -O 2019T62_snow_depth_ice_thickness.tab "https://doi.pangaea.de/10.1594/PANGAEA.938228?format=textfile&charset=UTF-8"

# 2: full temperature data: https://doi.pangaea.de/10.1594/PANGAEA.940231
wget -c -O 2019T62.zip "https://doi.pangaea.de/10.1594/PANGAEA.940231?format=zip&charset=UTF-8"
