#--------------------------- Description ----------------------------#

# Function: This script creates liftover input file.

# Contributors: Elizabeth Corfield, Tetyana Zayats
# Contributors: Yunhan Chu (yunhanch@gmail.com)

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript create-liftover-input.R dataprefix outprefix
# Arguments:  dataprefix - prefix of input bim file
#             outprefix - prefix of output bed file
# Example:    Rscript create-liftover-input.R MorBarn_Feb2018-yc-rsids MorBarn_Feb2018-yc-liftover_input

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# prefix of the path of the input bim file
dataprefix = args[1]

# prefix of the path of the output bed file
outprefix = args[2]

bim <- read.table(paste0(dataprefix,'.bim'),h=F, colClasses=c("integer","character","numeric","integer","character","character"))
bim$V7 <- as.integer(bim$V4+1)
autosome <- subset(bim, V1<=22)
autosome$V8 <- paste("chr", autosome$V1, sep="")
X <- subset(bim, V1==23)
X$V8 <- "chrX"
Y <- subset(bim, V1==24)
Y$V8 <- "chrY"
bim <- rbind(autosome, X, Y) 
lift <- bim[,c(8,4,7,2)]
write.table(lift, paste0(outprefix,'.bed'),row.names=F, col.names=F,sep='\t',quote=F)
