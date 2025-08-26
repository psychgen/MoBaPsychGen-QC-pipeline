#this script plots PCs of a batch alone (from PCA without 1KG)
args<-commandArgs(TRUE)
input=args[1]
title=args[2]
legendpos=args[3]
output=args[4]
data=read.table(input,h=F)
png(output,res=300,width=3000,height=3000)
par(mfrow=c(3,3))
plot(data[,3],data[,4],pch=16,col=data[,23],xlab="PC1",ylab="PC2",main=paste0(title," PC1 vs PC2"))
legend(legendpos,c("founders","non-founders"),fill=c("black","red"))
plot(data[,4],data[,5],pch=16,col=data[,23],xlab="PC2",ylab="PC3",main=paste0(title," PC2 vs PC3"))
plot(data[,5],data[,6],pch=16,col=data[,23],xlab="PC3",ylab="PC4",main=paste0(title," PC3 vs PC4"))
plot(data[,6],data[,7],pch=16,col=data[,23],xlab="PC4",ylab="PC5",main=paste0(title," PC4 vs PC5"))
plot(data[,7],data[,8],pch=16,col=data[,23],xlab="PC5",ylab="PC6",main=paste0(title," PC5 vs PC6"))
plot(data[,8],data[,9],pch=16,col=data[,23],xlab="PC6",ylab="PC7",main=paste0(title," PC6 vs PC7"))
plot(data[,9],data[,10],pch=16,col=data[,23],xlab="PC7",ylab="PC8",main=paste0(title," PC7 vs PC8"))
plot(data[,10],data[,11],pch=16,col=data[,23],xlab="PC8",ylab="PC9",main=paste0(title," PC8 vs PC9"))
plot(data[,11],data[,12],pch=16,col=data[,23],xlab="PC9",ylab="PC10",main=paste0(title," PC9 vs PC10"))
invisible(dev.off())
