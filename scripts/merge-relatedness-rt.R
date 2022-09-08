#--------------------------- Description ----------------------------#

# Function: This script merges pairwise bad relatedness list with the
# KING inferred relatedness type.

# Contributors: Elizabeth Corfield, Tetyana Zayats
# Contributors: Yunhan Chu (yunhanch@gmail.com)

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript merge-relatedness-rt.R relfile rtfile
# Arguments:  relfile - the ibd relatedness file
#             rtfile - the king inferred relatedness type file
# Example:    Rscript merge-relatedness-rt.R original-initials-eur-king-3-ibd-bad-relatedness.txt original-initials-eur-king-3.RT

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# the ibd relatedness file
relfile = args[1]

# the king inferred relatedness type file
rtfile = args[2]

#----------------------------- Start code ---------------------------#

dataprefix = sub('\\..[^\\.]*$', '', relfile)

bad <- read.table(relfile,h=T,colClasses="character")
bad_match <- subset(bad, FID1==FID2)
bad_nonmatch <- subset(bad, FID1!=FID2)
rm(bad)
kin <- read.table(rtfile,h=T)
colnames(kin) <- c("IID1","IID2","InfType")
bad_kin1 <- merge(bad_match, kin, by=c("IID1", "IID2"))
bad_kin2 <- merge(bad_match, kin, by.x=c("IID1", "IID2"), by.y=c("IID2", "IID1"))
bad_kin <- rbind(bad_kin1, bad_kin2)
rm(bad_kin1, bad_kin2)
table(bad_kin$InfType)
bad_kin <- bad_kin[,c(3,1,4,2,5:15)]
write.table(bad_kin, paste0(dataprefix,'-InfType.txt'),row.names=F, col.names=T, sep='\t', quote=F)
rm(bad_kin)
id1 <- data.frame(bad_nonmatch[,2])
colnames(id1) <- "IID"
id2 <- data.frame(bad_nonmatch[,4])
colnames(id2) <- "IID"
ids <- rbind(id1, id2)
rm(id1, id2)
length(unique(ids$IID))
freq <- data.frame(table(ids$IID))
rm(ids)
colnames(freq) <- c("IID1", "Freq1")
id1 <- merge(bad_nonmatch, freq, by="IID1")
colnames(freq) <- c("IID2", "Freq2")
bad_nonmatch <- merge(id1, freq, by="IID2")
rm(id1, freq)
bad_nonmatch <- bad_nonmatch[,c(3,2,4,1,5:16)]
write.table(bad_nonmatch, paste0(dataprefix,'-Freq.txt'),row.names=F, col.names=T, sep='\t', quote=F)
rm(bad_nonmatch)
