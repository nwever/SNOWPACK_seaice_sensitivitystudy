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
mkdir -p ./data/
unzip -j -d ./data/asfs30/ asfs30.zip *10min*nc
unzip -j -d ./data/asfs40/ asfs40.zip *10min*nc
unzip -j -d ./data/asfs50/ asfs50.zip *10min*nc
unzip -j -d ./data/metcity/ metcity.zip *10min*nc
