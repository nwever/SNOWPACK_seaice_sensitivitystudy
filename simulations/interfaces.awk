BEGIN {
	h=1;   # Flag for header
	d=0;   # Flag for data
	nodata=-999;
	fthlwc=0.217	# Threshold for LWC bove which a layer is considered flooded. It corresponds to a saturated layer with ice density 700 kg/m3.
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
			nE=$2-1
			for(i=1; i<=$2; i++) {
				# Read domain coordinates
				z[i-1]=$(i+2)/100.
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
			n++; idx=n
			# Read theta[AIR] (i.e., pore space)
			for(i=1; i<=$2; i++) {
				th_air[i]=$(i+2)/100.
			}

			zT[idx]=z[NF-2];	# top / surface
			zM[idx]=z[NF-2];	# interface between snow and ice/flooding layer
			zFt[idx]=-9999;		# top of flooding layer
			zF[idx]=-9999;		# bottom of flooding layer
			zB[idx]=-9999;		# bottom of ice
			hf[idx]=0;		# flooding layer thickness
			hs[idx]=0;		# snow depth
			hi[idx]=0;		# ice thickness
			snow=1; flood=1;
			for(i=nE; i>=1; i--) {
				dz=(z[i]-z[i-1]);
				if($i>=0 && rho[i]>=0) {
					if(snow==1 && (rho[i]<700.-((th_water[i])*1000.) || (i>=1 && rho[i-1]<700.-((th_water[i-1])*1000.)) || (i>=2 && rho[i-2]<700.-((th_water[i-2])*1000)))) {
						zM[idx]=z[i]
						hs[idx]+=dz
					} else {
						snow=0;
						if(th_water[i]>fthlwc && rho[i]>900 && i>7 && flood==1) {
							if(zFt[idx]==-9999) {
								zFt[idx]=z[i+1]
							}
							zF[idx]=z[i];
							hf[idx]+=dz
						}
						zB[idx]=z[i];
						hi[idx]+=dz
					}
				}
			}
			print datum, zT[idx], zM[idx], zFt[idx], zF[idx], zB[idx], hs[idx], hf[idx], hi[idx]
		}
	}
	if (/\[DATA\]/) {
		# Entering the data
		h=0;
		d=1;
	}
}
