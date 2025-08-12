#--------------------------- Description ----------------------------#

# Function: This script plots PC1 - PC7 of samples and 1kg samples selected from PCA.

# Contributors: Yunhan Chu (yunhanch@gmail.com), Alexey A. Shadrin
# Contributors: Elizabeth Corfield, Tetyana Zayats

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-pca-selected-subsample.R datalabel pcadata selected-sample-list selected-1kg-list outprefix
# Arguments:  tag - a tag of data shown in the title of the plot
#             pcadata - file path to the pca data
#             selected-sample-list - file path to the list of selected samples
#             selected-1kg-list - file path to the list of selected 1kg samples
#             legendpos - position of legend: topleft, topright, bottomleft, bottomright
#             outprefix - prefix of the output plot
# Example:    Rscript plot-pca-selected-subsample.R "M24 EUR" m24-1kg-ca-pca m24-ca-first-pca-plot-pc1-pc2-eur.selected_samples.csv m24-ca-first-pca-plot-pc1-pc2-eur.selected_samples_1kg.csv bottomleft m24-ca-first-pca-plots-pc1-pc7-threshold-eur

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# path of study data name
datalabel = args[1]

# path of the pca data file
pca = args[2]

# path of the file containing selected samples
sample_list = args[3]

# path of the file containing selected 1kg samples
kg_list = args[4]

# position of legend
legendpos = args[5]

# prefix of plot file
outprefix = args[6]

#----------------------------- Start code ---------------------------#

data = read.table(pca, header=F, strip.white=T, as.is=T)
samples = read.table(sample_list, header=F, strip.white=T, as.is=T)
kg = read.table(kg_list, header=F, strip.white=T, as.is=T)

num = length(data[,1])-1083
datatag = tolower(unlist(strsplit(unlist(strsplit(unlist(strsplit(datalabel, " "))[1], "-"))[1], "_"))[1])

data$color = c(rep("red", num), rep("black", 61), rep("lightblue", 85), rep("blue", 97), rep("aquamarine", 99), rep("yellow", 60), rep("green", 93), rep("purple", 89), rep("orange", 14), rep("gray", 89), rep("darkolivegreen", 91), rep("magenta", 64), rep("darkblue", 55), rep("orchid", 98), rep("cyan3", 88))

data$label = c(rep(datatag, num), rep("ASW", 61), rep("CEU", 85), rep("CHB", 97), rep("CHS", 99), rep("CLM", 60), rep("FIN", 93), rep("GBR", 89), rep("IBS", 14), rep("JPT", 89), rep("LWK", 91), rep("MXL", 64), rep("PUR", 55), rep("TSI", 98), rep("YRI", 88))

data <- data[data$V2 %in% samples$V2 | data$V1 %in% kg$V1, ]

png(width=800, height=600, paste(outprefix,'.png',sep=''))
par(mfrow=c(2,3))
df <- data.frame(table(data$label))
df <- df[match(unique(data$label),df$Var1), ]
plot(data[,3],data[,4],pch=20,main=paste0(unlist(strsplit(datalabel, " "))[1]," + 1KG threshold ",unlist(strsplit(datalabel, " "))[2]," PC1 vs PC2"),col=data$color,xlab="PC1",ylab="PC2")
legend(legendpos, title=paste0(toupper(unlist(strsplit(datalabel, " "))[2]),' subsample'), legend=paste0(df$Var1,' (',df$Freq,')'), fill=unique(data$color))
plot(data[,4],data[,5],pch=20,main="PC2 vs PC3",col=data$color,xlab="PC2",ylab="PC3")
plot(data[,5],data[,6],pch=20,main="PC3 vs PC4",col=data$color,xlab="PC3",ylab="PC4")
plot(data[,6],data[,7],pch=20,main="PC4 vs PC5",col=data$color,xlab="PC4",ylab="PC5")
plot(data[,7],data[,8],pch=20,main="PC5 vs PC6",col=data$color,xlab="PC5",ylab="PC6")
plot(data[,8],data[,9],pch=20,main="PC6 vs PC7",col=data$color,xlab="PC6",ylab="PC7")
invisible(dev.off())
