BEGIN {
	fthlwc=21.7	# Threshold for LWC in % above which a layer is considered flooded. It corresponds to a saturated layer with ice density 700 kg/m3.
}
{
	if(/StationName=/) {
		t=0;
	}
	if(/^0500/ && $2 ~ /[0-9]/) {
		t=t+1;
		tarr[t]=sprintf("%04d-%02d-%02dT%02d:%02d", substr($2,7,4), substr($2,4,2), substr($2,1,2), substr($2,12,2), substr($2,15,2))
	}
	if(/^0501/ && $2 ~ /[0-9]/) {
		for(i=3; i<=NF; i++) {
			z[i-3]=($i/100.)
		}
	}
	if(/^0502/ && $2 ~ /[0-9]/) {
		for(i=NF; i>=3; i--) {
			rho[i]=$i
		}
	}
	if(/^0506/ && $2 ~ /[0-9]/) {
		idx=sprintf("%d", t);
		zT[idx]=z[NF-2];
		zM[idx]=z[NF-2];
		zF[idx]=-9999;
		zFt[idx]=-9999;
		zB[idx]=-9999;
		hf[idx]=0;
		hs[idx]=0;
		hi[idx]=0;
		snow=1; flood=1;
		for(i=NF; i>=3; i--) {
			dz=(z[i-2]-z[i-3]);
			if($i>=0 && rho[i]>=0) {
				if(snow==1 && (rho[i]<700-(($i/100)*1000) || (i>=1 && rho[i-1]<700-(($(i-1)/100)*1000)) || (i>=2 && rho[i-2]<700-(($(i-2)/100)*1000)))) {
					zM[idx]=z[i-3]
					hs[idx]+=dz
				} else {
					snow=0;
					if($i>fthlwc && rho[i]>900 && i>7 && flood==1) {
						if(zFt[idx]==-9999) {
							zFt[idx]=z[i-2]
						}
						zF[idx]=z[i-3];
						hf[idx]+=dz
					}
					zB[idx]=z[i-3];
					hi[idx]+=dz
				}
			}
		}
	}
} END {
	for (t in tarr) {
		idx=sprintf("%d", t)
		print tarr[t], zT[idx], zM[idx], zFt[idx], zF[idx], zB[idx], hs[idx], hf[idx], hi[idx]
	}
}
