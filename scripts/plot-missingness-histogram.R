#--------------------------- Description ----------------------------#

# Function: This script plots the histograms of missing rates of the individuals and snps.

# Contributors: Tetyana Zayats, Elizabeth Corfield
# Contributors: Yunhan Chu (yunhanch@gmail.com)

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-missingness-histogram.R dataprefix tag
# Arguments:  dataprefix - prefix of the missingness data files
#             tag - a tag of data shown in the titles of the plots
# Example:    Rscript plot-missingness-histogram.R m24-ca-eur-missing "M24 EUR"

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# prefix of the path of the miss files
dataprefix = args[1]

# tag of data
tag = args[2]

#----------------------------- Start code ---------------------------#

indiv=read.table(paste0(dataprefix,'.imiss'), h=T)
snp=read.table(paste0(dataprefix,'.lmiss'), h=T)

png(paste0(dataprefix,'-rate-indiv.png'))
hist(indiv$F_MISS,main=paste0(tag," Missing Rates of Individuals"),xlab="Missing Rate",ylab="Counts",xlim=c(0,max(indiv$F_MISS)),col="gray",breaks=100)
abline(v=0.02,col="red")
abline(v=0.05,col="green")
legend("topright",c("pre-filter (95%)","filter (98%)"),fill=c("green","red"))
invisible(dev.off())

png(paste0(dataprefix,'-rate-snps-all.png'))
hist(snp$F_MISS,main=paste0(tag," Missing Rates of SNPs, all"),xlab="Missing Rate",ylab="Counts",xlim=c(0,1),col="gray",breaks=200)
abline(v=0.02,col="red")
abline(v=0.05,col="green")
legend("topright",c("pre-filter (95%)","filter (98%)"),fill=c("green","red"))
invisible(dev.off())

png(paste0(dataprefix,'-rate-snps-zoom.png'))
hist(snp$F_MISS,main=paste(tag," Missing Rates of SNPs, zoomed"),xlab="Missing Rate",ylab="Counts",xlim=c(0,0.06),col="gray",breaks=200)
abline(v=0.02,col="red")
abline(v=0.05,col="green")
legend("topright",c("pre-filter (95%)","filter (98%)"),fill=c("green","red"))
invisible(dev.off())
