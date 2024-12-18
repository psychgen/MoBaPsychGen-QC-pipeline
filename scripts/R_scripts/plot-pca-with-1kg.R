#--------------------------- Description ----------------------------#

# Function: This script plots principal components of a study dataset together with 1KG: PC1 vs. PC2, PC1 - PC7. Plots of the study data with full 1KG and plots with less 1KG (e.g. EUR, AFR, ASIAN anchor) will be generated.

# Contributors: Tetyana Zayats, Elizabeth Corfield
# Contributors: Yunhan Chu (yunhanch@gmail.com)

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-pca-with-1kg.R datalabel pcadata legendpos outprefix
# Arguments:  datalabel - a compact name of the study data to be used as a
#                         label in the titles and legends of the plots
#             pcadata - file path to the pca data
#             legendpos - position of legend: topleft, topright, bottomleft, bottomright
#             outprefix - prefix of the output plots
# Example:    Rscript plot-pca-with-1kg.R Norment_jun2015 norment_batch4_jun2015-1kg-yc-pca bottomright norment_batch4_jun2015-yc

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# path of study data name
datalabel = args[1]

# path of the pca data file
pca = args[2]

# position of legend
legendpos = args[3]

# prefix of plot file
outprefix = args[4]

#----------------------------- Start code ---------------------------#

data=read.table(pca, header=F, strip.white=T, as.is=T)

num = length(data[,1])-1083
datatag = tolower(unlist(strsplit(unlist(strsplit(datalabel, " "))[1], "_"))[1])

data$color = c(rep("red", num), rep("black", 61), rep("lightblue", 85), rep("blue", 97), rep("aquamarine", 99), rep("yellow", 60), rep("green", 93), rep("purple", 89), rep("orange", 14), rep("gray", 89), rep("darkolivegreen", 91), rep("magenta", 64), rep("darkblue", 55), rep("orchid", 98), rep("cyan3", 88))

data$label = c(rep(datatag, num), rep("ASW", 61), rep("CEU", 85), rep("CHB", 97), rep("CHS", 99), rep("CLM", 60), rep("FIN", 93), rep("GBR", 89), rep("IBS", 14), rep("JPT", 89), rep("LWK", 91), rep("MXL", 64), rep("PUR", 55), rep("TSI", 98), rep("YRI", 88))

png(width=900,height=500,file=paste(outprefix,'-first-pca-plot-pc1-pc2.png',sep=''))
par(mfrow=c(1,2))
df <- data.frame(table(data$label))
df <- df[match(unique(data$label),df$Var1), ]
plot(data[,3],data[,4],pch=20,main=paste0(datalabel," + 1KG, PC1 vs PC2"),col=data$color,xlab="PC1",ylab="PC2")
legend(legendpos, legend=df$Var1, fill=unique(data$color))

data_anchor <- data[data$label %in% c(datatag, "CEU", "CHB", "CHS", "FIN", "GBR", "JPT", "TSI", "LWK", "YRI"), ]
df <- data.frame(table(data_anchor$label))
df <- df[match(unique(data_anchor$label),df$Var1), ]
plot(data_anchor[,3],data_anchor[,4],pch=20,main=paste0(datalabel," + 1KG anchor, PC1 vs PC2"),col=data_anchor$color,xlab="PC1",ylab="PC2")
legend(legendpos, legend=df$Var1, fill=unique(data_anchor$color))
invisible(dev.off())

png(width=800,height=600,paste(outprefix,'-first-pca-plots-pc1-pc7.png',sep=''))
par(mfrow=c(2,3))
df <- data.frame(table(data$label))
df <- df[match(unique(data$label),df$Var1), ]
plot(data[,3],data[,4],pch=20,main=paste0(datalabel," + 1KG, PC1 vs PC2"),col=data$color,xlab="PC1",ylab="PC2")
legend(legendpos, legend=df$Var1, fill=unique(data$color))
plot(data[,4],data[,5],pch=20,main="PC2 vs PC3",col=data$color,xlab="PC2",ylab="PC3")
plot(data[,5],data[,6],pch=20,main="PC3 vs PC4",col=data$color,xlab="PC3",ylab="PC4")
plot(data[,6],data[,7],pch=20,main="PC4 vs PC5",col=data$color,xlab="PC4",ylab="PC5")
plot(data[,7],data[,8],pch=20,main="PC5 vs PC6",col=data$color,xlab="PC5",ylab="PC6")
plot(data[,8],data[,9],pch=20,main="PC6 vs PC7",col=data$color,xlab="PC6",ylab="PC7")
invisible(dev.off())

png(width=800,height=600,paste(outprefix,'-first-pca-plots-pc1-pc7-anchor.png',sep=''))
par(mfrow=c(2,3))
df <- data.frame(table(data_anchor$label))
df <- df[match(unique(data_anchor$label),df$Var1), ]
plot(data_anchor[,3],data_anchor[,4],pch=20,main=paste0(datalabel," + 1KG anchor, PC1 vs PC2"),col=data_anchor$color,xlab="PC1",ylab="PC2")
legend(legendpos, legend=df$Var1, fill=unique(data_anchor$color))
plot(data_anchor[,4],data_anchor[,5],pch=20,main="PC2 vs PC3",col=data_anchor$color,xlab="PC2",ylab="PC3")
plot(data_anchor[,5],data_anchor[,6],pch=20,main="PC3 vs PC4",col=data_anchor$color,xlab="PC3",ylab="PC4")
plot(data_anchor[,6],data_anchor[,7],pch=20,main="PC4 vs PC5",col=data_anchor$color,xlab="PC4",ylab="PC5")
plot(data_anchor[,7],data_anchor[,8],pch=20,main="PC5 vs PC6",col=data_anchor$color,xlab="PC5",ylab="PC6")
plot(data_anchor[,8],data_anchor[,9],pch=20,main="PC6 vs PC7",col=data_anchor$color,xlab="PC6",ylab="PC7")
invisible(dev.off())
