#--------------------------- Description ----------------------------#

# Function: This script takes the liftover output and creates a file to update the chromosome position in PLINK bfiles.

# Contributors: Elizabeth Corfield

# Usage:      Rscript create-update-chr-input.R dataprefix outprefix
# Arguments:  dataprefix - prefix of liftover bed output file
#             outprefix - prefix of output update-chr file
# Example:    Rscript create-update-chr-input.R MorBarn_May2016-ec-liftover_output.bed MorBarn_May2016-ec-liftover-update-chr

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# prefix of the path of the input bim file
dataprefix = args[1]

# prefix of the path of the output bed file
outprefix = args[2]

library(tidyr)
lift <- read.table(paste0(dataprefix,'.bed'),h=F, colClasses=c("character","integer","integer","character"))
X <- subset(lift, V1=="chrX")
X$V5 <- 23
Y <- subset(lift, V1=="chrY")
Y$V5 <- 24
sex <- rbind(X,Y)
rm(X,Y)
autosome <- lift[!lift$V4 %in% sex$V4,]
autosome <- separate(autosome, V1, into=c(NA,"V5"), sep="r", remove=F)
lift <- rbind(autosome, sex)
rm(autosome, sex)
lift <- lift[,c(5,2)]
write.table(lift, paste0(outprefix,'.txt'),row.names=F, col.names=F,sep='\t',quote=F)
