## Contents

* [create-relplot.sh](#create-relplotsh)
* [cryptic.sh](#crypticsh)

### create-relplot.sh

**Function**
This script modifies relplot R script from KING, and generates png file
with four or two merged subplots with optionally customized legend positions.
Default legend positions will be applied without input of legendpos.

**Usage** ``sh create-relplot.sh r_relplot tag [legendpos1 legendpos2 legendpos3 legendpos4]``

**Arguments** 
* `r_relplot` - R script file for relplot from KING
* `tag` - a tag of data shown in the titles of the plots
* `legendpos1` - legend position of plot 1: topleft, topright, bottomleft, bottomright
* `legendpos2` - legend position of plot 2: topleft, topright, bottomleft, bottomright
* `legendpos3` - legend position of plot 3: topleft, topright, bottomleft, bottomright
* `legendpos4` - legend position of plot 4: topleft, topright, bottomleft, bottomright

**Example**
```
sh create-relplot.sh rotterdam1-yc-eur-king-1_relplot.R "Rotterdam1 EUR" topright bottomright topright bottomright
```

### cryptic.sh

**Function**
Create files with (1) sum of all kinship coefficients per individual (when kinship>=5%) and (2) count of all individuals with whom an individual ha$

**Usage** ``sh cryptic.sh <king.ibs0> <out>``

**Arguments** 
* `king.ibs0` - ibs0 output from king
* `out` - prefix for otuput file

**Example**
```
cryptic.sh king-3.ibs0 cryptic-3
```
