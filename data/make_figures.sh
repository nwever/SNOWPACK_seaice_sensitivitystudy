fig_dir="./figs/"

if [ ! -d "${fig_dir}" ]; then
	mkdir ${fig_dir}
fi



source 2019T62_temp.info
plotfilename=${fig_dir}/2019T62_temp
echo "set term pdf size 12,7 font 'Liberation Sans,24'" > ${plotfilename}
echo "set encoding iso_8859_1" >> ${plotfilename}
echo "set datafile missing \"-9999\"" >> ${plotfilename}
echo "set output '${plotfilename}.pdf'" >> ${plotfilename}
echo "set cbrange[-20:0]" >> ${plotfilename}
echo "set xrange[0:*]" >> ${plotfilename}
echo "set yrange[0:*]" >> ${plotfilename}
ylabels=$(echo ${top} ${bottom} ${spacing} | awk 'BEGIN {printf "set ytics ("} {a=0; for(i=$1; i>=$2; i-=$3) {if (i%50==0) {if(a>0) {printf ","}; a++; printf "\"%d\" %d", i, ((i-$2))/$3}}} END {printf (")\n")}')
echo "${ylabels}" >> ${plotfilename}
echo "set xtics out" >> ${plotfilename}
echo "set palette defined (-9 \"black\", -3 \"blue\", 0 \"white\", 3 \"red\")" >> ${plotfilename}
xlabels=$(head -1 2019T62_temp_masked.tab | tr ' ' '\n' | awk '{printf "%02d-%02d %d\n", int(substr($1,9,2)), int(substr($1,6,2)), NR}' | awk -F- '($1==01) {print $0}' | uniq -w5 | awk 'BEGIN {a=0; printf "set xtics ("} {if(a>0) {printf ", "} else {a=1}; printf "\"%s\" %d", $1, $2} END {printf (")\n")}' | sed 's/-01/ Jan/g' | sed 's/-02/ Feb/g' | sed 's/-03/ Mar/g' | sed 's/-04/ Apr/g' | sed 's/-05/ May/g' | sed 's/-06/ Jun/g' | sed 's/-07/ Jul/g' | sed 's/-08/ Aug/g' | sed 's/-09/ Sep/g' | sed 's/-10/ Oct/g' | sed 's/-11/ Nov/g' | sed 's/-12/ Dec/g')
echo "${xlabels}" >> ${plotfilename}
echo "pl '<(tail -n+1 2019T62_temp_masked.tab | tac)' matrix with image notitle \\" >> ${plotfilename}
echo ", ((0-${bottom}))/${spacing} w l lc rgb 'cyan' lw 3 notitle\\" >> ${plotfilename}
echo "" >> ${plotfilename}
gnuplot ${plotfilename}
