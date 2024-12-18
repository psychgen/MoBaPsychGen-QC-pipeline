## Contents

* [plot-pca-with-1kg.R](#plot-pca-with-1kgr)
* [select-subsamples-on-pca.R](#select-subsamples-on-pcar)
* [select-subsamples-on-pca-ellipse.R](#select-subsamples-on-pca-ellipser)
* [plot-pca-selected-subsample.R](#plot-pca-selected-subsampler)
* [plot-missingness-histogram.R](#plot-missingness-histogramr)
* [plot-heterozygosity-common.R](#plot-heterozygosity-commonr)
* [plot-heterozygosity-rare.R](#plot-heterozygosity-rarer)
* [plot-ibd.R](#plot-ibdr)
* [plot-qqplot.R](#plot-qqplotr)
* [create-liftover-input.R](#create-liftover-inputr)
* [merge-relatedness-rt.R](#merge-relatedness-rtr)
* [create-relplot.sh](#create-relplotsh)
* [select-subsamples-on-pca-without1kg.R](#select-subsamples-on-pca-without1kg)
* [plot-sex.R](#plot-sex)
* [plot-kinship-histogram.R](#plot-kinship-histogram)
* [cryptic-plot.R](#cryptic-plot)
* [plot-batch-PCs.R](#plot-batch-PCs)
* [anova-for-PC-vs-plates.R](#anova-for-PC-vs-plates)
* [plot-PC-by-plate.R](#plot-PC-by-plate)

## Summary of R scripts

### plot-pca-with-1kg.R

**Function**
This script plots principal components of a study dataset together with 
1KG:  PC1 vs. PC2, PC1 - PC7. Plots of the study data with full 1KG and 
plots with less 1KG (e.g. EUR, AFR, ASIAN anchor) will be generated.

**Usage** ``Rscript plot-pca-with-1kg.R datalabel pcadata legendpos outprefix``

**Arguments** 
* `datalabel` - a compact name of the study data to be used as a label in
               the titles and legends of the plots
* `pcadata` - file path to the pca data
* `legendpos` - position of legend: topleft, topright, bottomleft, bottomright
* `outprefix` - prefix of the output plots

**Example**
```
Rscript plot-pca-with-1kg.R Norment_jun2015 norment_batch4_jun2015-1kg-yc-pca bottomright norment_batch4_jun2015-yc
```

### select-subsamples-on-pca.R

**Function**
This script selects core (e.g. European, African, Asian) subsamples based
on PCA plot(s) of the study data with 1KG, generates zoom and threshold
plots based on given thresholds, and generates a text file
containing the list of selected individuals per core subsample based on the
draw thresholds.

**Usage** ``Rscript select-subsamples-on-pca.R datalabel pcadata outprefix customfile``

**Arguments**
* `datalabel` - a compact name of the study data to be used as a label in
               the titles and legends of the plots
* `pcadata` - file path to the pca data
* `outprefix` - prefix of the output files
* `customfile` - file customized with thresholds for the plots

**Example**
```
Rscript select-subsamples-on-pca.R Norment_jun2015 norment_batch4_jun2015-1kg-yc-pca norment_batch4_jun2015-yc norment-jun2015-yc-pca-core-select-custom.txt

# An example of the customfile (norment-jun2015-yc-pca-core-select-custom.txt) is seen here:
https://github.com/psychgen/MoBaPsychGen-QC-pipeline/edit/main/scripts/config/m12bad-yc-pca-core-select-custom.txt
(where the zoom thresholds are only for zooming in, while the draw thresholds are for selecting individuals of subsamples, by dropping or commenting out all the draw threshold lines, zoom plots without threhold lines are made)
```

### select-subsamples-on-pca-ellipse.R

**Function**
This script selects core (e.g. European, African, Asian) subsamples based on PCA plot(s) of the study data with 1KG based on ellipse selection, generates zoom and threshold plots based on given thresholds, and generates a text file containing the list of selected individuals per core subsample.

**Usage** ``Rscript select-subsamples-on-pca-ellipse.R datalabel pcadata outprefix customfile``

**Arguments**
* `datalabel` - a compact name of the study data to be used as a label in
               the titles and legends of the plots
* `pcadata` - file path to the pca data
* `outprefix` - prefix of the output files
* `customfile` - file customized with thresholds for the plots

**Example**
```
Rscript select-subsamples-on-pca-ellipse.R Norment_jun2015 norment_batch4_jun2015-1kg-yc-pca norment_batch4_jun2015-yc norment-jun2015-yc-pca-core-select-ellipse-custom.txt

# An example of the customfile (norment-jun2015-yc-pca-core-select-ellipse-custom.txt) is seen here:
https://github.com/psychgen/MoBaPsychGen-QC-pipeline/edit/main/scripts/config/norment-jun2015-yc-pca-core-select-ellipse-custom.txt
(where the zoom thresholds are for zooming in, while the ellipse thresholds are for selecting individuals of subsamples, by dropping or commenting out all the ellipse threshold lines, zoom and threhold plots with roughly suggested ellipse thresholds are made)
```

### plot-pca-selected-subsample.R

**Function**
This script plots PC1 - PC7 of samples and 1kg samples selected from PCA.

**Usage** ``Rscript plot-pca-selected-subsample.R datalabel pcadata selected-sample-list selected-1kg-list outprefix``

**Arguments**
  * `tag` - a tag of data shown in the title of the plot
  * `pcadata` - file path to the pca data
  * `selected-sample-list` - file path to the list of selected samples
  * `selected-1kg-list` - file path to the list of selected 1kg samples
  * `legendpos` - position of legend: topleft, topright, bottomleft, bottomright
  * `outprefix` - prefix of the output plot
  
**Example**
```
Rscript plot-pca-selected-subsample.R "M24 EUR" m24-1kg-ca-pca m24-ca-first-pca-plot-pc1-pc2-eur.selected_samples.csv m24-ca-first-pca-plot-pc1-pc2-eur.selected_samples_1kg.csv bottomleft m24-ca-first-pca-plots-pc1-pc7-threshold-eur
```

### plot-missingness-histogram.R

**Function**
This script plots the histograms of missing rates of the individuals and snps.

**Usage** ``Rscript plot-missingness-histogram.R dataprefix tag``

**Arguments**
  * `dataprefix` - prefix of the missingness data files
  * `tag` - a tag of data shown in the titles of the plots
  
**Example**
```
Rscript plot-missingness-histogram.R m24-ca-eur-missing "M24 EUR"
```

### plot-heterozygosity-common.R

**Function**
This script plots heterozygosity rate (HET_RATE) vs. number of missing snps per individual and histograms of inbreeding coefficients (F) based on the common variants, marks the mean HET_RATE +/-3 SD and F +/- 0.2 of the sample, and generates the list of outliers outside F +/- 0.2.

**Usage** ``Rscript plot-heterozygosity-common.R dataprefix tag``

**Arguments**
  * `dataprefix` - prefix of the heterozygosity/missingness data files
  * `tag` - a tag of data shown in the titles of the plots

**Example**
```
Rscript plot-heterozygosity-common.R m24-ca-eur-common "M24 EUR"
```

### plot-heterozygosity-rare.R

**Function**
This script plots heterozygosity rate (HET_RATE) vs. number of missing snps per individual and histograms of inbreeding coefficients (F) based on the rare variants, marks the mean HET_RATE +/-3 SD and F +/- 0.2 of the sample, and generates the list of outliers outside F +/- 0.2.

**Usage** ``Rscript plot-heterozygosity-rare.R dataprefix tag``

**Arguments**
  * `dataprefix` - prefix of the heterozygosity/missingness data files
  * `tag` - a tag of data shown in the titles of the plots

**Example**
```
Rscript plot-heterozygosity-rare.R m24-ca-eur-rare  "M24 EUR"
```

### plot-ibd.R

**Function**
This script plots histogram of PI_HAT as well as Z0 vs Z1.

**Usage** ``Rscript plot-ibd.R dataprefix tag``

**Arguments**
  * `data` - the genome data file of ibd
  * `tag` - a tag of data shown in the titles of the plots

**Example**
```
Rscript plot-ibd.R m24-ca-eur-king-1-ibd "M24 EUR"
```

### plot-qqplot.R

**Function**
This script generates a qq-plot based on the list of p-values.

**Usage** ``Rscript plot-qqplot.R inputfile tag pcol outprefix``

**Arguments**
  * `inputfile` - the file containing pvalues
  * `tag` - a tag of data shown in the titles of the plots
  * `pcol` - no. of column of pvalue
  * `outprefix` - prefix of the output plot

**Example**
```
Rscript plot-qqplot.R rotterdam1-yc-eur-3-mh-plates.cmh2 "Rotterdam1 EUR" 5 rotterdam1-yc-eur-3-plate-test-qq-plot
```

### create-liftover-input.R

**Function**
This script creates liftover input file.

**Usage** ``Rscript create-liftover-input.R dataprefix outprefix``

**Arguments**
  * `dataprefix` - prefix of input bim file
  * `outprefix` - prefix of output bed file

**Example**
```
Rscript create-liftover-input.R MorBarn_Feb2018-yc-rsids MorBarn_Feb2018-yc-liftover_input
```

### merge-relatedness-rt.R

**Function**
This script merges pairwise bad relatedness list with the KING inferred relatedness type.

**Usage** ``Rscript merge-relatedness-rt.R relfile rtfile``

**Arguments**
  * `relfile` - the ibd relatedness file
  * `rtfile` - the king inferred relatedness type file

**Example**
```
Rscript merge-relatedness-rt.R original-initials-eur-king-3-ibd-bad-relatedness.txt original-initials-eur-king-3.RT
```

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

### select-subsamples-on-pca-without1kg.R

**Function**
This script selects core (e.g. European, African, Asian) subsamples based provided
thresholds from PCA of the study data without 1KG and generates a text file
containing the list of selected individuals per core subsample based on the
draw thresholds.

**Usage** `` Rscript select-subsamples-on-pca-without1kg.R pcadata outprefix customfile``

**Arguments** 
* `pcadata` - file path to the pca data
* `outprefix` - prefix of the output plots
* `customfile` - custom file with single line containing the filtering thresholds (e.g., PC1 > -0.02 & PC1 < 0 & PC2 > -0.005 & PC2 < 0.01)

### plot-sex.R

**Function**
This script is to plot F vs missingness for X chromosome stratifies by reported sex.

**Usage** ``Rscript input title legendpos output``

**Arguments**
  * `input` - the name of the file containing F and  missingness data for X chromosome 
  * `title` - part of the title to be given to the plot, it should reflect the tag of the batch from plot-PLINK file and the subpopulation/round of the QC
  * `legendpos` - the position of legend: topleft, topright, bottomleft, bottomright
  * `output` - the name of the output file to be created
  
**Example**
```
Rscript plot-sex.R m24-tz-eur-2-chr23-plot.txt "M24 EUR,round two" bottomright m24-tz-eur-2-sex-plot.png
```

### plot-kinship-histogram.R

**Function**
This script plots a histogram of Kinship between families as estimated by KING

**Usage** ``Rscript input output``

**Arguments**
 * `input` - the name of the input file  
 * `output` - the name of the output file to be created
  
**Example**
```
Rscript plot-kinship-histogram.R m12good-ec-eur-king-1.ibs0 m12good-ec-eur-king-1-hist
```

### cryptic-plot.R

**Function**
This script plots sums of kinships and counts of individuals with whom one shares at least 2.5% of kinship.

**Usage** ``Rscript input1 input2 tag``

**Arguments**
 * `input1` - the name of the file containing sums of kinships of at least 2.5% per individual
 * `input2` - the name of the file containing counts of kinships of at least 2.5% per individual
 * `tag` - the tag of your batch as specified in plot-PLINK file
 * `outprefix` - prefix of the output plots
  
 **Example**
 ```
 Rscript cryptic-plot.R m24-tz-eur-cryptic-1-kinship-sum.txt m24-tz-eur-cryptic-counts.txt "M24 EUR" m24-tz-eur-kinship-sum-and-count
 ``` 
### plot-batch-PCs.R

**Function**
This script plots the first 10 PCs of the batch PCA alone.

**Usage** ``Rscript input title legendpos output``

**Arguments**
* `input` - the name of the file containing PCs 
* `title` - part of the title to be given to the plot, it should reflect the tag of the batch from plot-PLINK file and the subpopulation/round of the QC
* `legendpos` - the position of legend: topleft, topright, bottomleft, bottomright
* `output` - the name of the output file to be created
  
**Example**
```
Rscript plot-batch-PCs.R m24-tz-eur-1-keep-pca-fam.txt "M24 EUR" bottomright m24-tz-eur-1-pca.png
```

### anova-for-PC-vs-plates.R

**Function**
This script runs ANOVA for the frist 10 PCs against the plates on which the samples were genotyped to test for batch effects.

**Usage** ``Rscript input output``

**Arguments**
* `input` - the name of the file containing the PCs and the plate IDs
* `output` - the name of the output file to be created
  
**Example**
```
Rscript anova-for-PC-vs-plates.R m24-tz-eur-3-pca-plates.txt m24-tz-eur-3-pca-anova-results.txt
```

### plot-PC-by-plate.R

**Function**
This script creates PC plot(s) colored by plate.

**Usage** ``Rscript input tag output``

**Arguments**
* `input` - the name of the file containing PCs and plate IDs
* `tag` - tag corresponding to your batch (from plot-PLINK file) and population you are QC-ing
* `output` - the name of the output file(s) to be created
  
**Example**
```
Rscript plot-PC-by-plate.R m24-tz-eur-3-pca-plates.txt "m24 EUR" m24-tz-eur
```
