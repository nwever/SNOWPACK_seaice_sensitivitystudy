BEGIN {
	h=1;   # Flag for header
	d=0;   # Flag for data
	nodata=-999;
}
{
	if ($0=="[STATION_PARAMETERS]") {
		# Entering the header
		h=1;
		d=0;
	}
	if (h) {
		# Deal with coordinates
		if (/Latitude/) {
			split($0,a,"= ")
			lat=a[2];
		} else if (/Longitude/) {
			split($0,a,"= ")
			lon=a[2];
		} else if (/Altitude/) {
			split($0,a,"= ")
			alt=a[2];
		}
	}
	if (d) {
		if (/^0500/) {
			datum=sprintf("%04d-%02d-%02dT%02d:%02d:%02d", substr($2,7,4), substr($2,4,2), substr($2,1,2), substr($2,12,2), substr($2,15,2), substr($2,18,2));
		} else if($1==501) {
			if($2==1 && $3==0) {printf "%s -999 -999 -999 -999 -999 -999\n", datum;}
			nE=$2
			for(i=1;i<=$2;i++) {
				# Read domain coordinates
				z[i]=$(i+2)/100.
			}
		} else if($1==502) {
			# Read densities
			for(i=1; i<=$2; i++) {
				rho[i]=$(i+2);
			}
		} else if($1==503) {
			# Read temperatures
			for(i=1; i<=$2; i++) {
				Te[i]=$(i+2)+273.15
			}
		} else if($1==506) {
			# Read LWC
			for(i=1; i<=$2; i++) {
				th_water[i]=$(i+2)/100.
			}
		} else if($1==512) {
			# Read grain size
			for(i=1; i<=$2; i++) {
				gs[i]=$(i+2)
			}
		} else if($1==515) {
			# Read theta[ICE]
			for(i=1; i<=$2; i++) {
				th_ice[i]=$(i+2)/100.
			}
		} else if($1==516) {
			n++;
			# Read theta[AIR] (i.e., pore space)
			for(i=1; i<=$2; i++) {
				th_air[i]=$(i+2)/100.
			}
			H=0
			lwc_10cm=0
			lwc_20cm=0
			lwc_10cm_d=0
			lwc_20cm_d=0
			for(i=nE; i>=	0; i--) {
				dH=(z[i+1]-z[i]);
				if (H<=0.1) {
					lwc_10cm+=th_water[i]*dH;
					lwc_10cm_d+=dH;
				}
				if (H<=0.2) {
					lwc_20cm+=th_water[i]*dH;
					lwc_20cm_d+=dH;
				}
				H+=dH;
			}
			print datum, (lwc_10cm_d>0)?(lwc_10cm/lwc_10cm_d):(nodata), (lwc_20cm_d>0)?(lwc_20cm/lwc_20cm_d):(nodata)
		}
	}
	if (/\[DATA\]/) {
		# Entering the data
		h=0;
		d=1;
	}
}
