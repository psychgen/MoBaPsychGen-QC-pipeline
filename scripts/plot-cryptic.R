#this script will generate plots for detection of cryptic relatedness

args<-commandArgs(TRUE)
input1=args[1]
input2=args[2]
tag=args[3]
outprefix=args[4]
sum=read.table(input1,h=F)
count=read.table(input2,h=F)
png(width=900,height=500,file=paste0(outprefix,"-kinship-sum-and-count-scatter-plots.png"))
par(mfrow=c(1,2))
plot(sum[,1], sum[,2], xlab="Individual", ylab="Sum of Kinship", main=paste0(tag,",\nSum of all kinships >= 2.5% per individual"), pch=16, xaxt='n')
plot(count[,1], count[,2], xlab="Individual", ylab="Count", main=paste0(tag,",\nNumber of all kinships >= 2.5% per individual"), pch=16, xaxt='n')
invisible(dev.off())
png(paste0(outprefix,"-kinship-sum-and-count-histograms.png"),res=250,height=1500,width=1900)
par(mfrow=c(2,2))
hist(sum[,2], xlab="Sum of Kinship", main=paste0(tag,",\nSum of all kinships >= 2.5% per individual"), cex.main=0.85, col="red")
hist(sum[,2], xlab="Sum of Kinship", main=paste0(tag,",\nSum of all kinships >= 2.5% per individual"), cex.main=0.85, col="red", ylim=c(0,100))
hist(count[,2], xlab="Count", main=paste0(tag,",\nNumber of all kinships >= 2.5% per individual"), cex.main=0.85, col="red")
hist(count[,2], xlab="Count", main=paste0(tag,",\nNumber of all kinships >= 2.5% per individual"), cex.main=0.85, col="red", ylim=c(0,100))
invisible(dev.off())
