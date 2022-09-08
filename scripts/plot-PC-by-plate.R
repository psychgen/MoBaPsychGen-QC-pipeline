#this script creates PC plot(s) colored by plate
args<-commandArgs(TRUE)
input=args[1]
tag=args[2]
output=args[3]
data=read.table(input,h=F)
number=length(unique(data[,23]))
data$col=factor(data[,23],levels=unique(data[,23]),label=heat.colors(number))

png(width=900,height=500,file=paste0(output,"-PC-vs-PC-by-plate.png"))
par(mfrow=c(1,2))
plot(data[,3],data[,4],xlab="PC1",ylab="PC2",main=paste0(tag," PC1 vs PC2, ",number," plates"),pch=16,col=data$col)
plot(data[,5],data[,6],xlab="PC3",ylab="PC4",main=paste0(tag," PC3 vs PC4, ",number," plates"),pch=16,col=data$col)
invisible(dev.off())

png(width=900,height=700,file=paste0(output,"-PC-boxplots-by-plate.png"))
par(mfrow=c(2,2))
boxplot(data[,3]~data[,23],xlab="plate",ylab="PC1",main=paste0(tag," PC1 by plate, ",number," plates"),pch=16,col=heat.colors(number)[unique(data[,23])],cex.lab=1.2,xaxt="n")
axis(1, at=1:number)
boxplot(data[,4]~data[,23],xlab="plate",ylab="PC2",main=paste0(tag," PC2 by plate, ",number," plates"),pch=16,col=heat.colors(number)[unique(data[,23])],cex.lab=1.2,xaxt="n")
axis(1, at=1:number)
boxplot(data[,5]~data[,23],xlab="plate",ylab="PC3",main=paste0(tag," PC3 by plate, ",number," plates"),pch=16,col=heat.colors(number)[unique(data[,23])],cex.lab=1.2,xaxt="n")
axis(1, at=1:number)
boxplot(data[,6]~data[,23],xlab="plate",ylab="PC4",main=paste0(tag," PC4 by plate, ",number," plates"),pch=16,col=heat.colors(number)[unique(data[,23])],cex.lab=1.2,xaxt="n")
axis(1, at=1:number)
invisible(dev.off())
