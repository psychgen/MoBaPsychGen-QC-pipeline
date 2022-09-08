#--------------------------- Description ----------------------------#

# Function: This script plots heterozygosity rate (HET_RATE) vs. number of missing snps per individual and histograms of inbreeding coefficients (F) based on the rare variants, marks the mean HET_RATE +/-3 SD and F +/- 0.2 of the sample, and generates the list of outliers outside F +/- 0.2.

# Contributors: Tetyana Zayats, Elizabeth Corfield
# Contributors: Yunhan Chu (yunhanch@gmail.com)

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-heterozygosity-rare.R dataprefix tag
# Arguments:  dataprefix - prefix of the heterozygosity/missingness data files
#             tag - a tag of data shown in the titles of the plots

# Example:    Rscript plot-heterozygosity-rare.R m24-ca-eur-rare "M24 EUR"

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
plot(het$HET_RATE,mis$N_MISS,ylab="Number of Missing SNPs per Ind",xlab="Heterozygosity Rate",main=paste0(tag," Missingness vs. Heterozygosity \n rare SNPs"))
abline(v=mean(het$HET_RATE)+3*sd(het$HET_RATE),col="red")
abline(v=mean(het$HET_RATE)-3*sd(het$HET_RATE),col="red")
legend("bottomright",c("mean +/- 3SD"),fill="red")
invisible(dev.off())

nleft=nrow(het[het$F < -0.2,])
nright=nrow(het[het$F > 0.2,])
nmiddle=nrow(het)-nleft-nright
png(paste0(dataprefix,"-F-het-plot.png"))
par(mfrow=c(1,2))
hist(het$F,xlim=c(-1,1),col="red",breaks=200,main=paste0(tag,"\n F het rare SNPs"),xlab="Fhet")
abline(v=0.2)
abline(v=-0.2)
hist(het$F,xlim=c(-0.3,0.3),col="red",breaks=200,main=paste0(tag,"\n F het zoomed rare SNPs"),xlab="Fhet")
abline(v=-0.2)
abline(v=0.2)
invisible(dev.off())

het_fail=subset(het,het$F < -0.2 | het$F > 0.2)
write.table(het_fail,paste0(dataprefix,"-het-fail.txt"),row.names=F,quote=F)
