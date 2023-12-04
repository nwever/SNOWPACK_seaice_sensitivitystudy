writeSMETheader() {
	echo "SMET 1.1 ASCII" > ${smetfile}
	echo "[HEADER]" >> ${smetfile}
	echo "station_id    = ${stnname}" >> ${smetfile}
	echo "station_name  = ${stnid}" >> ${smetfile}
	echo "latitude = 85.618" >> ${smetfile}
	echo "longitude = 125.832" >> ${smetfile}
	echo "COORDSYS = UPS" >> ${smetfile}
	echo "COORPARAM = N" >> ${smetfile}
	echo "altitude      = 0" >> ${smetfile}
	echo "nodata        = -999" >> ${smetfile}
	echo "tz            = 0" >> ${smetfile}
	echo "fields        = timestamp TA RH TSS VW ILWR ISWR " >> ${smetfile}
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
# Create *smet files
#
mkdir -p ./smet/
for stnname in asfs30 asfs40 asfs50 metcity
do
	stnid=${stnname}
	smetfile="./smet/${stnname}.smet"
	datafile="./data/${stnname}.txt"
	writeSMETheader
	writeSMETdata
done
