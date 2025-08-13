#cd /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
module load plink/1.90b6.2
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation
cd /cluster/projects/p697/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

## Merge Releases ##

# MoBaPsychGen_v1_snps.R
# MoBaPsychGen_v1_king-moba-families.R

plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/HCE/release1-hce-ec-eur-batch-basic-qc --update-ids MoBaPsychGen_v1-king_updateids.txt --make-just-fam --out release1-hce-ec-eur-MoBaPsychGen_v1-ids
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/HCE/release1-hce-ec-eur-batch-basic-qc --fam release1-hce-ec-eur-MoBaPsychGen_v1-ids.fam --update-parents MoBaPsychGen_v1-king_updateparents.txt --extract MoBaPsychGen_v1_snps.txt --make-bed --out release1-hce-ec-eur-MoBaPsychGen_v1
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/OMNI/release1-omni-ec-eur-batch-basic-qc --update-ids MoBaPsychGen_v1-king_updateids.txt --make-just-fam --out release1-omni-ec-eur-MoBaPsychGen_v1-ids
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/OMNI/release1-omni-ec-eur-batch-basic-qc --fam release1-omni-ec-eur-MoBaPsychGen_v1-ids.fam --update-parents MoBaPsychGen_v1-king_updateparents.txt --extract MoBaPsychGen_v1_snps.txt --make-bed --out release1-omni-ec-eur-MoBaPsychGen_v1
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/release1-gsa-ec-eur-batch-basic-qc --update-ids MoBaPsychGen_v1-king_updateids.txt --make-just-fam --out release1-gsa-ec-eur-MoBaPsychGen_v1-ids
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release1/GSA/release1-gsa-ec-eur-batch-basic-qc --fam release1-gsa-ec-eur-MoBaPsychGen_v1-ids.fam --update-parents MoBaPsychGen_v1-king_updateparents.txt --extract MoBaPsychGen_v1_snps.txt --make-bed --out release1-gsa-ec-eur-MoBaPsychGen_v1
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release2/release2-ec-eur-batch-basic-qc --update-ids MoBaPsychGen_v1-king_updateids.txt --make-just-fam --out release2-ec-eur-MoBaPsychGen_v1-ids
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release2/release2-ec-eur-batch-basic-qc --fam release2-ec-eur-MoBaPsychGen_v1-ids.fam --update-parents MoBaPsychGen_v1-king_updateparents.txt --extract MoBaPsychGen_v1_snps.txt --make-bed --out release2-ec-eur-MoBaPsychGen_v1
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3/release3-ec-eur-batch-basic-qc --update-ids MoBaPsychGen_v1-king_updateids.txt --make-just-fam --out release3-ec-eur-MoBaPsychGen_v1-ids
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release3/release3-ec-eur-batch-basic-qc --fam release3-ec-eur-MoBaPsychGen_v1-ids.fam --update-parents MoBaPsychGen_v1-king_updateparents.txt --extract MoBaPsychGen_v1_snps.txt --make-bed --out release3-ec-eur-MoBaPsychGen_v1
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release4/release4-ec-eur-batch-basic-qc --update-ids MoBaPsychGen_v1-king_updateids.txt --make-just-fam --out release4-ec-eur-MoBaPsychGen_v1-ids
plink --bfile /cluster/projects/p697/projects/moba_qc_imputation/EC/Release4/release4-ec-eur-batch-basic-qc --fam release4-ec-eur-MoBaPsychGen_v1-ids.fam --update-parents MoBaPsychGen_v1-king_updateparents.txt --extract MoBaPsychGen_v1_snps.txt --make-bed --out release4-ec-eur-MoBaPsychGen_v1

cat > MoBaPsychGen_v1_merge-list
release1-hce-ec-eur-MoBaPsychGen_v1
release1-omni-ec-eur-MoBaPsychGen_v1
release1-gsa-ec-eur-MoBaPsychGen_v1
release2-ec-eur-MoBaPsychGen_v1
release3-ec-eur-MoBaPsychGen_v1
release4-ec-eur-MoBaPsychGen_v1
<Control D>

plink --merge-list MoBaPsychGen_v1_merge-list --make-bed --out MoBaPsychGen_v1-ec-eur

# Basic QC #
plink --bfile MoBaPsychGen_v1-ec-eur --maf 0.01 --make-bed --out MoBaPsychGen_v1-ec-eur-common
plink --bfile MoBaPsychGen_v1-ec-eur-common --missing --out MoBaPsychGen_v1-ec-eur-info-maf-missing
Rscript $GITHUB/lib/plot-missingness-histogram.R MoBaPsychGen_v1-ec-eur-info-maf-missing "MoBaPsychGen_v1 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
plink --bfile MoBaPsychGen_v1-ec-eur-common --geno 0.05 --make-bed --out MoBaPsychGen_v1-ec-eur-95
plink --bfile MoBaPsychGen_v1-ec-eur-95 --geno 0.02 --make-just-bim --out MoBaPsychGen_v1-ec-eur-98 # removes an extra 127664 SNPs
awk '{print $2}' MoBaPsychGen_v1-ec-eur-98.bim > MoBaPsychGen_v1-ec-eur-98.snps
plink --bfile MoBaPsychGen_v1-ec-eur-95 --geno 0.05 --mind 0.02 --make-bed --out MoBaPsychGen_v1-ec-eur-call-rates
plink --bfile MoBaPsychGen_v1-ec-eur-call-rates --hwe 0.000001 --make-bed --out MoBaPsychGen_v1-ec-eur-basic-qc
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --het --missing --out MoBaPsychGen_v1-ec-eur-common-het-miss
Rscript $GITHUB/lib/plot-heterozygosity-common.R MoBaPsychGen_v1-ec-eur-common-het-miss "MoBaPsychGen_v1 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
tail -n +2 MoBaPsychGen_v1-ec-eur-common-het-miss-F-het-fail.txt | wc -l

# Duplicates #
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --extract MoBaPsychGen_v1-ec-eur-98.snps --indep-pairwise 3000 1500 0.1 --out MoBaPsychGen_v1-ec-eur-prune
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --extract MoBaPsychGen_v1-ec-eur-prune.prune.in --keep MoBaPsychGen_v1_duplicates.txt --genome --out MoBaPsychGen_v1-ec-eur-ibd
awk '$10>=0.95 {print $0}' MoBaPsychGen_v1-ec-eur-ibd.genome > MoBaPsychGen_v1-ec-eur-good-dup.txt
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --keep MoBaPsychGen_v1-ec-eur-good-dup-1.txt --make-bed --out MoBaPsychGen_v1-ec-eur-good-dup-1
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --keep MoBaPsychGen_v1-ec-eur-good-dup-2.txt --make-bed --out MoBaPsychGen_v1-ec-eur-good-dup-2
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --keep MoBaPsychGen_v1-ec-eur-good-dup-3.txt --make-bed --out MoBaPsychGen_v1-ec-eur-good-dup-3
wc -l MoBaPsychGen_v1-ec-eur-good-dup-1.fam
wc -l MoBaPsychGen_v1-ec-eur-good-dup-2.fam
wc -l MoBaPsychGen_v1-ec-eur-good-dup-3.fam
plink --bfile MoBaPsychGen_v1-ec-eur-good-dup-2 --update-ids MoBaPsychGen_v1-ec-eur-good-dup-id.txt --make-bed --out MoBaPsychGen_v1-ec-eur-good-dup-id
plink --bfile MoBaPsychGen_v1-ec-eur-good-dup-3 --update-ids MoBaPsychGen_v1-ec-eur-good-trip1-id.txt --make-bed --out MoBaPsychGen_v1-ec-eur-good-trip1-id
plink --bfile MoBaPsychGen_v1-ec-eur-good-dup-3 --update-ids MoBaPsychGen_v1-ec-eur-good-trip2-id.txt --make-bed --out MoBaPsychGen_v1-ec-eur-good-trip2-id
plink --bfile MoBaPsychGen_v1-ec-eur-good-dup-1 --bmerge MoBaPsychGen_v1-ec-eur-good-dup-id --merge-mode 7 --out MoBaPsychGen_v1-ec-eur-dup-check
plink --bfile MoBaPsychGen_v1-ec-eur-good-dup-1 --bmerge MoBaPsychGen_v1-ec-eur-good-trip1-id --merge-mode 7 --out MoBaPsychGen_v1-ec-eur-trip1-check
plink --bfile MoBaPsychGen_v1-ec-eur-good-dup-2 --bmerge MoBaPsychGen_v1-ec-eur-good-trip2-id --merge-mode 7 --out MoBaPsychGen_v1-ec-eur-trip2-check
cat MoBaPsychGen_v1-ec-eur-dup-check.diff MoBaPsychGen_v1-ec-eur-trip1-check.diff MoBaPsychGen_v1-ec-eur-trip2-check.diff > MoBaPsychGen_v1-ec-eur-trip-check.diff
awk '{print $1}' MoBaPsychGen_v1-ec-eur-trip-check.diff | sort | uniq -c | awk '{print $1/2855,$2}'| awk '$1>=0.03 {print $2}' > MoBaPsychGen_v1-ec-eur-dup-snps-to-remove.txt
wc -l MoBaPsychGen_v1-ec-eur-dup-snps-to-remove.txt
plink --bfile MoBaPsychGen_v1-ec-eur-basic-qc --exclude MoBaPsychGen_v1-ec-eur-dup-snps-to-remove.txt --make-bed --out MoBaPsychGen_v1-ec-eur-dup-clean
plink --bfile MoBaPsychGen_v1-ec-eur-dup-clean --missing --out MoBaPsychGen_v1-ec-eur-dup-clean-miss
./match.pl -f MoBaPsychGen_v1-ec-eur-dup-clean-miss.imiss -g duplicates_wide.txt -k 2 -l 1 -v 6 > MoBaPsychGen_v1-ec-eur-dup-miss1
./match.pl -f MoBaPsychGen_v1-ec-eur-dup-clean-miss.imiss -g MoBaPsychGen_v1-ec-eur-dup-miss1 -k 2 -l 2 -v 6 > MoBaPsychGen_v1-ec-eur-dup-miss2
./match.pl -f MoBaPsychGen_v1-ec-eur-dup-clean-miss.imiss -g MoBaPsychGen_v1-ec-eur-dup-miss2 -k 2 -l 3 -v 6 > MoBaPsychGen_v1-ec-eur-dup-miss3
rm MoBaPsychGen_v1-ec-eur-dup-miss1
rm MoBaPsychGen_v1-ec-eur-dup-miss2
awk '$6=="-" && $4!="-" && $5!="-" {print $0}' MoBaPsychGen_v1-ec-eur-dup-miss3 | awk '{if($4>$5) print $1; else print $2}' > MoBaPsychGen_v1-ec-eur-max
awk '$5=="-" && $4!="-" && $6!="-" {print $0}' MoBaPsychGen_v1-ec-eur-dup-miss3 | awk '{if($4>$6) print $1; else print $3}' >> MoBaPsychGen_v1-ec-eur-max
awk '$4=="-" && $5!="-" && $6!="-" {print $0}' MoBaPsychGen_v1-ec-eur-dup-miss3 | awk '{if($5>$6) print $2; else print $3}' >> MoBaPsychGen_v1-ec-eur-max
awk '$4!="-" && $5!="-" && $6!="-" {print $0}' MoBaPsychGen_v1-ec-eur-dup-miss3 | awk '{if($4<=$5 && $4<=$6) print $2"\n"$3; else if($5<=$4 && $5<=$6) print $1"\n"$3; else print $1"\n"$2}' >> MoBaPsychGen_v1-ec-eur-max
./match.pl -f MoBaPsychGen_v1-ec-eur-max -g duplicates.txt -k 1 -l 2 -v 1 | awk '$3!="-" {print $1,$2}' > MoBaPsychGen_v1-ec-eur-multi-bad
./match.pl -f MoBaPsychGen_v1-ec-eur-dup-clean.fam -g MoBaPsychGen_v1-ec-eur-multi-bad -k 2 -l 2 -v 1 | awk '{print $3, $2}' > MoBaPsychGen_v1-ec-eur-multi-bad.ind
# update parental ids so that the duplicate who is kept is listed as the parent #
R
dup <- read.table('MoBaPsychGen_v1-ec-eur-good-dup.txt',h=T)
dup <- dup[,c(1:4)]
removed <- read.table('MoBaPsychGen_v1-ec-eur-multi-bad.ind',h=F)
colnames(removed) <- c("FID1","IID1")
rd1 <- merge(dup, removed, by=c("FID1","IID1"))
colnames(rd1) <- c("Removed_FID", "Removed_IID", "Kept_FID", "Kept_IID", "order")
colnames(removed) <- c("FID2","IID2")
rd2 <- merge(dup, removed, by=c("FID2","IID2"))
colnames(rd2) <- c("Removed_FID", "Removed_IID", "Kept_FID", "Kept_IID", "order")
keptids <- rbind(rd1, rd2)
freq <- data.frame(table(keptids$order))
colnames(freq) <- c("order", "Freq")
keptids_freq <- merge(keptids, freq, by="order")
table(keptids_freq$Freq) # 1=2839, 2=32
keptids_1 <- subset(keptids_freq, Freq==1)
keptids_2 <- subset(keptids_freq, Freq==2) # triplicates that have been removed
keptids <- keptids_1[,c(4:5,2:3)]
write.table(keptids, 'MoBaPsychGen_v1-ec-eur-multi-bad-kept_ids.txt', quote=F, row.names=F, col.names=T, sep='\t')
rm(rd1, rd2, dup, removed, keptids, freq, keptids_freq, keptids_1, keptids_2)
fam <- read.table('MoBaPsychGen_v1-ec-eur-dup-clean.fam',h=F)
fam <- fam[,c(1:4)]
colnames(fam) <- c("FID","IID","PID","MID")
dup <- read.table('MoBaPsychGen_v1-ec-eur-multi-bad-kept_ids.txt',h=T)
dup <- dup[,c(2,4)]
colnames(dup) <- c("Kept_PID","Removed_PID")
dup$update_PID <- 1
pid <- merge(dup, fam, by.x="Removed_PID", by.y="PID", all.y=T)
colnames(dup) <- c("Kept_MID","Removed_MID","update_MID")
fam <- merge(dup, pid, by.x="Removed_MID", by.y="MID", all.y=T)
pid <- subset(fam, update_PID==1 & is.na(fam$update_MID))
mid <- subset(fam, is.na(fam$update_PID) & update_MID==1)
pid_mid <- subset(fam, update_PID==1 & update_MID==1)
rm(dup, fam)
pid <- pid[,c(7:8,5,1)]
colnames(pid) <- c("FID","IID","PID","MID")
mid <- mid[,c(7:8,4,2)]
colnames(mid) <- c("FID","IID","PID","MID")
pid_mid <- pid_mid[,c(7:8,5,2)]
colnames(pid_mid) <- c("FID","IID","PID","MID")
update_parents <- rbind(pid, mid, pid_mid)
rm(pid, mid, pid_mid)
write.table(update_parents, 'MoBaPsychGen_v1-ec-eur-multi-bad-update_parents.txt', quote=F, row.names=F, col.names=F, sep='\t')
q()
plink --bfile MoBaPsychGen_v1-ec-eur-dup-clean --remove MoBaPsychGen_v1-ec-eur-multi-bad.ind --update-parents MoBaPsychGen_v1-ec-eur-multi-bad-update_parents.txt --make-bed --out MoBaPsychGen_v1-ec-eur-multi-clean

# Pedigree build and known relatedness #
plink --bfile MoBaPsychGen_v1-ec-eur-multi-clean --extract MoBaPsychGen_v1-ec-eur-98.snps --maf 0.05 --indep-pairwise 3000 1500 0.4 --out MoBaPsychGen_v1-ec-eur-multi-clean-prune
plink --bfile MoBaPsychGen_v1-ec-eur-multi-clean --extract MoBaPsychGen_v1-ec-eur-multi-clean-prune.prune.in --make-bed --out MoBaPsychGen_v1-ec-eur-multi-clean-pruned
./match.pl -f MoBaPsychGen_v1-ec-eur-multi-clean.fam -g age_v12.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > MoBaPsychGen_v1-ec-eur-multi-clean-pruned.cov
sed -i '1 i\FID IID Age' MoBaPsychGen_v1-ec-eur-multi-clean-pruned.cov
/cluster/projects/p697/projects/moba_qc_imputation/software/king225_patch1 --cpus 16 -b MoBaPsychGen_v1-ec-eur-multi-clean-pruned.bed --related --build --degree 2 --rplot --prefix MoBaPsychGen_v1-ec-eur-pruned-king-1 > MoBaPsychGen_v1-ec-eur-pruned-king-1-slurm.txt
sh $GITHUB/tools/create-relplot.sh MoBaPsychGen_v1-ec-eur-pruned-king-1_relplot.R "MoBaPsychGen_v1 EUR" topright bottomright topright bottomright
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
awk '{print $1,$2,$3,$2}' MoBaPsychGen_v1-ec-eur-pruned-king-1updateids.txt > MoBaPsychGen_v1-ec-eur-king-1updateids.txt-sentrix
R
library(tidyr)
update <- read.table('MoBaPsychGen_v1-ec-eur-pruned-king-1updateparents.txt',h=F)
update$Order <- 1:nrow(update)
update_IID <- update[grep("->", update$V2),]
no_update_IID <- update[!update$Order %in% update_IID$Order,]
update_IID <- separate(update_IID, V2, into=c(NA,"V2"), sep="->", remove=T)
update_IID <- update_IID[,c(1,3:9)]
update <- rbind(update_IID, no_update_IID)
rm(update_IID, no_update_IID)
update_PID <- update[grep("->", update$V3),]
no_update_PID <- update[!update$Order %in% update_PID$Order,]
update_PID <- separate(update_PID, V3, into=c(NA,"V3"), sep="->", remove=T)
update_PID <- update_PID[,c(1:2,4:9)]
update <- rbind(update_PID, no_update_PID)
rm(update_PID, no_update_PID)
update_MID <- update[grep("->", update$V4),]
no_update_MID <- update[!update$Order %in% update_MID$Order,]
update_MID <- separate(update_MID, V4, into=c(NA,"V4"), sep="->", remove=T)
update_MID <- update_MID[,c(1:3,5:9)]
update <- rbind(update_MID, no_update_MID)
rm(update_MID, no_update_MID)
update <- update[,c(1:7)]
write.table(update, 'MoBaPsychGen_v1-ec-eur-king-1updateparents.txt-sentrix', row.names=F, col.names=F, sep='\t', quote=F)
q()
plink --bfile MoBaPsychGen_v1-ec-eur-multi-clean --update-ids MoBaPsychGen_v1-ec-eur-king-1updateids.txt-sentrix --make-just-fam --out MoBaPsychGen_v1-ec-eur-king-1-ids
plink --bfile MoBaPsychGen_v1-ec-eur-multi-clean --fam MoBaPsychGen_v1-ec-eur-king-1-ids.fam --update-parents MoBaPsychGen_v1-ec-eur-king-1updateparents.txt-sentrix --make-just-fam --out MoBaPsychGen_v1-ec-eur-king-1-parents

./match.pl -f yob_v12.txt -g MoBaPsychGen_v1-ec-eur-king-1-parents.fam -k 2 -l 2 -v 3 > MoBaPsychGen_v1-ec-eur-king-1-children-yob_v12.txt
./match.pl -f yob_v12.txt -g MoBaPsychGen_v1-ec-eur-king-1-children-yob_v12.txt -k 2 -l 3 -v 3 > MoBaPsychGen_v1-ec-eur-king-1-children-fathers-yob_v12.txt
./match.pl -f yob_v12.txt -g MoBaPsychGen_v1-ec-eur-king-1-children-fathers-yob_v12.txt -k 2 -l 4 -v 3 > MoBaPsychGen_v1-ec-eur-king-1-yob_v12.txt
rm MoBaPsychGen_v1-ec-eur-king-1-children-yob_v12.txt MoBaPsychGen_v1-ec-eur-king-1-children-fathers-yob_v12.txt
awk '{if ($7<$8 || $7<$9) print $0, "PROBLEM"; else print $0, "OK"}' MoBaPsychGen_v1-ec-eur-king-1-yob_v12.txt > MoBaPsychGen_v1-ec-eur-king-1-yob-check.txt
awk '$10=="PROBLEM" {print $0}' MoBaPsychGen_v1-ec-eur-king-1-yob-check.txt > MoBaPsychGen_v1-ec-eur-king-1-yob-problem.txt
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-parents.fam -g MoBaPsychGen_v1-ec-eur-king-1-parents.fam -k 2 -l 3 -v 5 > MoBaPsychGen_v1-ec-eur-king-1-father-sex.txt
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-parents.fam -g MoBaPsychGen_v1-ec-eur-king-1-father-sex.txt -k 2 -l 4 -v 5 > MoBaPsychGen_v1-ec-eur-king-1-sex.txt
rm MoBaPsychGen_v1-ec-eur-king-1-father-sex.txt
awk '{if ($7==2 || $8==1) print $0, "PROBLEM"; else print $0, "OK"}' MoBaPsychGen_v1-ec-eur-king-1-sex.txt > MoBaPsychGen_v1-ec-eur-king-1-sex-check.txt
awk '$10=="PROBLEM" {print $0}' MoBaPsychGen_v1-ec-eur-king-1-sex-check.txt > MoBaPsychGen_v1-ec-eur-king-1-sex-problem.txt
wc -l MoBaPsychGen_v1-ec-eur-king-1-yob-problem.txt
wc -l MoBaPsychGen_v1-ec-eur-king-1-sex-problem.txt

awk '$16>0 {print $0}' MoBaPsychGen_v1-ec-eur-pruned-king-1.kin > MoBaPsychGen_v1-ec-eur-king-1.kin-errors
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree.txt -g MoBaPsychGen_v1-ec-eur-king-1.kin-errors -k 4 -l 2 -v 8 > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-role1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree.txt -g  MoBaPsychGen_v1-ec-eur-king-1.kin-errors-role1 -k 4 -l 3 -v 8 > MoBaPsychGen_v1-ec-eur-king-1.kin-errors
rm  MoBaPsychGen_v1-ec-eur-king-1.kin-errors-role1
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors
awk '$15=="Dup/MZ" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-MZ
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-MZ
awk '$15=="PO" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-PO
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-PO
awk '$15=="FS" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-FS
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-FS
awk '$15=="2nd" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-2nd
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-2nd
awk '$6==0.25 {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors-2nd > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-2nd_expected-1st
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-2nd_expected-1st
awk '$15=="3rd" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-3rd
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-3rd
awk '$15=="4th" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-4th
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-4th
awk '$15=="UN" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin-errors > MoBaPsychGen_v1-ec-eur-king-1.kin-errors-UN
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin-errors-UN

awk '{if ($14=="Dup/MZ" || $14=="PO" || $14=="FS") print $0}' MoBaPsychGen_v1-ec-eur-pruned-king-1.kin0 > MoBaPsychGen_v1-ec-eur-king-1.kin0-errors
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree.txt -g MoBaPsychGen_v1-ec-eur-king-1.kin0-errors -k 4 -l 2 -v 8 > MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-role1
./match.pl -f /tsd/p697/data/durable/projects/moba_qc_imputation/resources/genotyped_pedigree.txt -g  MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-role1 -k 4 -l 4 -v 8 > MoBaPsychGen_v1-ec-eur-king-1.kin0-errors
rm  MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-role1
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin0-errors
awk '$14=="Dup/MZ" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin0-errors > MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-MZ
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-MZ
awk '$14=="PO" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin0-errors > MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-PO
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-PO
awk '$14=="FS" {print $0}' MoBaPsychGen_v1-ec-eur-king-1.kin0-errors > MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-FS
wc -l MoBaPsychGen_v1-ec-eur-king-1.kin0-errors-FS

plink --bfile MoBaPsychGen_v1-ec-eur-multi-clean --fam MoBaPsychGen_v1-ec-eur-king-1-parents.fam --remove MoBaPsychGen_v1-ec-eur-king-1-unexpected-relationships.txt --update-ids MoBaPsychGen_v1-ec-eur-king-1-fix-ids.txt --make-bed --out MoBaPsychGen_v1-ec-eur-king-1-fix-ids
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-fix-ids.fam -g /tsd/p697/data/durable/projects/moba_qc_imputation/resources/unlinkable_IDs_v12.txt -k 2 -l 2 -v 1 | awk '$3!="-" {print $3, $2}' > unlinkable_IDs_v12.txt
plink --bfile MoBaPsychGen_v1-ec-eur-king-1-fix-ids --remove unlinkable_IDs_v12.txt --update-parents MoBaPsychGen_v1-ec-eur-king-1-fix-parents.txt --make-bed --out MoBaPsychGen_v1-ec-eur-king-1-fix-parents

plink --bfile MoBaPsychGen_v1-ec-eur-king-1-fix-parents --extract MoBaPsychGen_v1-ec-eur-multi-clean-prune.prune.in --make-bed --out MoBaPsychGen_v1-ec-eur-king-1-fix-parents-pruned
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-fix-parents.fam -g age_v12.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > MoBaPsychGen_v1-ec-eur-king-1-fix-parents-pruned.cov
sed -i '1 i FID IID Age' MoBaPsychGen_v1-ec-eur-king-1-fix-parents-pruned.cov
/cluster/projects/p697/projects/moba_qc_imputation/software/king225 --cpus 16 -b MoBaPsychGen_v1-ec-eur-king-1-fix-parents-pruned.bed --related --build --degree 2 --rplot --prefix MoBaPsychGen_v1-ec-eur-king-1.25 > MoBaPsychGen_v1-ec-eur-king-1.25-slurm.txt
sh $GITHUB/tools/create-relplot.sh MoBaPsychGen_v1-ec-eur-king-1.25_relplot.R "MoBaPsychGen_v1 EUR" topright bottomright topright bottomright
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

plink --bfile MoBaPsychGen_v1-ec-eur-king-1-fix-parents --remove MoBaPsychGen_v1-ec-eur-king-1.25-unexpected-relationships.txt --update-ids MoBaPsychGen_v1-ec-eur-king-1.25-fix-ids.txt --make-bed --out MoBaPsychGen_v1-ec-eur-king-1.25-fix-ids
plink --bfile MoBaPsychGen_v1-ec-eur-king-1.25-fix-ids --update-parents MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents.txt --make-bed --out MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents

plink --bfile MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents --extract MoBaPsychGen_v1-ec-eur-multi-clean-prune.prune.in --make-bed --out MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents-pruned
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents.fam -g age_v12.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents-pruned.cov
sed -i '1 i FID IID Age' MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents-pruned.cov
/cluster/projects/p697/projects/moba_qc_imputation/software/king225 --cpus 16 -b MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents-pruned.bed --related --build --degree 2 --rplot --prefix MoBaPsychGen_v1-ec-eur-king-1.5 > MoBaPsychGen_v1-ec-eur-king-1.5-slurm.txt
sh $GITHUB/tools/create-relplot.sh MoBaPsychGen_v1-ec-eur-king-1.5_relplot.R "MoBaPsychGen_v1 EUR" topright bottomright topright bottomright
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

plink --bfile MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents --update-ids MoBaPsychGen_v1-ec-eur-king-1.5-fix-ids.txt --make-just-fam --out MoBaPsychGen_v1-ec-eur-king-1.5-fix-ids
plink --bfile MoBaPsychGen_v1-ec-eur-king-1.25-fix-parents --fam MoBaPsychGen_v1-ec-eur-king-1.5-fix-ids.fam --update-parents MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents.txt --make-bed --out MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents

plink --bfile MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents --extract MoBaPsychGen_v1-ec-eur-multi-clean-prune.prune.in --make-bed --out MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents-pruned
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents.fam -g age_v12.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents-pruned.cov
sed -i '1 i FID IID Age' MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents-pruned.cov
/cluster/projects/p697/projects/moba_qc_imputation/software/king225 --cpus 16 -b MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents-pruned.bed --related --build --degree 2 --rplot --prefix MoBaPsychGen_v1-ec-eur-king-1.75 > MoBaPsychGen_v1-ec-eur-king-1.75-slurm.txt
sh $GITHUB/tools/create-relplot.sh MoBaPsychGen_v1-ec-eur-king-1.75_relplot.R "MoBaPsychGen_v1 EUR" topright bottomright topright bottomright
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

# Cryptic relatedness #
/cluster/projects/p697/projects/moba_qc_imputation/software/king225_patch1 --cpus 16 -b MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents-pruned.bed --ibs --prefix MoBaPsychGen_v1-ec-eur-king-ibs > MoBaPsychGen_v1-ec-eur-king-ibs-slurm.txt
awk '{print $2, $4, $19}' MoBaPsychGen_v1-ec-eur-king-ibs.ibs0 > MoBaPsychGen_v1-ec-eur-king-ibs.ibs0_hist
Rscript $GITHUB/lib/plot-kinship-histogram.R MoBaPsychGen_v1-ec-eur-king-ibs.ibs0_hist MoBaPsychGen_v1-ec-eur-king-hist
./cryptic.sh MoBaPsychGen_v1-ec-eur-king-ibs.ibs0 MoBaPsychGen_v1-ec-eur-cryptic
Rscript $GITHUB/lib/plot-cryptic.R MoBaPsychGen_v1-ec-eur-cryptic-kinship-sum.txt MoBaPsychGen_v1-ec-eur-cryptic-counts.txt "MoBaPsychGen_v1 EUR" MoBaPsychGen_v1
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

# LD prune #
plink --bfile MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents --extract MoBaPsychGen_v1-ec-eur-prune.prune.in --make-set high-ld.txt --write-set --out MoBaPsychGen_v1-ec-eur-highld
plink --bfile MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents --extract MoBaPsychGen_v1-ec-eur-prune.prune.in --exclude MoBaPsychGen_v1-ec-eur-highld.set --make-bed --out MoBaPsychGen_v1-ec-eur-trimmed

# IBD #
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-ab --keep ab.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-ac --keep ac.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-ad --keep ad.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-ae --keep ae.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-bc --keep bc.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-bd --keep bd.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-be --keep be.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-cd --keep cd.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-ce --keep ce.ind
plink --bfile MoBaPsychGen_v1-ec-eur-trimmed --genome --min 0.15 --out MoBaPsychGen_v1-ec-eur-ibd-de --keep de.ind
IBD.R

awk '{print $5,$7,$8,$10}' MoBaPsychGen_v1-ec-eur-ibd.genome > MoBaPsychGen_v1-ec-eur-ibd.txt
Rscript $GITHUB/lib/plot-ibd.R MoBaPsychGen_v1-ec-eur-ibd.txt "MoBaPsychGen_v1 EUR"
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
rm MoBaPsychGen_v1-ec-eur-ibd.txt
awk '$5=="PO" && $10<0.4 || $5=="PO" && $10>0.6 {print $0}' MoBaPsychGen_v1-ec-eur-ibd.genome > MoBaPsychGen_v1-ec-eur-ibd-bad-parents.txt
awk '$5=="FS" && $10<0.4 || $5=="FS" && $10>0.6 {print $0}' MoBaPsychGen_v1-ec-eur-ibd.genome > MoBaPsychGen_v1-ec-eur-ibd-bad-siblings.txt
awk '$5=="HS" && $10<0.15 || $5=="HS" && $10>0.35 {print $0}' MoBaPsychGen_v1-ec-eur-ibd.genome > MoBaPsychGen_v1-ec-eur-ibd-bad-half-siblings.txt
awk '$5!="PO" && $5!="FS" && $5!="HS" && $10>0.15 {print $0}' MoBaPsychGen_v1-ec-eur-ibd.genome > MoBaPsychGen_v1-ec-eur-ibd-bad-unrelated.txt
cat MoBaPsychGen_v1-ec-eur-ibd-bad-unrelated.txt MoBaPsychGen_v1-ec-eur-ibd-bad-parents.txt MoBaPsychGen_v1-ec-eur-ibd-bad-siblings.txt MoBaPsychGen_v1-ec-eur-ibd-bad-half-siblings.txt > MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt
rm MoBaPsychGen_v1-ec-eur-ibd-bad-unrelated.txt MoBaPsychGen_v1-ec-eur-ibd-bad-parents.txt MoBaPsychGen_v1-ec-eur-ibd-bad-siblings.txt MoBaPsychGen_v1-ec-eur-ibd-bad-half-siblings.txt
awk '{print $2,$3,$15}' MoBaPsychGen_v1-ec-eur-king-1.75.kin > MoBaPsychGen_v1-ec-eur-king-1.75.kin-RT
awk '{print $2,$4,$14}' MoBaPsychGen_v1-ec-eur-king-1.75.kin0 > MoBaPsychGen_v1-ec-eur-king-1.75.kin0-RT
cat MoBaPsychGen_v1-ec-eur-king-1.75.kin-RT MoBaPsychGen_v1-ec-eur-king-1.75.kin0-RT > MoBaPsychGen_v1-ec-eur-king-1.75.RT
rm MoBaPsychGen_v1-ec-eur-king-1.75.kin-RT MoBaPsychGen_v1-ec-eur-king-1.75.kin0-RT
R
bad <- read.table('MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt',h=T,colClasses="character")
bad_match <- subset(bad, FID1==FID2)
bad_nonmatch <- subset(bad, FID1!=FID2)
rm(bad)
kin <- read.table('MoBaPsychGen_v1-ec-eur-king-1.75.RT',h=T)
colnames(kin) <- c("IID1","IID2","InfType")
bad_kin1 <- merge(bad_match, kin, by=c("IID1", "IID2"))
bad_kin2 <- merge(bad_match, kin, by.x=c("IID1", "IID2"), by.y=c("IID2", "IID1"))
bad_kin <- rbind(bad_kin1, bad_kin2)
rm(bad_kin1, bad_kin2)
table(bad_kin$InfType)
bad_kin <- bad_kin[,c(3,1,4,2,5:15)]
write.table(bad_kin, 'MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-InfType',row.names=F, col.names=T, sep='\t', quote=F)
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
write.table(bad_nonmatch, 'MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-Freq',row.names=F, col.names=T, sep='\t', quote=F)
rm(bad_nonmatch)
q()
plink --bfile MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents --missing --out MoBaPsychGen_v1-ec-eur-king-1-missing
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-missing.imiss -g MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-InfType -k 2 -l 2 -v 6 > MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-missing.imiss -g MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 -k 2 -l 4 -v 6 > MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-missing.imiss -g MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-Freq -k 2 -l 2 -v 6 > MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
./match.pl -f MoBaPsychGen_v1-ec-eur-king-1-missing.imiss -g MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1 -k 2 -l 4 -v 6 > MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate
rm MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-InfType-call-rate1 MoBaPsychGen_v1-ec-eur-ibd-bad-relatedness.txt-Freq-call-rate1
plink --bfile MoBaPsychGen_v1-ec-eur-king-1.5-fix-parents --remove MoBaPsychGen_v1-ec-eur-king-1-bad-relatedness-low-call-rate.txt --update-parents MoBaPsychGen_v1-ec-eur-king-1-bad-relatedness-update-parents.txt --make-bed --out MoBaPsychGen_v1-ec-eur-ibd-clean

# Mendelian errors #
plink --bfile MoBaPsychGen_v1-ec-eur-ibd-clean --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out MoBaPsychGen_v1-ec-eur-me-clean-sex

# PCA with 1000 genomes #
plink --bfile MoBaPsychGen_v1-ec-eur-me-clean-sex --extract MoBaPsychGen_v1-ec-eur-prune.prune.in --exclude MoBaPsychGen_v1-ec-eur-highld.set --make-bed --out MoBaPsychGen_v1-ec-eur-me-clean-trimmed
cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
cut -f2 MoBaPsychGen_v1-ec-eur-me-clean-trimmed.bim | sort -s > MoBaPsychGen_v1-ec-eur-me-clean-trimmed.bim.sorted
join 1kg.bim.sorted MoBaPsychGen_v1-ec-eur-me-clean-trimmed.bim.sorted > MoBaPsychGen_v1-ec-eur-me-clean-1kg-snps.txt
rm MoBaPsychGen_v1-ec-eur-me-clean-trimmed.bim.sorted 1kg.bim.sorted
wc -l MoBaPsychGen_v1-ec-eur-me-clean-1kg-snps.txt
plink --bfile MoBaPsychGen_v1-ec-eur-me-clean-trimmed --extract MoBaPsychGen_v1-ec-eur-me-clean-1kg-snps.txt --make-bed --out MoBaPsychGen_v1-ec-eur-1kg-common
plink --bfile 1kg --extract MoBaPsychGen_v1-ec-eur-me-clean-1kg-snps.txt --make-bed --out 1kg-MoBaPsychGen_v1-ec-eur-common
plink --bfile MoBaPsychGen_v1-ec-eur-1kg-common --bmerge 1kg-MoBaPsychGen_v1-ec-eur-common --make-bed --out MoBaPsychGen_v1-ec-eur-1kg-merged
plink --bfile 1kg-MoBaPsychGen_v1-ec-eur-common --flip MoBaPsychGen_v1-ec-eur-1kg-merged-merge.missnp --make-bed --out 1kg-MoBaPsychGen_v1-ec-eur-common-flip
plink --bfile MoBaPsychGen_v1-ec-eur-1kg-common --bmerge 1kg-MoBaPsychGen_v1-ec-eur-common-flip --make-bed --out MoBaPsychGen_v1-ec-eur-1kg-second-merged
plink --bfile MoBaPsychGen_v1-ec-eur-1kg-common --exclude MoBaPsychGen_v1-ec-eur-1kg-second-merged-merge.missnp --make-bed --out MoBaPsychGen_v1-ec-eur-1kg-common-clean
plink --bfile 1kg-MoBaPsychGen_v1-ec-eur-common-flip --exclude MoBaPsychGen_v1-ec-eur-1kg-second-merged-merge.missnp --make-bed --out 1kg-MoBaPsychGen_v1-ec-eur-common-flip-clean
plink --bfile MoBaPsychGen_v1-ec-eur-1kg-common-clean --bmerge 1kg-MoBaPsychGen_v1-ec-eur-common-flip-clean --make-bed --out MoBaPsychGen_v1-ec-eur-1kg-clean-merged
wc -l MoBaPsychGen_v1-ec-eur-1kg-clean-merged.bim
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' MoBaPsychGen_v1-ec-eur-1kg-clean-merged.fam > MoBaPsychGen_v1-ec-eur-1kg-clean-merged-populations.txt
awk '$3=="parent" {print $0}' MoBaPsychGen_v1-ec-eur-1kg-clean-merged-populations.txt > MoBaPsychGen_v1-ec-eur-1kg-merged-founders
plink --bfile MoBaPsychGen_v1-ec-eur-1kg-clean-merged --keep MoBaPsychGen_v1-ec-eur-1kg-merged-founders --keep-allele-order --make-bed --out MoBaPsychGen_v1-ec-eur-1kg-clean-merged-founders
./flashpca_x86-64 --bfile MoBaPsychGen_v1-ec-eur-1kg-clean-merged-founders -d 20 --outload MoBaPsychGen_v1-ec-eur-1kg-founders-loadings.txt --outmeansd MoBaPsychGen_v1-ec-eur-1kg-founders-meansd.txt --suffix -MoBaPsychGen_v1-ec-eur-1kg-founders-pca.txt > MoBaPsychGen_v1-ec-eur-1kg-founders-pca.log
./flashpca_x86-64 --bfile MoBaPsychGen_v1-ec-eur-1kg-clean-merged -d 20 --project --inmeansd MoBaPsychGen_v1-ec-eur-1kg-founders-meansd.txt --outproj MoBaPsychGen_v1-ec-eur-1kg-projections.txt --inload MoBaPsychGen_v1-ec-eur-1kg-founders-loadings.txt -v > MoBaPsychGen_v1-ec-eur-1kg-projections.log
tail -n +2 MoBaPsychGen_v1-ec-eur-1kg-projections.txt | sort -k2 > MoBaPsychGen_v1-ec-eur-1kg-projections.txt-sorted
head -n 207569 MoBaPsychGen_v1-ec-eur-1kg-projections.txt-sorted > MoBaPsychGen_v1-ec-eur-pca
tail -n 1083 MoBaPsychGen_v1-ec-eur-1kg-projections.txt-sorted | sort -k2 > 1kg-ec-eur-fin-pca
cat MoBaPsychGen_v1-ec-eur-pca 1kg-ec-eur-fin-pca > MoBaPsychGen_v1-ec-eur-1kg-pca
Rscript $GITHUB/lib/plot-pca-with-1kg.R MoBaPsychGen_v1 MoBaPsychGen_v1-ec-eur-1kg-pca bottomleft MoBaPsychGen_v1-ec-eur-1kg
Rscript $GITHUB/lib/select-subsamples-on-pca.R MoBaPsychGen_v1 MoBaPsychGen_v1-ec-eur-1kg-pca MoBaPsychGen_v1-ec-eur-selection MoBaPsychGen_v1-ec-eur-pca-core-select-custom.txt
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

# PCA #
awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' MoBaPsychGen_v1-ec-eur-me-clean-trimmed.fam > MoBaPsychGen_v1-ec-eur-me-clean-trimmed-populations.txt
awk '$3=="parent" {print $0}' MoBaPsychGen_v1-ec-eur-me-clean-trimmed-populations.txt > MoBaPsychGen_v1-ec-eur-me-clean-trimmed-founders
plink --bfile MoBaPsychGen_v1-ec-eur-me-clean-trimmed --keep MoBaPsychGen_v1-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out MoBaPsychGen_v1-ec-eur-me-clean-trimmed-founders
./flashpca_x86-64 --bfile MoBaPsychGen_v1-ec-eur-me-clean-trimmed-founders -d 20 --outload MoBaPsychGen_v1-ec-eur-founders-loadings.txt --outmeansd MoBaPsychGen_v1-ec-eur-founders-meansd.txt --suffix -MoBaPsychGen_v1-ec-eur-founders-pca.txt > MoBaPsychGen_v1-ec-eur-founders-pca.log
./flashpca_x86-64 --bfile MoBaPsychGen_v1-ec-eur-me-clean-trimmed -d 20 --project --inmeansd MoBaPsychGen_v1-ec-eur-founders-meansd.txt --outproj MoBaPsychGen_v1-ec-eur-projections.txt --inload MoBaPsychGen_v1-ec-eur-founders-loadings.txt -v > MoBaPsychGen_v1-ec-eur-projections.log
awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red"}' MoBaPsychGen_v1-ec-eur-me-clean-trimmed.fam > MoBaPsychGen_v1-ec-eur-me-clean-trimmed-fam.txt
./match.pl -f MoBaPsychGen_v1-ec-eur-me-clean-trimmed-fam.txt -g MoBaPsychGen_v1-ec-eur-projections.txt -k 2 -l 2 -v 3 > MoBaPsychGen_v1-ec-eur-pca-fam.txt
tail -n +2 MoBaPsychGen_v1-ec-eur-pca-fam.txt > MoBaPsychGen_v1-ec-eur-pca-fam.txt_noheader
Rscript $GITHUB/lib/plot-batch-PCs.R MoBaPsychGen_v1-ec-eur-pca-fam.txt_noheader "MoBaPsychGen_v1 EUR" bottomright MoBaPsychGen_v1-ec-eur-pca.png
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

# Batch effects #
./match.pl -f Imputation-batches.txt -g MoBaPsychGen_v1-ec-eur-projections.txt -k 1 -l 2 -v 2 | awk '$23!="-" {print $0}' | sort -k23 | tail -n +2 > MoBaPsychGen_v1-ec-eur-pca-batch.txt
awk '{print $1,$2,$23}' MoBaPsychGen_v1-ec-eur-pca-batch.txt > MoBaPsychGen_v1-ec-eur-batch-groups.txt
Rscript $GITHUB/lib/plot-PC-by-batch.R MoBaPsychGen_v1-ec-eur-pca-batch.txt "MoBaPsychGen_v1 EUR" MoBaPsychGen_v1-ec-eur
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
Rscript $GITHUB/lib/anova-for-PC-vs-plates.R MoBaPsychGen_v1-ec-eur-pca-batch.txt MoBaPsychGen_v1-ec-eur-pca-anova-results.txt
more MoBaPsychGen_v1-ec-eur-pca-anova-results.txt
plink --bfile MoBaPsychGen_v1-ec-eur-me-clean-sex --filter-founders --chr 1-22 --pheno MoBaPsychGen_v1-ec-eur-me-clean-sex.fam --mpheno 3 --within MoBaPsychGen_v1-ec-eur-batch-groups.txt --mh2 --out MoBaPsychGen_v1-ec-eur-mh-batch
Rscript $GITHUB/lib/plot-qqplot.R MoBaPsychGen_v1-ec-eur-mh-batch.cmh2 "MoBaPsychGen_v1 EUR" 5 MoBaPsychGen_v1-ec-eur-mh-batch-test-qq-plot
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/
sort -k5 -g MoBaPsychGen_v1-ec-eur-mh-batch.cmh2 | grep -v "NA" > MoBaPsychGen_v1-ec-eur-mh2-batch-sorted
awk '$5<0.00000005 {print $2}' MoBaPsychGen_v1-ec-eur-mh2-batch-sorted > MoBaPsychGen_v1-ec-eur-mh2-batch-significant
wc -l MoBaPsychGen_v1-ec-eur-mh2-batch-significant
plink --bfile MoBaPsychGen_v1-ec-eur-me-clean-sex --exclude MoBaPsychGen_v1-ec-eur-mh2-batch-significant --make-bed --out MoBaPsychGen_v1-ec-eur-batch
plink --bfile MoBaPsychGen_v1-ec-eur-batch --extract MoBaPsychGen_v1-ec-eur-prune.prune.in --exclude MoBaPsychGen_v1-ec-eur-highld.set --make-bed --out MoBaPsychGen_v1-ec-eur-batch-trimmed
plink --bfile MoBaPsychGen_v1-ec-eur-batch-trimmed --keep MoBaPsychGen_v1-ec-eur-me-clean-trimmed-founders --keep-allele-order --make-bed --out MoBaPsychGen_v1-ec-eur-batch-trimmed-founders
./flashpca_x86-64 --bfile MoBaPsychGen_v1-ec-eur-batch-trimmed-founders -d 20 --outload MoBaPsychGen_v1-ec-eur-batch-founders-loadings.txt --outmeansd MoBaPsychGen_v1-ec-eur-batch-founders-meansd.txt --suffix -MoBaPsychGen_v1-ec-eur-batch-founders-pca.txt > MoBaPsychGen_v1-ec-eur-batch-founders-pca.log
./flashpca_x86-64 --bfile MoBaPsychGen_v1-ec-eur-batch-trimmed -d 20 --project --inmeansd MoBaPsychGen_v1-ec-eur-batch-founders-meansd.txt --outproj MoBaPsychGen_v1-ec-eur-batch-projections.txt --inload MoBaPsychGen_v1-ec-eur-batch-founders-loadings.txt -v > MoBaPsychGen_v1-ec-eur-batch-projections.log
./match.pl -f Imputation-batches.txt -g MoBaPsychGen_v1-ec-eur-batch-projections.txt -k 1 -l 2 -v 2 | awk '$23!="-" {print $0}' | sort -k23 | tail -n +2 > MoBaPsychGen_v1-ec-eur-batch-pca-batch.txt
Rscript $GITHUB/lib/anova-for-PC-vs-plates.R MoBaPsychGen_v1-ec-eur-batch-pca-batch.txt MoBaPsychGen_v1-ec-eur-batch-pca-anova-results.txt
more MoBaPsychGen_v1-ec-eur-batch-pca-anova-results.txt

#Basic QC #
plink --bfile MoBaPsychGen_v1-ec-eur-batch --maf 0.01 --make-bed --out MoBaPsychGen_v1-ec-eur-batch-common
plink --bfile MoBaPsychGen_v1-ec-eur-batch-common --geno 0.05 --make-bed --out MoBaPsychGen_v1-ec-eur-batch-95
plink --bfile MoBaPsychGen_v1-ec-eur-batch-95 --geno 0.05 --mind 0.02 --make-bed --out MoBaPsychGen_v1-ec-eur-batch-call-rates
plink --bfile MoBaPsychGen_v1-ec-eur-batch-call-rates --hwe 0.000001 --update-parents update_parents-no-224-IDs.txt --make-bed --out MoBaPsychGen_v1-ec-eur-batch-basic-qc

plink --bfile MoBaPsychGen_v1-ec-eur-batch-basic-qc --extract MoBaPsychGen_v1-ec-eur-multi-clean-prune.prune.in --make-bed --out MoBaPsychGen_v1-ec-eur-batch-basic-qc-pruned
/cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b MoBaPsychGen_v1-ec-eur-batch-basic-qc-pruned.bed --related --degree 2 --rplot --prefix MoBaPsychGen_v1-ec-eur-batch-basic-qc-rel > MoBaPsychGen_v1-ec-eur-batch-basic-qc-rel.log
sh $GITHUB/tools/create-relplot.sh MoBaPsychGen_v1-ec-eur-batch-basic-qc-rel_relplot.R "MoBaPsychGen_v1 EUR" topright bottomright topright bottomright
cp *.png /tsd/p697/data/durable/projects/moba_qc_imputation/EC/MoBaPsychGen_v1/

IBD_final.R
