fig_dir="./figs/"

if [ ! -d "${fig_dir}" ]; then
	mkdir ${fig_dir}
fi



source 2019T62_temp.info
ytics=50
plotfilename=${fig_dir}/2019T62_temp
echo "set term pdf size 12,7 font 'Liberation Sans,24'" > ${plotfilename}
echo "set encoding iso_8859_1" >> ${plotfilename}
echo "set datafile missing \"-9999\"" >> ${plotfilename}
echo "set output '${plotfilename}.pdf'" >> ${plotfilename}
echo "set cbrange[-20:0]" >> ${plotfilename}
echo "set xrange[0:*]" >> ${plotfilename}
# t1, t2 are the boundaries in cm above/below snow/ice interface upon installation
# lim1, lim2 are the boundaries to the closest specified ytics
# finally printed are those lim1 and lim2 translated back to the image matrix
yrange=$(awk -v top=${top} -v bot=${bottom} -v sp=${spacing} -v yt=${ytics} 'BEGIN {b=-1; e=-1} {if(NR>1) {n++;for(i=1; i<=NF; i++) {if($i!=-9999) {e=NR-1; if(b==-1) {b=NR-1}}}}} END {t1=top-(b-1)*sp; t2=top-(e*sp); lim1=yt*(int(t1/yt)+1); lim2=yt*(int(t2/yt)-1); printf "set yrange[%f:%f]\n", (-bot+lim2)/sp, (-bot+lim1)/sp}' 2019T62_temp_masked.tab)
echo "${yrange}" >> ${plotfilename}
ylabels=$(echo ${top} ${bottom} ${spacing} | awk -v yt=${ytics} 'BEGIN {printf "set ytics ("} {a=0; for(i=$1; i>=$2; i-=$3) {if (i%yt==0) {if(a>0) {printf ","}; a++; printf "\"%d\" %d", i, ((i-$2))/$3}}} END {printf (")\n")}')
echo "${ylabels}" >> ${plotfilename}
echo "set xtics out" >> ${plotfilename}
echo "set palette defined (-9 \"black\", -3 \"blue\", 0 \"white\", 3 \"red\")" >> ${plotfilename}
xlabels=$(head -1 2019T62_temp_masked.tab | tr ' ' '\n' | awk '{printf "%02d-%02d %d\n", int(substr($1,9,2)), int(substr($1,6,2)), NR}' | awk -F- '($1==01) {print $0}' | uniq -w5 | awk 'BEGIN {a=0; printf "set xtics ("} {if(a>0) {printf ", "} else {a=1}; printf "\"%s\" %d", $1, $2} END {printf (")\n")}' | sed 's/-01/ Jan/g' | sed 's/-02/ Feb/g' | sed 's/-03/ Mar/g' | sed 's/-04/ Apr/g' | sed 's/-05/ May/g' | sed 's/-06/ Jun/g' | sed 's/-07/ Jul/g' | sed 's/-08/ Aug/g' | sed 's/-09/ Sep/g' | sed 's/-10/ Oct/g' | sed 's/-11/ Nov/g' | sed 's/-12/ Dec/g')
echo "${xlabels}" >> ${plotfilename}
echo "pl '<(tail -n+2 2019T62_temp_masked.tab | tac)' matrix with image notitle \\" >> ${plotfilename}
echo ", ((0-${bottom}))/${spacing} w l lc rgb 'cyan' lw 3 notitle\\" >> ${plotfilename}
echo "" >> ${plotfilename}
gnuplot ${plotfilename}
