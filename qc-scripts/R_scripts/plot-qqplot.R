#--------------------------- Description ----------------------------#

# Function: This script generates a qq-plot based on the list of p-values.

# Contributors: Yunhan Chu (yunhanch@gmail.com), Elizabeth Corfield

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-qqplot.R inputfile tag pcol outprefix
# Arguments:  inputfile - the file containing pvalues
#             tag - a tag of data shown in the titles of the plots
#             pcol - no. of column of pvalue
#             outprefix - prefix of the output plot
# Example:    Rscript plot-qqplot.R rotterdam1-yc-eur-3-mh-plates.cmh2 "Rotterdam1 EUR" 5 rotterdam1-yc-eur-3-plate-test-qq-plot

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# the file containing pvalues
inputfile = args[1]

# tag of data
tag = args[2]

# no. of column of the output plot
pcol = as.numeric(args[3])

# outprefix - prefix of the output plot
outprefix = args[4]
#----------------------------- Start code ---------------------------#
# Observed p-values
data <- read.table(inputfile, head=T)
data <- data[! is.na(data[,pcol]), ]
data <- data[order(data[,pcol]), ]
pval <- data[, pcol]

# Expected p-values
exp.pval <- (1:length(pval))/(length(pval)+1)

# Make plot
png(paste0(outprefix,'.png'))
plot(-log10(exp.pval), -log10(pval),pch=20,main=paste0(tag," Plate test QQ plot"),col="red",xlab="Expected -logP",ylab="Observed -logP")
abline(0,1)
invisible(dev.off())
