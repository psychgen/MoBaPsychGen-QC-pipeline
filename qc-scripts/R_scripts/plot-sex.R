#this script is to plot F vs missingness for X chromosome stratifies by reported sex
args<-commandArgs(TRUE)
input=args[1]
title=args[2]
legendpos=args[3]
output=args[4]
data=read.table(input,h=T)
png(output,res=250,width=2500,height=1900)
plot(data$F,data$F_MISS,col=data$PEDSEX,pch=16,xlab="X chromosome heterozygosity",ylab="X chromosome missingness F value",main=paste0(title," sex check"))
abline(v=c(0.2,0.8), lty=2, col="blue")
legend(legendpos,c("male","female"),fill=c("black","red"))
invisible(dev.off())
