#--------------------------- Description ----------------------------#

# Function: This script plots histogram of PI_HAT as well as Z0 vs Z1.

# Contributors: Yunhan Chu (yunhanch@gmail.com)
# Contributors: Elizabeth Corfield, Tetyana Zayats

# (c) 2020-2022 NORMENT, UiO

# Usage:      Rscript plot-ibd dataprefix tag
# Arguments:  data - the genome data file of ibd
#             tag - a tag of data shown in the titles of the plots
# Example:    Rscript plot-ibd.R m24-ca-eur-king-1-ibd "M24 EUR"

#-------------------------- Input paramters -------------------------#

# Import arguments from command line
args <- commandArgs(TRUE)

# prefix of the path of genome file
data = args[1]

# tag of data
tag = args[2]

#----------------------------- Start code ---------------------------#
dataprefix = sub('\\..[^\\.]*$', '', data)

if (length(args) > 2) {
   tag2 = args[2]
   for (i in 3:length(args)) {
      tag2 = paste(tag2, args[i], sep=' ')
   }
   tag = tag2
}

genome=read.table(data, header=T)

png(paste0(dataprefix,'-hist.png'))
par(mfrow=c(2,2))
hist(genome$PI_HAT,breaks=50,col="red",main=paste0("PI_HAT ",tag),xlab="PI_HAT")
hist(genome$PI_HAT,breaks=50,col="red",main=paste0("PI_HAT ",tag,"\n zoomed"),xlab="PI_HAT",xlim=c(0,0.5))
hist(genome$PI_HAT,breaks=50,col="red",main=paste0("PI_HAT ",tag,"\n zoomed"),xlab="PI_HAT",ylim=c(0,10000))
hist(genome$PI_HAT,breaks=50,col="red",main=paste0("PI_HAT ",tag,"\n zoomed"),xlab="PI_HAT",xlim=c(0,0.7),ylim=c(0,1000))
invisible(dev.off())

genome$color[genome$RT=='UN'] = 1
genome$color[genome$RT=='PO'] = 2
genome$color[genome$RT=='FS'] = 8
genome$color[genome$RT=='HS'] = 4
genome$color[genome$RT=='OT'] = 5

genome$label[genome$RT=='UN'] = "unrelated pair"
genome$label[genome$RT=='PO'] = "parent-offspring"
genome$label[genome$RT=='FS'] = "full siblings"
genome$label[genome$RT=='HS'] = "half siblings"
genome$label[genome$RT=='OT'] = "other"

genome$order[genome$RT=='PO'] = 1
genome$order[genome$RT=='FS'] = 2
genome$order[genome$RT=='HS'] = 3
genome$order[genome$RT=='OT'] = 4
genome$order[genome$RT=='UN'] = 5

genome <- genome[order(-genome$order),]

png(paste0(dataprefix,'-plot.png'),res=250,width=3000,height=1900)
plot(genome$Z0, genome$Z1, xlim=c(0,1), ylim=c(0,1), pch=16, col=genome$color, xlab="Z0",ylab="Z1", main=paste("Z0 vs Z1",tag))
legend("topright", legend=rev(unique(genome$label)), pch=16, col=rev(unique(genome$color)))
invisible(dev.off())
