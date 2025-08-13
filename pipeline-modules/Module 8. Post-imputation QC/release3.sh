# /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
module load plink/1.90b6.2
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation
cd /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3

cp /cluster/projects/p697/projects/moba_qc_imputation/OF/Release3/imputed.info0p8.maf0p01.bed /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3
cp /cluster/projects/p697/projects/moba_qc_imputation/OF/Release3/imputed.info0p8.maf0p01.bim /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3
cp /cluster/projects/p697/projects/moba_qc_imputation/OF/Release3/imputed.info0p8.maf0p01.fam /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3
cp /cluster/projects/p697/projects/moba_qc_imputation/OF/Release3/imputed.info0p8.maf0p01.bim.info /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3

# Basic QC #
plink --bfile imputed.info0p8.maf0p01 --missing --out release3-ec-eur-info-maf-missing
Rscript $GITHUB/lib/plot-missingness-histogram.R release3-ec-eur-info-maf-missing "Release3 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
plink --bfile imputed.info0p8.maf0p01 --geno 0.05 --make-bed --out release3-ec-eur-95
plink --bfile release3-ec-eur-95 --geno 0.02 --make-bed --out release3-ec-eur-98 # removes an extra 216431 SNPs
awk '{print $2}' release3-ec-eur-98.bim > release3-ec-eur-98.snps
plink --bfile release3-ec-eur-95 --geno 0.05 --mind 0.02 --make-bed --out release3-ec-eur-call-rates
plink --bfile release3-ec-eur-call-rates --hwe 0.000001 --make-bed --out release3-ec-eur-basic-qc
plink --bfile release3-ec-eur-basic-qc --het --missing --out release3-ec-eur-common-het-miss
Rscript $GITHUB/lib/plot-heterozygosity-common.R release3-ec-eur-common-het-miss "Release3 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
tail -n +2 release3-ec-eur-common-het-miss-F-het-fail.txt | wc -l
plink --bfile release3-ec-eur-basic-qc --remove release3-ec-eur-common-het-miss-F-het-fail.txt --make-bed --out release3-ec-eur-het

# Pedigree build and known relatedness #
./match.pl -f bfile release3-ec-eur-het.fam -g age.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > release3-ec-eur-het.cov
sed -i '1 i\FID IID Age' release3-ec-eur-het.cov
plink --bfile release3-ec-eur-het --extract release3-ec-eur-98.snps --maf 0.05 --indep-pairwise 3000 1500 0.4 --out release3-ec-eur-het-prune
plink --bfile release3-ec-eur-het --extract release3-ec-eur-het-prune.prune.in --make-bed --out release3-ec-eur-het-pruned
/cluster/projects/p697/projects/moba_qc_imputation/software/king225_patch1 --cpus 16 -b release3-ec-eur-het-pruned.bed --related --ibs --build --degree 2 --rplot --prefix release3-ec-eur-pruned-king-1 > release3-ec-eur-pruned-king-1-slurm.txt
sh $GITHUB/tools/create-relplot.sh release3-ec-eur-pruned-king-1_relplot.R "Release3 EUR" topright bottomright topright bottomright
awk '{print $2, $4, $19}' release3-ec-eur-pruned-king-1.ibs0 > release3-ec-eur-pruned-king-1.ibs0_hist
Rscript $GITHUB/lib/plot-kinship-histogram.R release3-ec-eur-pruned-king-1.ibs0_hist release3-ec-eur-pruned-king-1-hist
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
awk '$16>0 {print $0}' release3-ec-eur-pruned-king-1.kin > release3-ec-eur-pruned-king-1.kin-errors
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release3-ec-eur-pruned-king-1.kin-errors -k 4 -l 2 -v 8 > release3-ec-eur-pruned-king-1.kin-errors_role1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release3-ec-eur-pruned-king-1.kin-errors_role1 -k 4 -l 3 -v 8 > release3-ec-eur-pruned-king-1.kin-errors_role2
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release3-ec-eur-pruned-king-1.kin-errors_role2 -k 4 -l 2 -v 3 > release3-ec-eur-pruned-king-1.kin-errors_FID1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release3-ec-eur-pruned-king-1.kin-errors_FID1 -k 4 -l 3 -v 3 > release3-ec-eur-pruned-king-1.kin-errors
rm release3-ec-eur-pruned-king-1.kin-errors_role1 release3-ec-eur-pruned-king-1.kin-errors_role2 release3-ec-eur-pruned-king-1.kin-errors_FID1
wc -l release3-ec-eur-pruned-king-1.kin-errors
awk '$15=="Dup/MZ" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_MZ
wc -l release3-ec-eur-pruned-king-1.kin-errors_MZ
awk '$15=="PO" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_PO
wc -l release3-ec-eur-pruned-king-1.kin-errors_PO
awk '$15=="FS" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_FS
wc -l release3-ec-eur-pruned-king-1.kin-errors_FS
awk '$15=="2nd" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_2nd
wc -l release3-ec-eur-pruned-king-1.kin-errors_2nd
awk '$15=="3rd" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_3rd
wc -l release3-ec-eur-pruned-king-1.kin-errors_3rd
awk '$15=="4th" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_4th
wc -l release3-ec-eur-pruned-king-1.kin-errors_4th
awk '$15=="UN" {print $0}' release3-ec-eur-pruned-king-1.kin-errors > release3-ec-eur-pruned-king-1.kin-errors_UN
wc -l release3-ec-eur-pruned-king-1.kin-errors_UN
awk '{if ($14=="Dup/MZ" || $14=="PO" || $14=="FS") print $0}' release3-ec-eur-pruned-king-1.kin0 > release3-ec-eur-pruned-king-1.kin0-errors
wc -l release3-ec-eur-pruned-king-1.kin0-errors # 0

# Cryptic relatedness #
./cryptic.sh release3-ec-eur-pruned-king-1.ibs0 release3-ec-eur-pruned-cryptic-1
Rscript $GITHUB/lib/plot-cryptic.R release3-ec-eur-pruned-cryptic-1-kinship-sum.txt release3-ec-eur-pruned-cryptic-1-counts.txt "Release3 EUR" release3-pruned
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/

# LD prune #
plink --bfile release3-ec-eur-het --extract release3-ec-eur-98.snps --indep-pairwise 3000 1500 0.1 --out release3-ec-eur-indep
plink --bfile release3-ec-eur-het --extract release3-ec-eur-indep.prune.in --make-set high-ld.txt --write-set --out release3-ec-eur-highld
plink --bfile release3-ec-eur-het --extract release3-ec-eur-indep.prune.in --exclude release3-ec-eur-highld.set --make-bed --out release3-ec-eur-trimmed

# IBD #
plink --bfile release3-ec-eur-trimmed --genome --min 0.15 --out release3-ec-eur-ibd
awk '{print $5,$7,$8,$10}' release3-ec-eur-ibd.genome > release3-ec-eur-ibd.txt
Rscript $GITHUB/lib/plot-ibd.R release3-ec-eur-ibd.txt "Release3 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
rm release3-ec-eur-ibd.txt
awk '$5=="PO" && $10<0.4 || $5=="PO" && $10>0.6 {print $0}' release3-ec-eur-ibd.genome > release3-ec-eur-ibd-bad-parents.txt
awk '$5=="FS" && $10<0.4 || $5=="FS" && $10>0.6 {print $0}' release3-ec-eur-ibd.genome > release3-ec-eur-ibd-bad-siblings.txt
awk '$5=="HS" && $10<0.15 || $5=="HS" && $10>0.35 {print $0}' release3-ec-eur-ibd.genome > release3-ec-eur-ibd-bad-half-siblings.txt
awk '$5!="PO" && $5!="FS" && $5!="HS" && $10>0.15 {print $0}' release3-ec-eur-ibd.genome > release3-ec-eur-ibd-bad-unrelated.txt
cat release3-ec-eur-ibd-bad-unrelated.txt release3-ec-eur-ibd-bad-parents.txt release3-ec-eur-ibd-bad-siblings.txt release3-ec-eur-ibd-bad-half-siblings.txt > release3-ec-eur-ibd-bad-relatedness.txt
rm release3-ec-eur-ibd-bad-unrelated.txt release3-ec-eur-ibd-bad-parents.txt release3-ec-eur-ibd-bad-siblings.txt release3-ec-eur-ibd-bad-half-siblings.txt
awk '{print $2,$3,$15}' release3-ec-eur-pruned-king-1.kin > release3-ec-eur-pruned-king-1.kin-RT
awk '{print $2,$4,$14}' release3-ec-eur-pruned-king-1.kin0 > release3-ec-eur-pruned-king-1.kin0-RT
cat release3-ec-eur-pruned-king-1.kin-RT release3-ec-eur-pruned-king-1.kin0-RT > release3-ec-eur-pruned-king-1.RT
rm release3-ec-eur-pruned-king-1.kin-RT release3-ec-eur-pruned-king-1.kin0-RT
R
bad <- read.table('release3-ec-eur-ibd-bad-relatedness.txt',h=T,colClasses="character")
bad_match <- subset(bad, FID1==FID2)
bad_nonmatch <- subset(bad, FID1!=FID2)
rm(bad)
kin <- read.table('release3-ec-eur-pruned-king-1.RT',h=T)
colnames(kin) <- c("IID1","IID2","InfType")
bad_kin1 <- merge(bad_match, kin, by=c("IID1", "IID2"))
bad_kin2 <- merge(bad_match, kin, by.x=c("IID1", "IID2"), by.y=c("IID2", "IID1"))
bad_kin <- rbind(bad_kin1, bad_kin2)
rm(bad_kin1, bad_kin2)
table(bad_kin$InfType)
bad_kin <- bad_kin[,c(3,1,4,2,5:15)]
write.table(bad_kin, 'release3-ec-eur-ibd-bad-relatedness.txt-InfType',row.names=F, col.names=T, sep='\t', quote=F)
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
write.table(bad_nonmatch, 'release3-ec-eur-ibd-bad-relatedness.txt-Freq',row.names=F, col.names=T, sep='\t', quote=F)
rm(bad_nonmatch)
q()
plink --bfile release3-ec-eur-het --missing --out release3-ec-eur-king-1-missing
./match.pl -f release3-ec-eur-king-1-missing.imiss -g release3-ec-eur-ibd-bad-relatedness.txt-InfType -k 2 -l 2 -v 6 > release3-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1
./match.pl -f release3-ec-eur-king-1-missing.imiss -g release3-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 -k 2 -l 4 -v 6 > release3-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate
./match.pl -f release3-ec-eur-king-1-missing.imiss -g release3-ec-eur-ibd-bad-relatedness.txt-Freq -k 2 -l 2 -v 6 > release3-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
./match.pl -f release3-ec-eur-king-1-missing.imiss -g release3-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1 -k 2 -l 4 -v 6 > release3-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate
rm release3-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 release3-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
plink --bfile release3-ec-eur-het --remove release3-ec-eur-king-1-bad-relatedness-low-call-rate.txt --make-bed --out release3-ec-eur-ibd-clean

# Mendelian errors #
plink --bfile release3-ec-eur-ibd-clean --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out release3-ec-eur-me-clean-sex

# PCA with 1000 genomes #
plink --bfile release3-ec-eur-me-clean-sex --extract release3-ec-eur-indep.prune.in --exclude release3-ec-eur-highld.set --make-bed --out release3-ec-eur-me-clean-trimmed
cp /tsd/p697/data/durable/projects/moba_qc_imputation/resources/1kg.* /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3
cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
cut -f2 release3-ec-eur-me-clean-trimmed.bim | sort -s > release3-ec-eur-me-clean-trimmed.bim.sorted
join 1kg.bim.sorted release3-ec-eur-me-clean-trimmed.bim.sorted > release3-ec-eur-me-clean-1kg-snps.txt
rm release3-ec-eur-me-clean-trimmed.bim.sorted 1kg.bim.sorted
wc -l release3-ec-eur-me-clean-1kg-snps.txt
plink --bfile release3-ec-eur-me-clean-trimmed --extract release3-ec-eur-me-clean-1kg-snps.txt --make-bed --out release3-ec-eur-1kg-common
plink --bfile 1kg --extract release3-ec-eur-me-clean-1kg-snps.txt --make-bed --out 1kg-release3-ec-eur-common
plink --bfile release3-ec-eur-1kg-common --bmerge 1kg-release3-ec-eur-common --make-bed --out release3-ec-eur-1kg-merged
plink --bfile 1kg-release3-ec-eur-common --flip release3-ec-eur-1kg-merged-merge.missnp --make-bed --out 1kg-release3-ec-eur-common-flip
plink --bfile release3-ec-eur-1kg-common --bmerge 1kg-release3-ec-eur-common-flip --make-bed --out release3-ec-eur-1kg-second-merged
plink --bfile release3-ec-eur-1kg-common --exclude release3-ec-eur-1kg-second-merged-merge.missnp --make-bed --out release3-ec-eur-1kg-common-clean
plink --bfile 1kg-release3-ec-eur-common-flip --exclude release3-ec-eur-1kg-second-merged-merge.missnp --make-bed --out 1kg-release3-ec-eur-common-flip-clean
plink --bfile release3-ec-eur-1kg-common-clean --bmerge 1kg-release3-ec-eur-common-flip-clean --make-bed --out release3-ec-eur-1kg-clean-merged
wc -l release3-ec-eur-1kg-clean-merged.bim
cp /tsd/p697/data/durable/projects/moba_qc_imputation/resources/populations.txt /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' release3-ec-eur-1kg-clean-merged.fam > release3-ec-eur-1kg-clean-merged-populations.txt
awk '$3=="parent" {print $0}' release3-ec-eur-1kg-clean-merged-populations.txt > release3-ec-eur-1kg-merged-founders
plink --bfile release3-ec-eur-1kg-clean-merged --keep release3-ec-eur-1kg-merged-founders --keep-allele-order --make-bed --out release3-ec-eur-1kg-clean-merged-founders
./flashpca_x86-64 --bfile release3-ec-eur-1kg-clean-merged-founders -d 20 --outload release3-ec-eur-1kg-founders-loadings.txt --outmeansd release3-ec-eur-1kg-founders-meansd.txt --suffix -release3-ec-eur-1kg-founders-pca.txt > release3-ec-eur-1kg-founders-pca.log
./flashpca_x86-64 --bfile release3-ec-eur-1kg-clean-merged -d 20 --project --inmeansd release3-ec-eur-1kg-founders-meansd.txt --outproj release3-ec-eur-1kg-projections.txt --inload release3-ec-eur-1kg-founders-loadings.txt -v > release3-ec-eur-1kg-projections.log
tail -n +2 release3-ec-eur-1kg-projections.txt | sort -k2 > release3-ec-eur-1kg-projections.txt-sorted
head -n 45563 release3-ec-eur-1kg-projections.txt-sorted > release3-ec-eur-pca
tail -n 1083 release3-ec-eur-1kg-projections.txt-sorted | sort -k2 > 1kg-ec-eur-fin-pca
cat release3-ec-eur-pca 1kg-ec-eur-fin-pca > release3-ec-eur-1kg-pca
Rscript $GITHUB/lib/plot-pca-with-1kg.R Release3 release3-ec-eur-1kg-pca bottomleft release3-ec-eur-1kg
Rscript $GITHUB/lib/select-subsamples-on-pca.R Release3 release3-ec-eur-1kg-pca release3-ec-eur-selection release3-ec-eur-pca-core-select-custom.txt
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/

# PCA without 1000 genomes #
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' release3-ec-eur-me-clean-trimmed.fam > release3-ec-eur-me-clean-trimmed-populations.txt
awk '$3=="parent" {print $0}' release3-ec-eur-me-clean-trimmed-populations.txt > release3-ec-eur-me-clean-trimmed-founders
plink --bfile release3-ec-eur-me-clean-trimmed --keep release3-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out release3-ec-eur-me-clean-trimmed-founders
./flashpca_x86-64 --bfile release3-ec-eur-me-clean-trimmed-founders -d 20 --outload release3-ec-eur-founders-loadings.txt --outmeansd release3-ec-eur-founders-meansd.txt --suffix -release3-ec-eur-founders-pca.txt > release3-ec-eur-founders-pca.log
./flashpca_x86-64 --bfile release3-ec-eur-me-clean-trimmed -d 20 --project --inmeansd release3-ec-eur-founders-meansd.txt --outproj release3-ec-eur-projections.txt --inload release3-ec-eur-founders-loadings.txt -v > release3-ec-eur-projections.log
awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red"}' release3-ec-eur-me-clean-trimmed.fam > release3-ec-eur-me-clean-trimmed-fam.txt
./match.pl -f release3-ec-eur-me-clean-trimmed-fam.txt -g release3-ec-eur-projections.txt -k 2 -l 2 -v 3 > release3-ec-eur-pca-fam.txt
tail -n +2 release3-ec-eur-pca-fam.txt > release3-ec-eur-pca-fam.txt_noheader
Rscript $GITHUB/lib/plot-batch-PCs.R release3-ec-eur-pca-fam.txt_noheader "Release3 EUR" topright release3-ec-eur-pca.png
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/

# Batch effects #
cp /tsd/p697/data/durable/projects/moba_qc_imputation/resources/GSA-batches.txt /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3
./match.pl -f GSA-batches.txt -g release3-ec-eur-projections.txt -k 1 -l 2 -v 2 | awk '$23!="-" {print $0}' | sort -k23 | tail -n +2 > release3-ec-eur-pca-batch.txt
awk '{print $1,$2,$23}' release3-ec-eur-pca-batch.txt > release3-ec-eur-batch-groups.txt
Rscript $GITHUB/lib/plot-PC-by-batch.R release3-ec-eur-pca-batch.txt "Release3 EUR" release3-ec-eur
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
Rscript $GITHUB/lib/anova-for-PC-vs-plates.R release3-ec-eur-pca-batch.txt release3-ec-eur-pca-anova-results.txt
more release3-ec-eur-pca-anova-results.txt
plink --bfile release3-ec-eur-me-clean-sex --filter-founders --chr 1-22 --pheno release3-ec-eur-me-clean-sex.fam --mpheno 3 --within release3-ec-eur-batch-groups.txt --mh2 --out release3-ec-eur-mh-batch
Rscript $GITHUB/lib/plot-qqplot.R release3-ec-eur-mh-batch.cmh2 "Release3 EUR" 5 release3-ec-eur-mh-batch-test-qq-plot
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/
sort -k5 -g release3-ec-eur-mh-batch.cmh2 | grep -v "NA" > release3-ec-eur-mh2-batch-sorted
awk '$5<0.00000005 {print $2}' release3-ec-eur-mh2-batch-sorted > release3-ec-eur-mh2-batch-significant
wc -l release3-ec-eur-mh2-batch-significant
plink --bfile release3-ec-eur-me-clean-sex --exclude release3-ec-eur-mh2-batch-significant --make-bed --out release3-ec-eur-batch
plink --bfile release3-ec-eur-batch --extract release3-ec-eur-indep.prune.in --exclude release3-ec-eur-highld.set --make-bed --out release3-ec-eur-batch-trimmed
plink --bfile release3-ec-eur-batch-trimmed --keep release3-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out release3-ec-eur-batch-trimmed-founders
./flashpca_x86-64 --bfile release3-ec-eur-batch-trimmed-founders -d 20 --outload release3-ec-eur-batch-founders-loadings.txt --outmeansd release3-ec-eur-batch-founders-meansd.txt --suffix -release3-ec-eur-batch-founders-pca.txt > release3-ec-eur-batch-founders-pca.log
./flashpca_x86-64 --bfile release3-ec-eur-batch-trimmed -d 20 --project --inmeansd release3-ec-eur-batch-founders-meansd.txt --outproj release3-ec-eur-batch-projections.txt --inload release3-ec-eur-batch-founders-loadings.txt -v > release3-ec-eur-batch-projections.log
./match.pl -f GSA-batches.txt -g release3-ec-eur-projections.txt -k 1 -l 2 -v 2 | awk '$23!="-" {print $0}' | sort -k23 | tail -n +2 > release3-ec-eur-batch-pca-batch.txt
Rscript $GITHUB/lib/anova-for-PC-vs-plates.R release3-ec-eur-batch-pca-batch.txt release3-ec-eur-batch-pca-anova-results.txt
more release3-ec-eur-batch-pca-anova-results.txt

#Basic QC #
plink --bfile release3-ec-eur-batch --maf 0.01 --make-bed --out release3-ec-eur-batch-common
plink --bfile release3-ec-eur-batch-common --geno 0.05 --make-bed --out release3-ec-eur-batch-95
plink --bfile release3-ec-eur-batch-95 --geno 0.05 --mind 0.02 --make-bed --out release3-ec-eur-batch-call-rates
plink --bfile release3-ec-eur-batch-call-rates --hwe 0.000001 --make-bed --out release3-ec-eur-batch-basic-qc

plink --bfile release3-ec-eur-batch-basic-qc --het --missing --out release3-ec-eur-batch-het-miss
Rscript $GITHUB/lib/plot-heterozygosity-common.R release3-ec-eur-batch-het-miss "Release3 EUR"
tail -n +2 release3-ec-eur-batch-het-miss-F-het-fail.txt | wc -l
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release3_freeze/Post-imputationQC/

plink --bfile release3-ec-eur-batch-basic-qc --extract release3-ec-eur-het-prune.prune.in --make-bed --out release3-ec-eur-batch-basic-qc-pruned
/cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b release3-ec-eur-batch-basic-qc-pruned.bed --related --degree 2 --rplot --prefix release3-ec-eur-batch-basic-qc-rel > release3-ec-eur-batch-basic-qc-rel.log

plink --bfile release3-ec-eur-batch-basic-qc --extract release3-ec-eur-indep.prune.in --exclude release3-ec-eur-highld.set --genome --min 0.15 --out release3-ec-eur-batch-basic-qc-ibd

