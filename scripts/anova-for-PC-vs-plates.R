#this script is to run ANOVA on the first 10 PCs against the plates IDs to test for batch effects
args<-commandArgs(TRUE)
input=args[1]
output=args[2]
data=read.table(input,h=F)
data1=data[,-c(1,2)]
out=matrix(1:10,10,2)
colnames(out)=c("PC_number","ANOVA_P_VALUE")
for(i in 1:10){
out[i,2]=summary(aov(data1[,i]~data1[,21]))[[1]][[5]][1]
}
write.table(out,output,row.names=FALSE,quote=FALSE)
