#!/bin/bash
#--------------------------- Description ---------------------------------#

# This script modifies relplot R script from KING, and generates png file
# with four or two merged subplots with optionally customized legend positions.
# Default legend positions will be applied without input of legendpos.

# Yunhan Chu (yunhanch@gmail.com), Elizabeth Corfield

# (c) 2020-2022 NORMENT, UiO

# Usage:      sh create-relplot.sh r_relplot tag [legendpos1 legendpos2 legendpos3 legendpos4]
# Arguments:  r_relplot - R script file for relplot from KING
#             tag - a tag of data shown in the titles of the plots
#             legendpos1 - legend position of plot 1: topleft, topright, bottomleft, bottomright
#             legendpos2 - legend position of plot 2: topleft, topright, bottomleft, bottomright
#             legendpos3 - legend position of plot 3: topleft, topright, bottomleft, bottomright
#             legendpos4 - legend position of plot 4: topleft, topright, bottomleft, bottomright
# Example:    sh create-relplot.sh rotterdam1-yc-eur-king-1_relplot.R "Rotterdam1 EUR" topright bottomright topright bottomright

#-------------------------------------------------------------------------#

r_relplot=$1
tag=$2

legendpos1=$3
legendpos2=$4
legendpos3=$5
legendpos4=$6

cp $r_relplot ${r_relplot%.*}_2.R
r_relplot=${r_relplot%.*}_2.R

r_file=`head -n1 $r_relplot | awk '{print $2}'`
r_file=${r_file%_relplot.R}
dir=$(dirname $r_file)
bn=$(basename $r_file)

sed -i "s|$r_file|$bn|g" $r_relplot
sed -i "s|$bn Families|$tag Families|" $r_relplot
sed -i "s|) in $tag Families|)\\\n in $tag Families|" $r_relplot
sed -i "s|In Inferred $bn Relatives|In Inferred $tag Relatives|" $r_relplot
sed -i "s|in Inferred $bn Relatives|\\\n in Inferred $tag Relatives|" $r_relplot
sed -i "s|postscript(\"${bn}_relplot.ps\", paper=\"letter\", horizontal=T)|png(width=900,height=720,file=\"$bn.png\")\npar(mfrow=c(2,2))\npar(mar=c(5.1,5.1,4.1,1.1))|" $r_relplot
if [ ! -z $legendpos1 ]; then
    sed -i "s|legend(\"topright\", allrelatives|legend(\"$legendpos1\", allrelatives|" $r_relplot
fi
if [ ! -z $legendpos2 ]; then
    sed -i "s|legend(\"bottomright\", allrelatives|legend(\"$legendpos2\", allrelatives|" $r_relplot
fi
if [ ! -z $legendpos3 ]; then
    sed -i "s|legend(\"topright\", c(\"Inferred|legend(\"$legendpos3\", c(\"Inferred|" $r_relplot
fi
if [ ! -z $legendpos4 ]; then
    sed -i "s|legend(\"bottomright\", c(\"Inferred|legend(\"$legendpos4\", c(\"Inferred|" $r_relplot
fi
sed -i "s/cex.lab=1.2/cex.lab=1.3/g" $r_relplot
sed -i "s/^dev.off()/invisible(dev.off())/g" $r_relplot

Rscript $r_relplot

if [ ! -f $dir/$bn.kin0 ] || [ `cut -f11 $dir/$bn.kin0 | wc -l` -eq 1 ] || [ `cut -f12 $dir/$bn.kin0 | wc -l` -eq 1 ]; then
    convert $dir/$bn.png -gravity South -chop 0x360 $dir/${bn}_2.png
    mv $dir/${bn}_2.png $dir/$bn.png
fi
