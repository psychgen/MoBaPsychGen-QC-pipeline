# /tsd/p697/data/durable/projects/moba_qc_imputation/EC/May_freeze/Release2
module load plink/1.90b6.2
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation
cd /cluster/projects/p697/projects/moba_qc_imputation/EC/Release2

# Basic QC #
plink --bfile imputed.info0p8.maf0p01 --missing --out release2-ec-eur-info-maf-missing
Rscript $GITHUB/lib/plot-missingness-histogram.R release2-ec-eur-info-maf-missing "Release2 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/May_freeze/Release2
plink --bfile imputed.info0p8.maf0p01 --geno 0.05 --make-bed --out release2-ec-eur-95
plink --bfile release2-ec-eur-95 --geno 0.02 --make-bed --out release2-ec-eur-98 # removes an extra 224859 SNPs
awk '{print $2}' release2-ec-eur-98.bim > release2-ec-eur-98.snps
plink --bfile release2-ec-eur-95 --geno 0.05 --mind 0.02 --make-bed --out release2-ec-eur-call-rates
plink --bfile release2-ec-eur-call-rates --hwe 0.000001 --make-bed --out release2-ec-eur-basic-qc
plink --bfile release2-ec-eur-basic-qc --het --missing --out release2-ec-eur-common-het-miss
Rscript $GITHUB/lib/plot-heterozygosity-common.R release2-ec-eur-common-het-miss "Release2 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/May_freeze/Release2
tail -n +2 release2-ec-eur-common-het-miss-F-het-fail.txt | wc -l
plink --bfile release2-ec-eur-basic-qc --remove release2-ec-eur-common-het-miss-F-het-fail.txt --make-bed --out release2-ec-eur-het

# Pedigree build and known relatedness #
#cp /cluster/projects/p697/projects/moba_qc_imputation/OF/GSA_may2021/*.bim.info /cluster/projects/p697/projects/moba_qc_imputation/EC/Release2
#cat chr1.step10.imputed.bim.info chr2.step10.imputed.bim.info chr3.step10.imputed.bim.info chr4.step10.imputed.bim.info chr5.step10.imputed.bim.info chr6.step10.imputed.bim.info chr7.step10.imputed.bim.info chr8.step10.imputed.bim.info chr9.step10.imputed.bim.info chr10.step10.imputed.bim.info chr11.step10.imputed.bim.info chr12.step10.imputed.bim.info chr13.step10.imputed.bim.info chr14.step10.imputed.bim.info chr15.step10.imputed.bim.info chr16.step10.imputed.bim.info chr17.step10.imputed.bim.info chr18.step10.imputed.bim.info chr19.step10.imputed.bim.info chr20.step10.imputed.bim.info chr21.step10.imputed.bim.info chr22.step10.imputed.bim.info > imputed.bim.info
#rm chr1.step10.imputed.bim.info chr2.step10.imputed.bim.info chr3.step10.imputed.bim.info chr4.step10.imputed.bim.info chr5.step10.imputed.bim.info chr6.step10.imputed.bim.info chr7.step10.imputed.bim.info chr8.step10.imputed.bim.info chr9.step10.imputed.bim.info chr10.step10.imputed.bim.info chr11.step10.imputed.bim.info chr12.step10.imputed.bim.info chr13.step10.imputed.bim.info chr14.step10.imputed.bim.info chr15.step10.imputed.bim.info chr16.step10.imputed.bim.info chr17.step10.imputed.bim.info chr18.step10.imputed.bim.info chr19.step10.imputed.bim.info chr20.step10.imputed.bim.info chr21.step10.imputed.bim.info chr22.step10.imputed.bim.info
#awk '$8>0.9998 {print $2}' imputed.bim.info > info0.9998.snps
#wc -l info0.9998.snps
#plink --bfile release2-ec-eur-het --extract info0.9998.snps --geno 0.02 --make-bed --out release2-ec-eur-info0.9998-geno98
#./match.pl -f release2-ec-eur-info0.9998-geno98.fam -g age.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > release2-ec-eur-info0.9998-geno98.cov
#sed -i '1 i\FID IID Age' release2-ec-eur-info0.9998-geno98.cov
#/cluster/projects/p697/projects/moba_qc_imputation/software/king225_patch1 --cpus 16 -b release2-ec-eur-info0.9998-geno98.bed --related --ibs  --build --degree 2 --rplot --prefix release2-ec-eur-king-1 > release2-ec-eur-king1-slurm.txt
#sh $GITHUB/tools/create-relplot.sh release2-ec-eur-king-1_relplot.R "Release2 EUR" topright bottomright topright bottomright
#awk '{print $2, $4, $19}' release2-ec-eur-king-1.ibs0 > release2-ec-eur-king-1.ibs0_hist
#Rscript $GITHUB/lib/plot-kinship-histogram.R release2-ec-eur-king-1.ibs0_hist release2-ec-eur-king-1-hist
#awk '$16>0 {print $0}' release2-ec-eur-king-1.kin > release2-ec-eur-king-1.kin-errors
#./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-king-1.kin-errors -k 4 -l 2 -v 8 > release2-ec-eur-king-1.kin-errors_role1
#./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-king-1.kin-errors_role1 -k 4 -l 3 -v 8 > release2-ec-eur-king-1.kin-errors_role2
#./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-king-1.kin-errors_role2 -k 4 -l 2 -v 3 > release2-ec-eur-king-1.kin-errors_FID1
#./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-king-1.kin-errors_FID1 -k 4 -l 3 -v 3 > release2-ec-eur-king-1.kin-errors
#rm release2-ec-eur-king-1.kin-errors_role1 release2-ec-eur-king-1.kin-errors_role2 release2-ec-eur-king-1.kin-errors_FID1
#wc -l release2-ec-eur-king-1.kin-errors
#awk '$15=="Dup/MZ" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_MZ
#wc -l release2-ec-eur-king-1.kin-errors_MZ
#awk '$15=="PO" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_PO
#wc -l release2-ec-eur-king-1.kin-errors_PO
#awk '$15=="FS" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_FS
#wc -l release2-ec-eur-king-1.kin-errors_FS
#awk '$15=="2nd" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_2nd
#wc -l release2-ec-eur-king-1.kin-errors_2nd
#awk '$15=="3rd" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_3rd
#wc -l release2-ec-eur-king-1.kin-errors_3rd
#awk '$15=="4th" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_4th
#wc -l release2-ec-eur-king-1.kin-errors_4th
#awk '$15=="UN" {print $0}' release2-ec-eur-king-1.kin-errors > release2-ec-eur-king-1.kin-errors_UN
#wc -l release2-ec-eur-king-1.kin-errors_UN
#awk '{if ($14=="Dup/MZ" || $14=="PO" || $14=="FS") print $0}' release2-ec-eur-king-1.kin0 > release2-ec-eur-king-1.kin0-errors
#wc -l release2-ec-eur-king-1.kin0-errors # 0
#plink --bfile release2-ec-eur-het --update-ids release2-ec-eur-king-1updateids-sentrix.txt --make-bed --out release2-ec-eur-king-1-ids
#plink --bfile release2-ec-eur-king-1-ids --update-parents release2-ec-eur-king-1updateparents.txt --make-bed --out release2-ec-eur-king-1-parents
#plink --bfile release2-ec-eur-king-1-parents --remove release2-ec-eur-king-1-unexpected-relationships.txt --update-parents release2-ec-eur-king-1-fix-parents.txt --make-bed --out release2-ec-eur-king-1-fix-parents

cp release2-ec-eur-info0.9998-geno98.cov release2-ec-eur-pruned.cov
plink --bfile release2-ec-eur-het --extract release2-ec-eur-98.snps --maf 0.05 --indep-pairwise 3000 1500 0.4 --out release2-ec-eur-het-prune
plink --bfile release2-ec-eur-het --extract release2-ec-eur-het-prune.prune.in --make-bed --out release2-ec-eur-het-pruned
/cluster/projects/p697/projects/moba_qc_imputation/software/king225_patch1 --cpus 16 -b release2-ec-eur-het-pruned.bed --related --ibs --build --degree 2 --rplot --prefix release2-ec-eur-pruned-king-1 > release2-ec-eur-pruned-king-1-slurm.txt
sh $GITHUB/tools/create-relplot.sh release2-ec-eur-pruned-king-1_relplot.R "Release2 EUR" topright bottomright topright bottomright
awk '{print $2, $4, $19}' release2-ec-eur-pruned-king-1.ibs0 > release2-ec-eur-pruned-king-1.ibs0_hist
Rscript $GITHUB/lib/plot-kinship-histogram.R release2-ec-eur-pruned-king-1.ibs0_hist release2-ec-eur-pruned-king-1-hist
awk '$16>0 {print $0}' release2-ec-eur-pruned-king-1.kin > release2-ec-eur-pruned-king-1.kin-errors
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-pruned-king-1.kin-errors -k 4 -l 2 -v 8 > release2-ec-eur-pruned-king-1.kin-errors_role1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-pruned-king-1.kin-errors_role1 -k 4 -l 3 -v 8 > release2-ec-eur-pruned-king-1.kin-errors_role2
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-pruned-king-1.kin-errors_role2 -k 4 -l 2 -v 3 > release2-ec-eur-pruned-king-1.kin-errors_FID1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release2-ec-eur-pruned-king-1.kin-errors_FID1 -k 4 -l 3 -v 3 > release2-ec-eur-pruned-king-1.kin-errors
rm release2-ec-eur-pruned-king-1.kin-errors_role1 release2-ec-eur-pruned-king-1.kin-errors_role2 release2-ec-eur-pruned-king-1.kin-errors_FID1
wc -l release2-ec-eur-pruned-king-1.kin-errors
awk '$15=="Dup/MZ" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_MZ
wc -l release2-ec-eur-pruned-king-1.kin-errors_MZ
awk '$15=="PO" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_PO
wc -l release2-ec-eur-pruned-king-1.kin-errors_PO
awk '$15=="FS" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_FS
wc -l release2-ec-eur-pruned-king-1.kin-errors_FS
awk '$15=="2nd" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_2nd
wc -l release2-ec-eur-pruned-king-1.kin-errors_2nd
awk '$15=="3rd" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_3rd
wc -l release2-ec-eur-pruned-king-1.kin-errors_3rd
awk '$15=="4th" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_4th
wc -l release2-ec-eur-pruned-king-1.kin-errors_4th
awk '$15=="UN" {print $0}' release2-ec-eur-pruned-king-1.kin-errors > release2-ec-eur-pruned-king-1.kin-errors_UN
wc -l release2-ec-eur-pruned-king-1.kin-errors_UN
awk '{if ($14=="Dup/MZ" || $14=="PO" || $14=="FS") print $0}' release2-ec-eur-pruned-king-1.kin0 > release2-ec-eur-pruned-king-1.kin0-errors
wc -l release2-ec-eur-pruned-king-1.kin0-errors # 0
plink --bfile release2-ec-eur-het --update-parents release2-ec-eur-pruned-king-1updateparents.txt --make-bed --out release2-ec-eur-king-1-parents
plink --bfile release2-ec-eur-king-1-parents --remove release2-ec-eur-king-1-unexpected-relationships.txt --update-parents release2-ec-eur-king-1-fix-parents.txt --make-bed --out release2-ec-eur-king-1-fix-parents

# Cryptic relatedness #
#./cryptic.sh release2-ec-eur-king-1.ibs0 release2-ec-eur-cryptic-1
#Rscript $GITHUB/lib/plot-cryptic.R release2-ec-eur-cryptic-1-kinship-sum.txt release2-ec-eur-cryptic-1-counts.txt "Release2 EUR" release2

./cryptic.sh release2-ec-eur-pruned-king-1.ibs0 release2-ec-eur-pruned-cryptic-1
Rscript $GITHUB/lib/plot-cryptic.R release2-ec-eur-pruned-cryptic-1-kinship-sum.txt release2-ec-eur-pruned-cryptic-1-counts.txt "Release2 EUR" release2-pruned

# LD prune #
plink --bfile release2-ec-eur-het --extract release2-ec-eur-98.snps --indep-pairwise 3000 1500 0.1 --out release2-ec-eur-indep
plink --bfile release2-ec-eur-het --extract release2-ec-eur-indep.prune.in --make-set high-ld.txt --write-set --out release2-ec-eur-highld
plink --bfile release2-ec-eur-het --extract release2-ec-eur-indep.prune.in --exclude release2-ec-eur-highld.set --make-bed --out release2-ec-eur-trimmed

# IBD #
plink --bfile release2-ec-eur-trimmed --genome --min 0.15 --out release2-ec-eur-ibd
Rscript $GITHUB/lib/plot-ibd.R release2-ec-eur-ibd.genome "Release2 EUR"
awk '$5=="PO" && $10<0.4 || $5=="PO" && $10>0.6 {print $0}' release2-ec-eur-ibd.genome > release2-ec-eur-ibd-bad-parents.txt
awk '$5=="FS" && $10<0.4 || $5=="FS" && $10>0.6 {print $0}' release2-ec-eur-ibd.genome > release2-ec-eur-ibd-bad-siblings.txt
awk '$5=="HS" && $10<0.15 || $5=="HS" && $10>0.35 {print $0}' release2-ec-eur-ibd.genome > release2-ec-eur-ibd-bad-half-siblings.txt
awk '$5!="PO" && $5!="FS" && $5!="HS" && $10>0.15 {print $0}' release2-ec-eur-ibd.genome > release2-ec-eur-ibd-bad-unrelated.txt
cat release2-ec-eur-ibd-bad-unrelated.txt release2-ec-eur-ibd-bad-parents.txt release2-ec-eur-ibd-bad-siblings.txt release2-ec-eur-ibd-bad-half-siblings.txt > release2-ec-eur-ibd-bad-relatedness.txt
rm release2-ec-eur-ibd-bad-unrelated.txt release2-ec-eur-ibd-bad-parents.txt release2-ec-eur-ibd-bad-siblings.txt release2-ec-eur-ibd-bad-half-siblings.txt
awk '{print $2,$3,$15}' release2-ec-eur-pruned-king-1.kin > release2-ec-eur-pruned-king-1.kin-RT
awk '{print $2,$4,$14}' release2-ec-eur-pruned-king-1.kin0 > release2-ec-eur-pruned-king-1.kin0-RT
cat release2-ec-eur-pruned-king-1.kin-RT release2-ec-eur-pruned-king-1.kin0-RT > release2-ec-eur-pruned-king-1.RT
rm release2-ec-eur-pruned-king-1.kin-RT release2-ec-eur-pruned-king-1.kin0-RT
R
bad <- read.table('release2-ec-eur-ibd-bad-relatedness.txt',h=T,colClasses="character")
bad_match <- subset(bad, FID1==FID2)
bad_nonmatch <- subset(bad, FID1!=FID2)
rm(bad)
kin <- read.table('release2-ec-eur-pruned-king-1.RT',h=T)
colnames(kin) <- c("IID1","IID2","InfType")
bad_kin1 <- merge(bad_match, kin, by=c("IID1", "IID2"))
bad_kin2 <- merge(bad_match, kin, by.x=c("IID1", "IID2"), by.y=c("IID2", "IID1"))
bad_kin <- rbind(bad_kin1, bad_kin2)
rm(bad_kin1, bad_kin2)
table(bad_kin$InfType)
bad_kin <- bad_kin[,c(3,1,4,2,5:15)]
write.table(bad_kin, 'release2-ec-eur-ibd-bad-relatedness.txt-InfType',row.names=F, col.names=T, sep='\t', quote=F)
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
write.table(bad_nonmatch, 'release2-ec-eur-ibd-bad-relatedness.txt-Freq',row.names=F, col.names=T, sep='\t', quote=F)
rm(bad_nonmatch)
q()
plink --bfile release2-ec-eur-king-1-fix-parents --missing --out release2-ec-eur-king-1-missing
./match.pl -f release2-ec-eur-king-1-missing.imiss -g release2-ec-eur-ibd-bad-relatedness.txt-InfType -k 2 -l 2 -v 6 > release2-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1
./match.pl -f release2-ec-eur-king-1-missing.imiss -g release2-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 -k 2 -l 4 -v 6 > release2-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate
./match.pl -f release2-ec-eur-king-1-missing.imiss -g release2-ec-eur-ibd-bad-relatedness.txt-Freq -k 2 -l 2 -v 6 > release2-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
./match.pl -f release2-ec-eur-king-1-missing.imiss -g release2-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1 -k 2 -l 4 -v 6 > release2-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate
rm release2-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 release2-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
plink --bfile release2-ec-eur-king-1-fix-parents --remove release2-ec-eur-king-1-bad-relatedness-low-call-rate.txt --make-bed --out release2-ec-eur-ibd-clean

# Mendelian errors #
plink --bfile release2-ec-eur-ibd-clean --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out release2-ec-eur-me-clean-sex

# PCA with 1000 genomes #
plink --bfile release2-ec-eur-me-clean-sex --extract release2-ec-eur-indep.prune.in --exclude release2-ec-eur-highld.set --make-bed --out release2-ec-eur-me-clean-trimmed
cp /tsd/p697/data/durable/projects/moba_qc_imputation/resources/1kg.* /cluster/projects/p697/projects/moba_qc_imputation/EC/Release2
cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
cut -f2 release2-ec-eur-me-clean-trimmed.bim | sort -s > release2-ec-eur-me-clean-trimmed.bim.sorted
join 1kg.bim.sorted release2-ec-eur-me-clean-trimmed.bim.sorted > release2-ec-eur-me-clean-1kg-snps.txt
rm release2-ec-eur-me-clean-trimmed.bim.sorted 1kg.bim.sorted
wc -l release2-ec-eur-me-clean-1kg-snps.txt
plink --bfile release2-ec-eur-me-clean-trimmed --extract release2-ec-eur-me-clean-1kg-snps.txt --make-bed --out release2-ec-eur-1kg-common
plink --bfile 1kg --extract release2-ec-eur-me-clean-1kg-snps.txt --make-bed --out 1kg-release2-ec-eur-common
plink --bfile release2-ec-eur-1kg-common --bmerge 1kg-release2-ec-eur-common --make-bed --out release2-ec-eur-1kg-merged
plink --bfile 1kg-release2-ec-eur-common --flip release2-ec-eur-1kg-merged-merge.missnp --make-bed --out 1kg-release2-ec-eur-common-flip
plink --bfile release2-ec-eur-1kg-common --bmerge 1kg-release2-ec-eur-common-flip --make-bed --out release2-ec-eur-1kg-second-merged
plink --bfile release2-ec-eur-1kg-common --exclude release2-ec-eur-1kg-second-merged-merge.missnp --make-bed --out release2-ec-eur-1kg-common-clean
plink --bfile 1kg-release2-ec-eur-common-flip --exclude release2-ec-eur-1kg-second-merged-merge.missnp --make-bed --out 1kg-release2-ec-eur-common-flip-clean
plink --bfile release2-ec-eur-1kg-common-clean --bmerge 1kg-release2-ec-eur-common-flip-clean --make-bed --out release2-ec-eur-1kg-clean-merged
wc -l release2-ec-eur-1kg-clean-merged.bim
cp /tsd/p697/data/durable/projects/moba_qc_imputation/resources/populations.txt /cluster/projects/p697/projects/moba_qc_imputation/EC/Release2
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' release2-ec-eur-1kg-clean-merged.fam > release2-ec-eur-1kg-clean-merged-populations.txt
awk '$3=="parent" {print $0}' release2-ec-eur-1kg-clean-merged-populations.txt > release2-ec-eur-1kg-merged-founders
plink --bfile release2-ec-eur-1kg-clean-merged --keep release2-ec-eur-1kg-merged-founders --keep-allele-order --make-bed --out release2-ec-eur-1kg-clean-merged-founders
./flashpca_x86-64 --bfile release2-ec-eur-1kg-clean-merged-founders --outload release2-ec-eur-1kg-founders-loadings.txt --outmeansd release2-ec-eur-1kg-founders-meansd.txt --suffix -release2-ec-eur-1kg-founders-pca.txt > release2-ec-eur-1kg-founders-pca.log
./flashpca_x86-64 --bfile release2-ec-eur-1kg-clean-merged --project --inmeansd release2-ec-eur-1kg-founders-meansd.txt --outproj release2-ec-eur-1kg-projections.txt --inload release2-ec-eur-1kg-founders-loadings.txt -v > release2-ec-eur-1kg-projections.log
sort -k2 release2-ec-eur-1kg-projections.txt > release2-ec-eur-1kg-projections.txt-sorted
head -n 62013 release2-ec-eur-1kg-projections.txt-sorted > release2-ec-eur-pca
tail -n 1083 release2-ec-eur-1kg-projections.txt-sorted | sort -k2 > 1kg-ec-eur-fin-pca
cat release2-ec-eur-pca 1kg-ec-eur-fin-pca > release2-ec-eur-1kg-pca
Rscript $GITHUB/lib/plot-pca-with-1kg.R Release2 release2-ec-eur-1kg-pca topleft release2-ec-eur-1kg

# PCA without 1000 genomes #
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' release2-ec-eur-me-clean-trimmed.fam > release2-ec-eur-me-clean-trimmed-populations.txt
awk '$3=="parent" {print $0}' release2-ec-eur-me-clean-trimmed-populations.txt > release2-ec-eur-me-clean-trimmed-founders
plink --bfile release2-ec-eur-me-clean-trimmed --keep release2-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out release2-ec-eur-me-clean-trimmed-founders
./flashpca_x86-64 --bfile release2-ec-eur-me-clean-trimmed-founders --outload release2-ec-eur-founders-loadings.txt --outmeansd release2-ec-eur-founders-meansd.txt --suffix -release2-ec-eur-founders-pca.txt > release2-ec-eur-founders-pca.log
./flashpca_x86-64 --bfile release2-ec-eur-me-clean-trimmed --project --inmeansd release2-ec-eur-founders-meansd.txt --outproj release2-ec-eur-projections.txt --inload release2-ec-eur-founders-loadings.txt -v > release2-ec-eur-projections.log
awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red"}' release2-ec-eur-me-clean-trimmed.fam > release2-ec-eur-me-clean-trimmed-fam.txt
./match.pl -f release2-ec-eur-me-clean-trimmed-fam.txt -g release2-ec-eur-projections.txt -k 2 -l 2 -v 3 > release2-ec-eur-pca-fam.txt
Rscript plot-batch-PCs.R release2-ec-eur-pca-fam.txt "Release2 EUR" bottomright release2-ec-eur-pca.png

# Batch effects #
./match.pl -f release2-batches.txt -g release2-ec-eur-projections.txt -k 1 -l 2 -v 2 | awk '$13!="-" {print $0}' | sort -k13 > release2-ec-eur-pca-batch.txt
awk '{print $1,$2,$13}' release2-ec-eur-pca-batch.txt > release2-ec-eur-batch-groups.txt
Rscript plot-PC-by-batch.R release2-ec-eur-pca-batch.txt "Release2 EUR" release2-ec-eur
Rscript anova-for-PC-vs-plates.R release2-ec-eur-pca-batch.txt release2-ec-eur-pca-anova-results.txt
more release2-ec-eur-pca-anova-results.txt
plink --bfile release2-ec-eur-me-clean-sex --filter-founders --chr 1-22 --pheno release2-ec-eur-me-clean-sex.fam --mpheno 3 --within release2-ec-eur-batch-groups.txt --mh2 --out release2-ec-eur-mh-batch
Rscript $GITHUB/lib/plot-qqplot.R release2-ec-eur-mh-batch.cmh2 "Release2 EUR" 5 release2-ec-eur-mh-batch-test-qq-plot
sort -k5 -g release2-ec-eur-mh-batch.cmh2 | grep -v "NA" > release2-ec-eur-mh2-batch-sorted
awk '$5<0.00000005 {print $2}' release2-ec-eur-mh2-batch-sorted > release2-ec-eur-mh2-batch-significant
wc -l release2-ec-eur-mh2-batch-significant
plink --bfile release2-ec-eur-me-clean-sex --exclude release2-ec-eur-mh2-batch-significant --make-bed --out release2-ec-eur-batch
plink --bfile release2-ec-eur-batch --extract release2-ec-eur-indep.prune.in --exclude release2-ec-eur-highld.set --make-bed --out release2-ec-eur-batch-trimmed
plink --bfile release2-ec-eur-batch-trimmed --keep release2-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out release2-ec-eur-batch-trimmed-founders
./flashpca_x86-64 --bfile release2-ec-eur-batch-trimmed-founders --outload release2-ec-eur-batch-founders-loadings.txt --outmeansd release2-ec-eur-batch-founders-meansd.txt --suffix -release2-ec-eur-batch-founders-pca.txt > release2-ec-eur-batch-founders-pca.log
./flashpca_x86-64 --bfile release2-ec-eur-batch-trimmed --project --inmeansd release2-ec-eur-batch-founders-meansd.txt --outproj release2-ec-eur-batch-projections.txt --inload release2-ec-eur-batch-founders-loadings.txt -v > release2-ec-eur-batch-projections.log
./match.pl -f release2-batches.txt -g release2-ec-eur-projections.txt -k 1 -l 2 -v 2 | awk '$13!="-" {print $0}' | sort -k23 > release2-ec-eur-batch-pca-batch.txt
Rscript anova-for-PC-vs-plates.R release2-ec-eur-batch-pca-batch.txt release2-ec-eur-batch-pca-anova-results.txt
more release2-ec-eur-batch-pca-anova-results.txt

#Basic QC #
plink --bfile release2-ec-eur-batch --maf 0.01 --make-bed --out release2-ec-eur-batch-common
plink --bfile release2-ec-eur-batch-common --geno 0.05 --make-bed --out release2-ec-eur-batch-95
plink --bfile release2-ec-eur-batch-95 --geno 0.05 --mind 0.02 --make-bed --out release2-ec-eur-batch-call-rates
plink --bfile release2-ec-eur-batch-call-rates --hwe 0.000001 --make-bed --out release2-ec-eur-batch-basic-qc

plink --bfile release2-ec-eur-batch-basic-qc --het --missing --out release2-ec-eur-batch-het-miss
Rscript $GITHUB/lib/plot-heterozygosity-common.R release2-ec-eur-batch-het-miss "Release2 EUR"
tail -n +2 release2-ec-eur-batch-het-miss-F-het-fail.txt | wc -l
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/May_freeze/Release2

plink --bfile release2-ec-eur-batch-basic-qc --extract release2-ec-eur-indep.prune.in --exclude release2-ec-eur-highld.set --genome --min 0.15 --out release2-ec-eur-batch-ibd
plink --bfile release2-ec-eur-batch-basic-qc --extract release2-ec-eur-het-prune.prune.in --make-bed --out release2-ec-eur-batch-basic-qc-pruned
/cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b release2-ec-eur-batch-basic-qc-pruned.bed --related --degree 2 --rplot --prefix release2-ec-eur-batch-rel > release2-ec-eur-batch-rel.log



