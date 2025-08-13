#cd /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
module load plink/1.90b6.2
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation
cd /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/

# Imputation report: /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/figures
# Full results before filtering on MAF & INFO: chr@.imputed.[bed,bim,fam,bgen,bim.info].
# Imputation results INFO>=0.8 and MAF>=0.01: /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/imputed.info0p8.maf0p01.[bed/bim/fam]
# INFO scores INFO>=0.8 and MAF>=0.01: /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/imputed.info0p8.maf0p01.bim.info

cp /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/imputed.info0p8.maf0p01.bed /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/
cp /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/imputed.info0p8.maf0p01.bim /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/
cp /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/imputed.info0p8.maf0p01.fam /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/
cp /cluster/projects/p697/projects/moba_qc_imputation/BA/release1_GSA/imputed.info0p8.maf0p01.bim.info /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/

# Basic QC #
plink --bfile imputed.info0p8.maf0p01 --missing --out release1-gsa-ec-eur-info-maf-missing
Rscript $GITHUB/lib/plot-missingness-histogram.R release1-gsa-ec-eur-info-maf-missing "release1-gsa EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
plink --bfile imputed.info0p8.maf0p01 --geno 0.05 --make-bed --out release1-gsa-ec-eur-95
plink --bfile release1-gsa-ec-eur-95 --geno 0.02 --make-bed --out release1-gsa-ec-eur-98 # removes an extra 276607 SNPs
awk '{print $2}' release1-gsa-ec-eur-98.bim > release1-gsa-ec-eur-98.snps
plink --bfile release1-gsa-ec-eur-95 --geno 0.05 --mind 0.02 --make-bed --out release1-gsa-ec-eur-call-rates
plink --bfile release1-gsa-ec-eur-call-rates --hwe 0.000001 --make-bed --out release1-gsa-ec-eur-basic-qc
plink --bfile release1-gsa-ec-eur-basic-qc --het --missing --out release1-gsa-ec-eur-common-het-miss
Rscript $GITHUB/lib/plot-heterozygosity-common.R release1-gsa-ec-eur-common-het-miss "release1-gsa EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
tail -n +2 release1-gsa-ec-eur-common-het-miss-F-het-fail.txt | wc -l
plink --bfile release1-gsa-ec-eur-basic-qc --remove release1-gsa-ec-eur-common-het-miss-F-het-fail.txt --make-bed --out release1-gsa-ec-eur-het

# No Duplicates #

# Pedigree build and known relatedness #
plink --bfile release1-gsa-ec-eur-het --extract release1-gsa-ec-eur-98.snps --maf 0.05 --indep-pairwise 3000 1500 0.4 --out release1-gsa-ec-eur-het-prune
plink --bfile release1-gsa-ec-eur-het --extract release1-gsa-ec-eur-het-prune.prune.in --make-bed --out release1-gsa-ec-eur-het-pruned
./match.pl -f release1-gsa-ec-eur-het.fam -g age_v12.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > release1-gsa-ec-eur-het-pruned.cov
sed -i '1 i\FID IID Age' release1-gsa-ec-eur-het-pruned.cov
/cluster/projects/p697/projects/moba_qc_imputation/software/king225_patch1 --cpus 16 -b release1-gsa-ec-eur-het-pruned.bed --related --ibs --build --degree 2 --rplot --prefix release1-gsa-ec-eur-pruned-king-1 > release1-gsa-ec-eur-pruned-king-1-slurm.txt
sh $GITHUB/tools/create-relplot.sh release1-gsa-ec-eur-pruned-king-1_relplot.R "release1-gsa EUR" topright bottomright topright bottomright
awk '{print $2, $4, $19}' release1-gsa-ec-eur-pruned-king-1.ibs0 > release1-gsa-ec-eur-pruned-king-1.ibs0_hist
Rscript $GITHUB/lib/plot-kinship-histogram.R release1-gsa-ec-eur-pruned-king-1.ibs0_hist release1-gsa-ec-eur-pruned-king-1-hist
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
awk '$16>0 {print $0}' release1-gsa-ec-eur-pruned-king-1.kin > release1-gsa-ec-eur-pruned-king-1.kin-errors
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release1-gsa-ec-eur-pruned-king-1.kin-errors -k 4 -l 2 -v 8 > release1-gsa-ec-eur-pruned-king-1.kin-errors_role1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release1-gsa-ec-eur-pruned-king-1.kin-errors_role1 -k 4 -l 3 -v 8 > release1-gsa-ec-eur-pruned-king-1.kin-errors_role2
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release1-gsa-ec-eur-pruned-king-1.kin-errors_role2 -k 4 -l 2 -v 3 > release1-gsa-ec-eur-pruned-king-1.kin-errors_FID1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree_v11.txt -g release1-gsa-ec-eur-pruned-king-1.kin-errors_FID1 -k 4 -l 3 -v 3 > release1-gsa-ec-eur-pruned-king-1.kin-errors
rm release1-gsa-ec-eur-pruned-king-1.kin-errors_role1 release1-gsa-ec-eur-pruned-king-1.kin-errors_role2 release1-gsa-ec-eur-pruned-king-1.kin-errors_FID1
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors
awk '$15=="Dup/MZ" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_MZ
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_MZ
awk '$15=="PO" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_PO
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_PO
awk '$15=="FS" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_FS
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_FS
awk '$15=="2nd" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_2nd
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_2nd
awk '$15=="3rd" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_3rd
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_3rd
awk '$15=="4th" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_4th
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_4th
awk '$15=="UN" {print $0}' release1-gsa-ec-eur-pruned-king-1.kin-errors > release1-gsa-ec-eur-pruned-king-1.kin-errors_UN
wc -l release1-gsa-ec-eur-pruned-king-1.kin-errors_UN
awk '{if ($14=="Dup/MZ" || $14=="PO" || $14=="FS") print $0}' release1-gsa-ec-eur-pruned-king-1.kin0 > release1-gsa-ec-eur-pruned-king-1.kin0-errors
wc -l release1-gsa-ec-eur-pruned-king-1.kin0-errors # 0

# Cryptic relatedness #
./cryptic.sh release1-gsa-ec-eur-pruned-king-1.ibs0 release1-gsa-ec-eur-pruned-cryptic-1
Rscript $GITHUB/lib/plot-cryptic.R release1-gsa-ec-eur-pruned-cryptic-1-kinship-sum.txt release1-gsa-ec-eur-pruned-cryptic-1-counts.txt "release1-gsa EUR" release1-gsa-pruned
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/

# LD prune #
plink --bfile release1-gsa-ec-eur-het --extract release1-gsa-ec-eur-98.snps --indep-pairwise 3000 1500 0.1 --out release1-gsa-ec-eur-indep
plink --bfile release1-gsa-ec-eur-het --extract release1-gsa-ec-eur-indep.prune.in --make-set high-ld.txt --write-set --out release1-gsa-ec-eur-highld
plink --bfile release1-gsa-ec-eur-het --extract release1-gsa-ec-eur-indep.prune.in --exclude release1-gsa-ec-eur-highld.set --make-bed --out release1-gsa-ec-eur-trimmed

# IBD #
plink --bfile release1-gsa-ec-eur-trimmed --genome --min 0.15 --out release1-gsa-ec-eur-ibd
awk '{print $5,$7,$8,$10}' release1-gsa-ec-eur-ibd.genome > release1-gsa-ec-eur-ibd.txt
Rscript $GITHUB/lib/plot-ibd.R release1-gsa-ec-eur-ibd.txt "release1-gsa EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
rm release1-gsa-ec-eur-ibd.txt
awk '$5=="PO" && $10<0.4 || $5=="PO" && $10>0.6 {print $0}' release1-gsa-ec-eur-ibd.genome > release1-gsa-ec-eur-ibd-bad-parents.txt
awk '$5=="FS" && $10<0.4 || $5=="FS" && $10>0.6 {print $0}' release1-gsa-ec-eur-ibd.genome > release1-gsa-ec-eur-ibd-bad-siblings.txt
awk '$5=="HS" && $10<0.15 || $5=="HS" && $10>0.35 {print $0}' release1-gsa-ec-eur-ibd.genome > release1-gsa-ec-eur-ibd-bad-half-siblings.txt
awk '$5!="PO" && $5!="FS" && $5!="HS" && $10>0.15 {print $0}' release1-gsa-ec-eur-ibd.genome > release1-gsa-ec-eur-ibd-bad-unrelated.txt
cat release1-gsa-ec-eur-ibd-bad-unrelated.txt release1-gsa-ec-eur-ibd-bad-parents.txt release1-gsa-ec-eur-ibd-bad-siblings.txt release1-gsa-ec-eur-ibd-bad-half-siblings.txt > release1-gsa-ec-eur-ibd-bad-relatedness.txt
rm release1-gsa-ec-eur-ibd-bad-unrelated.txt release1-gsa-ec-eur-ibd-bad-parents.txt release1-gsa-ec-eur-ibd-bad-siblings.txt release1-gsa-ec-eur-ibd-bad-half-siblings.txt
awk '{print $2,$3,$15}' release1-gsa-ec-eur-pruned-king-1.kin > release1-gsa-ec-eur-pruned-king-1.kin-RT
awk '{print $2,$4,$14}' release1-gsa-ec-eur-pruned-king-1.kin0 > release1-gsa-ec-eur-pruned-king-1.kin0-RT
cat release1-gsa-ec-eur-pruned-king-1.kin-RT release1-gsa-ec-eur-pruned-king-1.kin0-RT > release1-gsa-ec-eur-pruned-king-1.RT
rm release1-gsa-ec-eur-pruned-king-1.kin-RT release1-gsa-ec-eur-pruned-king-1.kin0-RT
R
bad <- read.table('release1-gsa-ec-eur-ibd-bad-relatedness.txt',h=T,colClasses="character")
bad_match <- subset(bad, FID1==FID2)
bad_nonmatch <- subset(bad, FID1!=FID2)
rm(bad)
kin <- read.table('release1-gsa-ec-eur-pruned-king-1.RT',h=T)
colnames(kin) <- c("IID1","IID2","InfType")
bad_kin1 <- merge(bad_match, kin, by=c("IID1", "IID2"))
bad_kin2 <- merge(bad_match, kin, by.x=c("IID1", "IID2"), by.y=c("IID2", "IID1"))
bad_kin <- rbind(bad_kin1, bad_kin2)
rm(bad_kin1, bad_kin2)
table(bad_kin$InfType)
bad_kin <- bad_kin[,c(3,1,4,2,5:15)]
write.table(bad_kin, 'release1-gsa-ec-eur-ibd-bad-relatedness.txt-InfType',row.names=F, col.names=T, sep='\t', quote=F)
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
write.table(bad_nonmatch, 'release1-gsa-ec-eur-ibd-bad-relatedness.txt-Freq',row.names=F, col.names=T, sep='\t', quote=F)
rm(bad_nonmatch)
q()
plink --bfile release1-gsa-ec-eur-het --missing --out release1-gsa-ec-eur-king-1-missing
./match.pl -f release1-gsa-ec-eur-king-1-missing.imiss -g release1-gsa-ec-eur-ibd-bad-relatedness.txt-InfType -k 2 -l 2 -v 6 > release1-gsa-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1
./match.pl -f release1-gsa-ec-eur-king-1-missing.imiss -g release1-gsa-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 -k 2 -l 4 -v 6 > release1-gsa-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate
./match.pl -f release1-gsa-ec-eur-king-1-missing.imiss -g release1-gsa-ec-eur-ibd-bad-relatedness.txt-Freq -k 2 -l 2 -v 6 > release1-gsa-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
./match.pl -f release1-gsa-ec-eur-king-1-missing.imiss -g release1-gsa-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1 -k 2 -l 4 -v 6 > release1-gsa-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate
rm release1-gsa-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 release1-gsa-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
plink --bfile release1-gsa-ec-eur-het --remove release1-gsa-ec-eur-king-1-bad-relatedness-low-call-rate.txt --make-bed --out release1-gsa-ec-eur-ibd-clean

# Mendelian errors #
plink --bfile release1-gsa-ec-eur-ibd-clean --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out release1-gsa-ec-eur-me-clean-sex

# PCA with 1000 genomes #
plink --bfile release1-gsa-ec-eur-me-clean-sex --extract release1-gsa-ec-eur-indep.prune.in --exclude release1-gsa-ec-eur-highld.set --make-bed --out release1-gsa-ec-eur-me-clean-trimmed
cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
cut -f2 release1-gsa-ec-eur-me-clean-trimmed.bim | sort -s > release1-gsa-ec-eur-me-clean-trimmed.bim.sorted
join 1kg.bim.sorted release1-gsa-ec-eur-me-clean-trimmed.bim.sorted > release1-gsa-ec-eur-me-clean-1kg-snps.txt
rm release1-gsa-ec-eur-me-clean-trimmed.bim.sorted 1kg.bim.sorted
wc -l release1-gsa-ec-eur-me-clean-1kg-snps.txt
plink --bfile release1-gsa-ec-eur-me-clean-trimmed --extract release1-gsa-ec-eur-me-clean-1kg-snps.txt --make-bed --out release1-gsa-ec-eur-1kg-common
plink --bfile 1kg --extract release1-gsa-ec-eur-me-clean-1kg-snps.txt --make-bed --out 1kg-release1-gsa-ec-eur-common
plink --bfile release1-gsa-ec-eur-1kg-common --bmerge 1kg-release1-gsa-ec-eur-common --make-bed --out release1-gsa-ec-eur-1kg-merged
plink --bfile 1kg-release1-gsa-ec-eur-common --flip release1-gsa-ec-eur-1kg-merged-merge.missnp --make-bed --out 1kg-release1-gsa-ec-eur-common-flip
plink --bfile release1-gsa-ec-eur-1kg-common --bmerge 1kg-release1-gsa-ec-eur-common-flip --make-bed --out release1-gsa-ec-eur-1kg-second-merged
plink --bfile release1-gsa-ec-eur-1kg-common --exclude release1-gsa-ec-eur-1kg-second-merged-merge.missnp --make-bed --out release1-gsa-ec-eur-1kg-common-clean
plink --bfile 1kg-release1-gsa-ec-eur-common-flip --exclude release1-gsa-ec-eur-1kg-second-merged-merge.missnp --make-bed --out 1kg-release1-gsa-ec-eur-common-flip-clean
plink --bfile release1-gsa-ec-eur-1kg-common-clean --bmerge 1kg-release1-gsa-ec-eur-common-flip-clean --make-bed --out release1-gsa-ec-eur-1kg-clean-merged
wc -l release1-gsa-ec-eur-1kg-clean-merged.bim
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' release1-gsa-ec-eur-1kg-clean-merged.fam > release1-gsa-ec-eur-1kg-clean-merged-populations.txt
awk '$3=="parent" {print $0}' release1-gsa-ec-eur-1kg-clean-merged-populations.txt > release1-gsa-ec-eur-1kg-merged-founders
plink --bfile release1-gsa-ec-eur-1kg-clean-merged --keep release1-gsa-ec-eur-1kg-merged-founders --keep-allele-order --make-bed --out release1-gsa-ec-eur-1kg-clean-merged-founders
./flashpca_x86-64 --bfile release1-gsa-ec-eur-1kg-clean-merged-founders -d 20 --outload release1-gsa-ec-eur-1kg-founders-loadings.txt --outmeansd release1-gsa-ec-eur-1kg-founders-meansd.txt --suffix -release1-gsa-ec-eur-1kg-founders-pca.txt > release1-gsa-ec-eur-1kg-founders-pca.log
./flashpca_x86-64 --bfile release1-gsa-ec-eur-1kg-clean-merged -d 20 --project --inmeansd release1-gsa-ec-eur-1kg-founders-meansd.txt --outproj release1-gsa-ec-eur-1kg-projections.txt --inload release1-gsa-ec-eur-1kg-founders-loadings.txt -v > release1-gsa-ec-eur-1kg-projections.log
tail -n +2 release1-gsa-ec-eur-1kg-projections.txt | sort -k2 > release1-gsa-ec-eur-1kg-projections.txt-sorted
head -n 33853 release1-gsa-ec-eur-1kg-projections.txt-sorted > release1-gsa-ec-eur-pca
tail -n 1083 release1-gsa-ec-eur-1kg-projections.txt-sorted | sort -k2 > 1kg-ec-eur-fin-pca
cat release1-gsa-ec-eur-pca 1kg-ec-eur-fin-pca > release1-gsa-ec-eur-1kg-pca
Rscript $GITHUB/lib/plot-pca-with-1kg.R release1-gsa release1-gsa-ec-eur-1kg-pca bottomleft release1-gsa-ec-eur-1kg
Rscript $GITHUB/lib/select-subsamples-on-pca.R release1-gsa release1-gsa-ec-eur-1kg-pca release1-gsa-ec-eur-selection release1-gsa-ec-eur-pca-core-select-custom.txt
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/

# PCA #
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' release1-gsa-ec-eur-me-clean-trimmed.fam > release1-gsa-ec-eur-me-clean-trimmed-populations.txt
awk '$3=="parent" {print $0}' release1-gsa-ec-eur-me-clean-trimmed-populations.txt > release1-gsa-ec-eur-me-clean-trimmed-founders
plink --bfile release1-gsa-ec-eur-me-clean-trimmed --keep release1-gsa-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out release1-gsa-ec-eur-me-clean-trimmed-founders
./flashpca_x86-64 --bfile release1-gsa-ec-eur-me-clean-trimmed-founders -d 20 --outload release1-gsa-ec-eur-founders-loadings.txt --outmeansd release1-gsa-ec-eur-founders-meansd.txt --suffix -release1-gsa-ec-eur-founders-pca.txt > release1-gsa-ec-eur-founders-pca.log
./flashpca_x86-64 --bfile release1-gsa-ec-eur-me-clean-trimmed -d 20 --project --inmeansd release1-gsa-ec-eur-founders-meansd.txt --outproj release1-gsa-ec-eur-projections.txt --inload release1-gsa-ec-eur-founders-loadings.txt -v > release1-gsa-ec-eur-projections.log
awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red"}' release1-gsa-ec-eur-me-clean-trimmed.fam > release1-gsa-ec-eur-me-clean-trimmed-fam.txt
./match.pl -f release1-gsa-ec-eur-me-clean-trimmed-fam.txt -g release1-gsa-ec-eur-projections.txt -k 2 -l 2 -v 3 > release1-gsa-ec-eur-pca-fam.txt
tail -n +2 release1-gsa-ec-eur-pca-fam.txt > release1-gsa-ec-eur-pca-fam.txt_noheader
Rscript $GITHUB/lib/plot-batch-PCs.R release1-gsa-ec-eur-pca-fam.txt_noheader "release1-gsa EUR" topleft release1-gsa-ec-eur-pca.png
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/

# Batch effects #
./match.pl -f GSA-batches.txt -g release1-gsa-ec-eur-projections.txt -k 1 -l 2 -v 2 | awk '$23!="-" {print $0}' | sort -k23 | tail -n +2 > release1-gsa-ec-eur-pca-batch.txt
awk '{print $1,$2,$23}' release1-gsa-ec-eur-pca-batch.txt > release1-gsa-ec-eur-batch-groups.txt
Rscript $GITHUB/lib/plot-PC-by-batch.R release1-gsa-ec-eur-pca-batch.txt "release1-gsa EUR" release1-gsa-ec-eur
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
Rscript $GITHUB/lib/anova-for-PC-vs-plates.R release1-gsa-ec-eur-pca-batch.txt release1-gsa-ec-eur-pca-anova-results.txt
more release1-gsa-ec-eur-pca-anova-results.txt
plink --bfile release1-gsa-ec-eur-me-clean-sex --filter-founders --chr 1-22 --pheno release1-gsa-ec-eur-me-clean-sex.fam --mpheno 3 --within release1-gsa-ec-eur-batch-groups.txt --mh2 --out release1-gsa-ec-eur-mh-batch
Rscript $GITHUB/lib/plot-qqplot.R release1-gsa-ec-eur-mh-batch.cmh2 "release1-gsa EUR" 5 release1-gsa-ec-eur-mh-batch-test-qq-plot
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/Release1_freeze/GSA/Post-imputationQC/
sort -k5 -g release1-gsa-ec-eur-mh-batch.cmh2 | grep -v "NA" > release1-gsa-ec-eur-mh2-batch-sorted
awk '$5<0.00000005 {print $2}' release1-gsa-ec-eur-mh2-batch-sorted > release1-gsa-ec-eur-mh2-batch-significant
wc -l release1-gsa-ec-eur-mh2-batch-significant
plink --bfile release1-gsa-ec-eur-me-clean-sex --exclude release1-gsa-ec-eur-mh2-batch-significant --make-bed --out release1-gsa-ec-eur-batch
plink --bfile release1-gsa-ec-eur-batch --extract release1-gsa-ec-eur-indep.prune.in --exclude release1-gsa-ec-eur-highld.set --make-bed --out release1-gsa-ec-eur-batch-trimmed
plink --bfile release1-gsa-ec-eur-batch-trimmed --keep release1-gsa-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out release1-gsa-ec-eur-batch-trimmed-founders
./flashpca_x86-64 --bfile release1-gsa-ec-eur-batch-trimmed-founders -d 20 --outload release1-gsa-ec-eur-batch-founders-loadings.txt --outmeansd release1-gsa-ec-eur-batch-founders-meansd.txt --suffix -release1-gsa-ec-eur-batch-founders-pca.txt > release1-gsa-ec-eur-batch-founders-pca.log
./flashpca_x86-64 --bfile release1-gsa-ec-eur-batch-trimmed -d 20 --project --inmeansd release1-gsa-ec-eur-batch-founders-meansd.txt --outproj release1-gsa-ec-eur-batch-projections.txt --inload release1-gsa-ec-eur-batch-founders-loadings.txt -v > release1-gsa-ec-eur-batch-projections.log
./match.pl -f GSA-batches.txt -g release1-gsa-ec-eur-batch-projections.txt -k 1 -l 2 -v 2 | awk '$23!="-" {print $0}' | sort -k23 | tail -n +2 > release1-gsa-ec-eur-batch-pca-batch.txt
Rscript $GITHUB/lib/anova-for-PC-vs-plates.R release1-gsa-ec-eur-batch-pca-batch.txt release1-gsa-ec-eur-batch-pca-anova-results.txt
more release1-gsa-ec-eur-batch-pca-anova-results.txt

#Basic QC #
plink --bfile release1-gsa-ec-eur-batch --maf 0.01 --make-bed --out release1-gsa-ec-eur-batch-common
plink --bfile release1-gsa-ec-eur-batch-common --geno 0.05 --make-bed --out release1-gsa-ec-eur-batch-95
plink --bfile release1-gsa-ec-eur-batch-95 --geno 0.05 --mind 0.02 --make-bed --out release1-gsa-ec-eur-batch-call-rates
plink --bfile release1-gsa-ec-eur-batch-call-rates --hwe 0.000001 --make-bed --out release1-gsa-ec-eur-batch-basic-qc

#plink --bfile release1-gsa-ec-eur-batch-basic-qc --extract release1-gsa-ec-eur-het-prune.prune.in --make-bed --out release1-gsa-ec-eur-batch-basic-qc-pruned
#/cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b release1-gsa-ec-eur-batch-basic-qc-pruned.bed --related --degree 2 --rplot --prefix release1-gsa-ec-eur-batch-basic-qc-rel > release1-gsa-ec-eur-batch-basic-qc-rel.log

#plink --bfile release1-gsa-ec-eur-batch-basic-qc --extract release1-gsa-ec-eur-indep.prune.in --exclude release1-gsa-ec-eur-highld.set --genome --min 0.15 --out release1-gsa-ec-eur-batch-basic-qc-ibd
