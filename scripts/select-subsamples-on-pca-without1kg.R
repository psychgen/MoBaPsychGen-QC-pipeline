# Args:
#   pcadata: file path to the pca data
#   outprefix: prefix of the output plots
#   customfile: file customized with thresholds for the plots

# Import arguments from command line
args <- commandArgs(TRUE)
# path to the ${PREFIX}-1-keep-pca-fam.txt file
pca = args[1]
# prefix of plot name
outprefix = args[2]
# custom file, contains a single line with filtering conditions, for example:
# PC1 > -0.02 & PC1 < 0 & PC2 > -0.005 & PC2 < 0.01 
customfile = args[3]


# filter eigenvec file
df=read.table(pca, sep="", header=F, strip.white=T, as.is=T)
n_pc=ncol(df) - 3
custom <- readLines(customfile)
custom <- custom[trimws(custom) != ""]

for (j in 1:n_pc) {
    custom <- gsub(paste0("PC",j), paste0("df$V",j+2), custom)
}

df_sub = subset(df,eval(parse(text=custom)))
outf_keep = paste0(outprefix,"-1-pca-keep.txt")
write.table(df_sub[,c(1,2)], outf_keep, sep=' ', quote=F, row.names=F, col.names=F)

outf_keep_fam = paste0(outprefix,"-1-keep-pca-fam-keep.txt")
write.table(df_sub, outf_keep_fam, sep=" ", quote=F, row.names=F, col.names=F)

