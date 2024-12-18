#!/bin/bash

set -u
set -e

echo "Using plink: $(which plink), version: $(plink --version)"

# general parameters
MOBA_QC_DIR_CLUSTER=/ess/p697/cluster/projects/moba_qc_imputation
CHRX_ORIG_DIR=${MOBA_QC_DIR_CLUSTER}/OF/chrX_imputation/batches/
MOBA_QC_DIR_DURABLE=/ess/p697/data/durable/projects/moba_qc_imputation
RESOURCES_DIR=${MOBA_QC_DIR_DURABLE}/resources
SOFTWARE_DIR=${MOBA_QC_DIR_DURABLE}/software
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation

# batch and user specific parameters
BATCH_ID="norment_feb2018" # prefix of the original plink --silent bfiles.
INITIALS="as"
POP="eur-fin"
PREFIX="${BATCH_ID}-${INITIALS}-${POP}" # prefix of all produced files
BATCH_LABEL="Norment_feb2018"
ARRAY="GSA" # GSA HCE or OMNI
WORK_DIR=${MOBA_QC_DIR_DURABLE}/AS/ChrX/${BATCH_ID}

rsync -zah ${GITHUB}/software/match.pl ${WORK_DIR}
chmod +x match.pl
rsync -zah "${RESOURCES_DIR}/${ARRAY}-plates.txt" ${WORK_DIR}

#--------------------------------------------------------------------
# Sync input data
echo ">>> Sync input data"
# BFILE variable contains input genotypes prefix, OUT contains output file prefix.
BFILE=${BATCH_ID}
for ext in bed bim fam; do rsync -zah ${CHRX_ORIG_DIR}/${BFILE}.${ext} ${WORK_DIR}; done

# ROUND 1.
# Restrict to individuals passing autosome QC and update pedigree to match
echo ">>> Round 1"
OUT="${BATCH_ID}-sex_chr-${INITIALS}-update-ids"
plink --silent --bfile ${BFILE} --update-ids ${RESOURCES_DIR}/MoBa_PsychGen_v1_update_ids.txt --chr 23-25 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-sex_chr-${INITIALS}-keep"
plink --silent --bfile ${BFILE} --keep ${RESOURCES_DIR}/MoBa_PsychGen_v1_keep.txt --update-parents ${RESOURCES_DIR}/MoBa_PsychGen_v1_update_parents.txt --make-bed --out ${OUT}

# Split by chromosome and where relevant by sex
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-female"
plink --silent --bfile ${BFILE} --chr 23 --filter-females --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-male"
plink --silent --bfile ${BFILE} --chr 23 --filter-males --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-female"
plink --silent --bfile ${BFILE} --chr 24 --filter-females --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-male"
plink --silent --bfile ${BFILE} --chr 24 --filter-males --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr25"
plink --silent --bfile ${BFILE} --chr 25 --make-bed --out ${OUT}

# Basic QC
# MAF
BFILE="${BATCH_ID}-${INITIALS}-chr23-female"
OUT="${BFILE}-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr23-male"
OUT="${BFILE}-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr24-male"
OUT="${BFILE}-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr25"
OUT="${BFILE}-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}

# Call rates
BFILE="${BATCH_ID}-${INITIALS}-chr23-female-common"
MISSING="${BATCH_ID}-${INITIALS}-chr23-female-missing"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript ${GITHUB}/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID} females, chromosome X"
OUT="${BATCH_ID}-${INITIALS}-chr23-female-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-female-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-female-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr23-male-common"
MISSING="${BATCH_ID}-${INITIALS}-chr23-male-missing"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript ${GITHUB}/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID} males, chromosome X"
OUT="${BATCH_ID}-${INITIALS}-chr23-male-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-male-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-male-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}

BFILE="${BATCH_ID}-${INITIALS}-chr24-male-common"
MISSING="${BATCH_ID}-${INITIALS}-chr24-male-missing"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript ${GITHUB}/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID} males, chromosome Y"
OUT="${BATCH_ID}-${INITIALS}-chr24-male-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-male-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-male-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}

BFILE="${BATCH_ID}-${INITIALS}-chr25-common"
MISSING="${BATCH_ID}-${INITIALS}-chr25-missing"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript $GITHUB/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID}, chromosome XY"
OUT="${BATCH_ID}-${INITIALS}-chr25-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr25-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr25-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}

# HWE
BFILE="${BATCH_ID}-${INITIALS}-chr23-female-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr23-female-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr23-male-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr23-male-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr24-male-call-rates" 
OUT="${BATCH_ID}-${INITIALS}-chr24-male-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr25-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr25-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
# Hetrozygosity. Only run in chr 25
BFILE="${BATCH_ID}-${INITIALS}-chr25-basic-qc"
MISSING="${BATCH_ID}-${INITIALS}-chr25-het-miss"
plink --silent --bfile ${BFILE} --het --missing --out ${MISSING}
Rscript $GITHUB/lib/plot-heterozygosity-common.R ${MISSING} "${BATCH_ID}, chromosome XY"
tail -n+2 ${MISSING}-het-fail.txt | wc -l

# Sex check
echo '
library(data.table)
f <- fread("'${BATCH_ID}-${INITIALS}-chr23-female-basic-qc.bim'", h=F)
m <- fread("'${BATCH_ID}-${INITIALS}-chr23-male-basic-qc.bim'", h=F)
f <- f[,2]
m <- m[,2]
overlap <- merge(f, m, by="V2")
m24 <- fread("'${BATCH_ID}-${INITIALS}-chr24-male-basic-qc.bim'", h=F)
m24 <- m24[,2]
par <- fread("'${BATCH_ID}-${INITIALS}-chr25-basic-qc.bim'")
par <- par[,2]
snps <- rbind(overlap, m24, par)
fwrite(snps, "'${BATCH_ID}-${INITIALS}-chr23-24-25-keep.snps'", quote=F, row.names=F, col.names=F, sep="\t")
rm(f, m, overlap, m24, snps, par)
m23 <- fread("'${BATCH_ID}-${INITIALS}-chr23-male-basic-qc.fam'",h=F)
m24 <- fread("'${BATCH_ID}-${INITIALS}-chr24-male-basic-qc.fam'",h=F)
m23 <- m23[,c(1:2)]
m24 <- m24[,c(1:2)]
m <- merge(m23, m24, by=c("V1","V2"))
f23 <- fread("'${BATCH_ID}-${INITIALS}-chr23-female-basic-qc.fam'",h=F)
f23 <- f23[,c(1:2)]
ind <- rbind(f23, m)
par <- fread("'${BATCH_ID}-${INITIALS}-chr25-basic-qc.fam'",h=F)
par <- par[,c(1:2)]
keep <- merge(ind, par, by=c("V1","V2"))
fwrite(keep, "'${BATCH_ID}-${INITIALS}-chr23-24-25-keep.ind'", quote=F, row.names=F, col.names=F, sep="\t")
q()
' | R --vanilla

MERGE_LIST="${BATCH_ID}-${INITIALS}-chr23-24-25_merge.txt"
echo "${BATCH_ID}-${INITIALS}-chr23-female-basic-qc" > ${MERGE_LIST}
echo "${BATCH_ID}-${INITIALS}-chr23-male-basic-qc" >> ${MERGE_LIST}
echo "${BATCH_ID}-${INITIALS}-chr24-male-basic-qc" >> ${MERGE_LIST}
echo "${BATCH_ID}-${INITIALS}-chr24-female" >> ${MERGE_LIST}
echo "${BATCH_ID}-${INITIALS}-chr25-basic-qc" >> ${MERGE_LIST}
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-basic-qc"
plink --silent --merge-list ${MERGE_LIST} --keep "${BATCH_ID}-${INITIALS}-chr23-24-25-keep.ind" --extract "${BATCH_ID}-${INITIALS}-chr23-24-25-keep.snps" --make-bed --out ${OUT}

# Run sex check
# Regular sex check based on chr x only
BFILE=${OUT}
SEXCHECK_X="${BATCH_ID}-${INITIALS}-chr23-24-25-sex-check"
plink --silent --bfile ${BFILE} --check-sex --out ${SEXCHECK_X}
# Sex check based on y chromosome data
SEXCHECK_Y="${BATCH_ID}-${INITIALS}-chr23-24-25-sex-check-y-only"
plink --silent --bfile ${BFILE} --check-sex y-only --out ${SEXCHECK_Y}
MISSING="${BATCH_ID}-${INITIALS}-chr23-24-25-miss"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}

SEXCHECK="${BATCH_ID}-${INITIALS}-chr23-24-25.sexcheck"
./match.pl -f ${SEXCHECK_Y}.sexcheck -g ${SEXCHECK_X}.sexcheck -k 2 -l 2 -v 6 > ${SEXCHECK}
SEXPLOT="${BATCH_ID}-${INITIALS}-chr23-24-25-sex-plot"
./match.pl -f ${MISSING}.imiss -g ${SEXCHECK} -k 2 -l 2 -v 6 > "${SEXPLOT}.txt"
Rscript ${GITHUB}/lib/plot-sex.R "${SEXPLOT}.txt" "${BATCH_ID}, chromosome X" topleft "${SEXPLOT}.png"
# Identify individuals to remove
BAD_SEX="${BATCH_ID}-${INITIALS}-chr23-24-25-bad-sex.txt"
awk '$3!=0 && $5=="PROBLEM" {print $0}' "${SEXPLOT}.txt" > ${BAD_SEX}
wc -l ${BAD_SEX}
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-pass-sex-check"
plink --silent --bfile ${BFILE} --remove ${BAD_SEX} --make-bed --out ${OUT}

# ME. All sex chromosomes
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-me"
plink --silent --bfile ${BFILE} --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out ${OUT}

# Plate effects
# Create shuffled sex phenotype
BFILE=${OUT} # original-initials-chr23-24-25-me
FAM="${BFILE}.fam"
SHUF_SEX="${BATCH_ID}-${INITIALS}-chr23-24-25-shuffle_sex.txt"
echo -e "FID\tIID\tPHENO" > ${SHUF_SEX}
paste <(cut -d' ' -f1,2 ${FAM} | tr ' ' $'\t') <(cut -f5 -d' ' ${FAM} | shuf --random-source <(yes "moba")) >> ${SHUF_SEX}
# Create plate file
PLATES="${BATCH_ID}-${INITIALS}-chr23-24-25-plates.txt"
./match.pl -f "${ARRAY}-plates.txt" -g ${FAM} -k 1 -l 2 -v 3 | awk '$7!="-" {print $0}' | sort -k7,7 | awk '{print $1,$2,$7}' > ${PLATES}
# Run mh2 test
MH="${BATCH_ID}-${INITIALS}-chr23-24-25-mh-plates"
plink --silent --bfile ${BFILE} --filter-founders --pheno ${SHUF_SEX} --within ${PLATES} --mh2 --out ${MH}
# Create QQ plot
Rscript $GITHUB/lib/plot-qqplot.R "${MH}.cmh2" "${BATCH_ID}, chromosome X" 5 "${MH}-qq-plot"
# Identify SNPs to remove
sort -k 5 -g "${MH}.cmh2" | grep -v "NA" > "${MH}-sorted"
awk '$5<0.001 {print $2}' "${MH}-sorted" > "${MH}-significant"
wc -l "${MH}-significant"
# Exclude SNPs
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-batch"
plink --silent --bfile ${BFILE} --exclude "${MH}-significant" --make-bed --out ${OUT}

# ROUND 2.
# Split by chromosome and where relevant by sex
echo ">>> Round 2"
BFILE="${BATCH_ID}-${INITIALS}-chr23-24-25-batch"
OUT="${BATCH_ID}-${INITIALS}-chr23-female-2"
plink --silent --bfile ${BFILE} --chr 23 --filter-females --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-male-2"
plink --silent --bfile ${BFILE} --chr 23 --filter-males --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-female-2"
plink --silent --bfile ${BFILE} --chr 24 --filter-females --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-male-2"
plink --silent --bfile ${BFILE} --chr 24 --filter-males --make-bed --out ${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr25-2"
plink --silent --bfile ${BFILE} --chr 25 --make-bed --out ${OUT}

# Basic QC
# MAF
BFILE="${BATCH_ID}-${INITIALS}-chr23-female-2"
OUT="${BATCH_ID}-${INITIALS}-chr23-female-2-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr23-male-2"
OUT="${BATCH_ID}-${INITIALS}-chr23-male-2-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr24-male-2"
OUT="${BATCH_ID}-${INITIALS}-chr24-male-2-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr25-2"
OUT="${BATCH_ID}-${INITIALS}-chr25-2-common"
plink --silent --bfile ${BFILE} --maf 0.005 --make-bed --out ${OUT}
# Call rates
BFILE="${BATCH_ID}-${INITIALS}-chr23-female-2-common"
MISSING="${BATCH_ID}-${INITIALS}-chr23-female-2-missing"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript ${GITHUB}/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID} females, chromosome X"
OUT="${BATCH_ID}-${INITIALS}-chr23-female-2-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-female-2-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-female-2-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr23-male-2-common"
MISSING="${BATCH_ID}-${INITIALS}-chr23-male-2-missing"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript $GITHUB/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID} males, chromosome X"
OUT="${BATCH_ID}-${INITIALS}-chr23-male-2-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-male-2-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-male-2-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr24-male-2-common"
MISSING="${BATCH_ID}-${INITIALS}-chr24-male-2-missing" 
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
Rscript $GITHUB/lib/plot-missingness-histogram.R ${MISSING} "${BATCH_ID} males, chromosome X"
OUT="${BATCH_ID}-${INITIALS}-chr24-male-2-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-male-2-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr24-male-2-call-rates" 
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr25-2-common" 
MISSING="${BATCH_ID}-${INITIALS}-chr25-2-missing"
plink --silent --bfile ${BFILE} --missing --out ${OUT}
Rscript ${GITHUB}/lib/plot-missingness-histogram.R ${OUT} "${BATCH_ID} males, chromosome X"
OUT="${BATCH_ID}-${INITIALS}-chr25-2-95"
plink --silent --bfile ${BFILE} --geno 0.05 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr25-2-98"
plink --silent --bfile ${BFILE} --geno 0.02 --make-bed --out ${OUT}
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr25-2-call-rates"
plink --silent --bfile ${BFILE} --geno 0.02 --mind 0.02 --make-bed --out ${OUT}

# HWE
BFILE="${BATCH_ID}-${INITIALS}-chr23-female-2-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr23-female-2-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr23-male-2-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr23-male-2-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr24-male-2-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr24-male-2-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
BFILE="${BATCH_ID}-${INITIALS}-chr25-2-call-rates"
OUT="${BATCH_ID}-${INITIALS}-chr25-2-basic-qc"
plink --silent --bfile ${BFILE} --hwe 0.000001 --make-bed --out ${OUT}
# Hetrozygosity. Unless distribution is non-normal don't remove individuals  - instead rely on checks performed in autosome QC
BFILE="${BATCH_ID}-${INITIALS}-chr25-2-basic-qc"
HET_MISS="${BATCH_ID}-${INITIALS}-chr25-2-het-miss"
plink --silent --bfile ${BFILE} --het --missing --out ${HET_MISS}
Rscript $GITHUB/lib/plot-heterozygosity-common.R ${HET_MISS} "${BATCH_ID}, chromosome XY"
tail -n+2 "${HET_MISS}-het-fail.txt" | wc -l


# Sex check. Merge all sex chromosomes. Create SNP list.
echo '
library(data.table)
f <- fread("'${BATCH_ID}-${INITIALS}-chr23-female-2-basic-qc.bim'", h=F)
m <- fread("'${BATCH_ID}-${INITIALS}-chr23-male-2-basic-qc.bim'", h=F)
f <- f[,2]
m <- m[,2]
overlap <- merge(f, m, by="V2")
m24 <- fread("'${BATCH_ID}-${INITIALS}-chr24-male-2-basic-qc.bim'", h=F)
m24 <- m24[,2]
par <- fread("'${BATCH_ID}-${INITIALS}-chr25-2-basic-qc.bim'")
par <- par[,2]
snps <- rbind(overlap, m24, par)
fwrite(snps, "'${BATCH_ID}-${INITIALS}-chr23-24-25-2-keep.snps'", quote=F, row.names=F, col.names=F, sep="\t")
rm(f, m, overlap, m24, snps, par)
# Create individual list
m23 <- fread("'${BATCH_ID}-${INITIALS}-chr23-male-2-basic-qc.fam'",h=F)
m24 <- fread("'${BATCH_ID}-${INITIALS}-chr24-male-2-basic-qc.fam'",h=F)
m23 <- m23[,c(1:2)]
m24 <- m24[,c(1:2)]
m <- merge(m23, m24, by=c("V1","V2"))
f23 <- fread("'${BATCH_ID}-${INITIALS}-chr23-female-2-basic-qc.fam'",h=F)
f23 <- f23[,c(1:2)]
ind <- rbind(f23, m)
par <- fread("'${BATCH_ID}-${INITIALS}-chr25-2-basic-qc.fam'",h=F)
par <- par[,c(1:2)]
keep <- merge(ind, par, by=c("V1","V2"))
fwrite(keep, "'${BATCH_ID}-${INITIALS}-chr23-24-25-2-keep.ind'", quote=F, row.names=F, col.names=F, sep="\t")
q()
' | R --vanilla

# Create merge list
MERGE_LIST_2="${BATCH_ID}-${INITIALS}-chr23-24-25-2_merge.txt"
echo "${BATCH_ID}-${INITIALS}-chr23-female-2-basic-qc" > ${MERGE_LIST_2}
echo "${BATCH_ID}-${INITIALS}-chr23-male-2-basic-qc" >> ${MERGE_LIST_2}
echo "${BATCH_ID}-${INITIALS}-chr24-male-2-basic-qc" >> ${MERGE_LIST_2}
echo "${BATCH_ID}-${INITIALS}-chr24-female-2" >> ${MERGE_LIST_2}
echo "${BATCH_ID}-${INITIALS}-chr25-2-basic-qc" >> ${MERGE_LIST_2}
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-2-basic-qc"
plink --silent --merge-list ${MERGE_LIST_2} --keep "${BATCH_ID}-${INITIALS}-chr23-24-25-2-keep.ind" --extract "${BATCH_ID}-${INITIALS}-chr23-24-25-2-keep.snps" --make-bed --out ${OUT}

# Run sex check.
# Regular sex check based on chr x only.
BFILE="${BATCH_ID}-${INITIALS}-chr23-24-25-2-basic-qc"
SEXCHECK_x="${BATCH_ID}-${INITIALS}-chr23-24-25-2-sex-check"
plink --silent --bfile ${BFILE} --check-sex --out ${SEXCHECK_X}
# Sex check based on y chromosome data.
SEXCHECK_Y="${BATCH_ID}-${INITIALS}-chr23-24-25-2-sex-check-y-only"
plink --silent --bfile ${BFILE} --check-sex y-only --out ${SEXCHECK_Y}
# Merge output from chr x and y plus missingness information.
MISSING="${BATCH_ID}-${INITIALS}-chr23-24-25-2-miss"
plink --silent --bfile ${BFILE} --missing --out ${MISSING}
SEXCHECK="${BATCH_ID}-${INITIALS}-chr23-24-25-2.sexcheck"
./match.pl -f "${SEXCHECK_Y}.sexcheck" -g "${SEXCHECK_X}.sexcheck" -k 2 -l 2 -v 6 > ${SEXCHECK}
SEXPLOT="${BATCH_ID}-${INITIALS}-chr23-24-25-2-sex-plot"
./match.pl -f ${MISSING}.imiss -g ${SEXCHECK} -k 2 -l 2 -v 6 > "${SEXPLOT}.txt"

# Create plot.
Rscript ${GITHUB}/lib/plot-sex.R "${SEXPLOT}.txt" "${BATCH_ID}, chromosome X" topleft "${SEXPLOT}.png"
# Identify individuals to remove.
BAD_SEX="${BATCH_ID}-${INITIALS}-chr23-24-25-2-bad-sex.txt"
awk '$3!=0 && $5=="PROBLEM" {print $0}' "${SEXPLOT}.txt" > ${BAD_SEX}
wc -l ${BAD_SEX}
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-2-pass-sex-check"
plink --silent --bfile ${BFILE} --remove ${BAD_SEX} --make-bed --out ${OUT}

# ME. All sex chromosomes.
BFILE=${OUT}
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-2-me"
plink --silent --bfile ${BFILE} --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out ${OUT}

# Plate effects.
# Create plate file.
BFILE=${OUT} # ${BATCH_ID}-${INITIALS}-chr23-24-25-2-me
FAM="${BFILE}.fam"
PLATES="${BATCH_ID}-${INITIALS}-chr23-24-25-2-plates.txt"
./match.pl -f "${ARRAY}-plates.txt" -g ${FAM} -k 1 -l 2 -v 3 | awk '$7!="-" {print $0}' | sort -k7,7 | awk '{print $1,$2,$7}' > ${PLATES}
# Run mh2 test (using original shuffled sex phenotype)
MH="${BATCH_ID}-${INITIALS}-chr23-24-25-2-mh-plates"
plink --silent --bfile ${BFILE} --filter-founders --pheno ${SHUF_SEX} --within ${PLATES} --mh2 --out ${MH}
# Create QQ plot.
Rscript $GITHUB/lib/plot-qqplot.R "${MH}.cmh2" "${BATCH_ID}, sex chromosomes" 5 "${MH}-qq-plot"
# Identify SNPs to remove.
sort -k5,5g "${MH}.cmh2" | grep -v "NA" > "${MH}-sorted"
awk '$5<0.001 {print $2}' "${MH}-sorted" > "${MH}-significant"
wc -l "${MH}-significant"
# Exclude SNPs
OUT="${BATCH_ID}-${INITIALS}-chr23-24-25-2-batch"
plink --silent --bfile ${BFILE} --exclude "${MH}-significant" --make-bed --out ${OUT}

