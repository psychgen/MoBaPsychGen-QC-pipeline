#this script creates files with (1) sum of all kinship coefficients per individual (when kinship>=5%) and (2) count of all individuals with whom an individual ha$
NAME=$1
NAME1=$2
awk '$19>=0.025 {print $0}' $NAME > cryptic-5      
awk '{a[$2]+=$19} END {for (i in a) print i, a[i]}' cryptic-5 | sort -k1 > cryptic-5-2-all-kinship
awk '{a[$4]+=$19} END {for (i in a) print i, a[i]}' cryptic-5 | sort -k1 > cryptic-5-4-all-kinship
cat cryptic-5-2-all-kinship cryptic-5-4-all-kinship | awk '{a[$1]+=$2} END {for (i in a) print i, a[i]}' | sort -k1 | grep -v "IID" > $NAME1-kinship-sum.txt
awk '{print $2}' cryptic-5 | sort | uniq -c | sort --key=1 -g > cryptic-5-2
awk '{print $4}' cryptic-5 | sort | uniq -c | sort --key=1 -g > cryptic-5-4
cat cryptic-5-2 cryptic-5-4 | awk '{a[$2]+=$1} END{for (i in a) print i, a[i]}' | sort -k1 > $NAME1-counts.txt
rm cryptic-5*

