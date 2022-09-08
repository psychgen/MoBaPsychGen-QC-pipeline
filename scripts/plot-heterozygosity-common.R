#--------------------------- Description ----------------------------#

# Function: This script plots heterozygosity rate (HET_RATE) vs. number of missing snps per individual and histograms of inbreeding coefficients (F) based on the common variants, marks the mean HET_RATE +/-3 SD and F +/- 0.2 of the sample, and generates the list of outliers outside F +/- 0.2.

# Contributors: Tetyana Zayats, Elizabeth Corfield
# Contributors: Yunhan Chu (yunhanch@gmail.com)

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-heterozygosity-common.R dataprefix tag
# Arguments:  dataprefix - prefix of the heterozygosity/missingness data files
#             tag - a tag of data shown in the titles of the plots
# Example:    Rscript plot-heterozygosity-common.R m24-ca-eur-common "M24 EUR"

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# prefix of the path of het and miss file
dataprefix = args[1]

# tag of data
tag = args[2]

#----------------------------- Start code ---------------------------#

het=read.table(paste0(dataprefix,".het"), header=T)
mis=read.table(paste0(dataprefix,".imiss"), header=T)
het$HET_RATE=(het$"N.NM."-het$"O.HOM.")/het$"N.NM."

nleft=nrow(het[het$HET_RATE < mean(het$HET_RATE)-3*sd(het$HET_RATE),])
nright=nrow(het[het$HET_RATE > mean(het$HET_RATE)+3*sd(het$HET_RATE),])
nmiddle=nrow(het)-nleft-nright
png(paste0(dataprefix,"-het-miss-plot.png"))
plot(het$HET_RATE,mis$N_MISS,ylab="Number of Missing SNPs per Ind",xlab="Heterozygosity Rate",main=paste0(tag," Missingness vs. Heterozygosity in common SNPs"))
abline(v=mean(het$HET_RATE)+3*sd(het$HET_RATE),col="red")
abline(v=mean(het$HET_RATE)-3*sd(het$HET_RATE),col="red")
legend("topleft",c("mean +/- 3SD"),fill="red")
invisible(dev.off())

nleft=nrow(het[het$F < -0.1,])
nright=nrow(het[het$F > 0.1,])
nmiddle=nrow(het)-nleft-nright
png(paste0(dataprefix,"-F-het-plot.png"))
par(mfrow=c(1,2))
hist(het$F,col="red",breaks=50,main=paste0(tag,"\n F het common SNPs"),xlab="Fhet")
abline(v=0.1)
abline(v=-0.1)
hist(het$F,xlim=c(-0.15,0.15),col="red",breaks=50,main=paste0(tag,"\n F het zoomed common SNPs"),xlab="Fhet")
abline(v=-0.1)
abline(v=0.1)
invisible(dev.off())

het_fail=subset(het,het$HET_RATE < mean(het$HET_RATE)-3*sd(het$HET_RATE) | het$HET_RATE > mean(het$HET_RATE)+3*sd(het$HET_RATE))
write.table(het_fail,paste0(dataprefix,"-het-fail.txt"),row.names=F,quote=F)

het_fail=subset(het,het$F < -0.1 | het$F > 0.1)
write.table(het_fail,paste0(dataprefix,"-F-het-fail.txt"),row.names=F,quote=F)
