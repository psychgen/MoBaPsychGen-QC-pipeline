#This script plots a histogram of Kinship between families as estimated by KING

args<-commandArgs(TRUE)
input=args[1]
output=args[2]
data=read.table(input,h=T)

png(paste0(output,".png"),res=250,height=1500,width=1900)
par(mfrow=c(1,2))
hist(data$Kinship,breaks=50,col="red",main="Kinship between families",xlab="Estimated Kinship Coefficient")
hist(data$Kinship,breaks=50,col="red",main="Kinship between families, zoomed",xlab="Estimated Kinship Coefficient",ylim=c(0,10000))
invisible(dev.off())
