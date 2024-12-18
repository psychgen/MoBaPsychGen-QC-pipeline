#!/bin/bash

# general parameters
MOBA_QC_DIR=/tsd/p697/data/durable/projects/moba_qc_imputation
RESOURCES_DIR=${MOBA_QC_DIR}/resources
SOFTWARE_DIR=${MOBA_QC_DIR}/software
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation

# batch and user specific parameters
BATCH_ID="PDB1479_R1273_sentrix" # prefix of the original plink --silent bfiles.
INITIALS="as"
POP="eur-fin"
PREFIX="${BATCH_ID}-${INITIALS}-${POP}" # prefix of all produced files
BATCH_LABEL=Norment_mar2021_1273
BATCH_BFILE_DIR=${MOBA_QC_DIR}/AS/norment_mar2021_1273/M1
WORK_DIR=${MOBA_QC_DIR}/AS/norment_mar2021_1273/M2

LINKAGE_VERSION=12

# flow control parameters
RUN_TRUE=true
RUN_FALSE=false

#--------------------------------------------------------------------

# Sync input data
echo ">>> Sync input data"
for ext in bed bim fam; do rsync -zah ${BATCH_BFILE_DIR}/${PREFIX}.${ext} ${WORK_DIR}; done
rsync -zah ${RESOURCES_DIR}/unlinkable_IDs_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/yob_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/age_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/sex_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/high-ld.txt ${WORK_DIR}
rsync -zah $GITHUB/software/match.pl ${WORK_DIR}
chmod +x match.pl
for ext in bed bim fam; do rsync -zah ${RESOURCES_DIR}/1kg.${ext} ${WORK_DIR}; done
rsync -zah ${RESOURCES_DIR}/populations.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/genotyped_pedigree_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${MOBA_QC_DIR}/scripts/cryptic.sh ${WORK_DIR}
chmod +x cryptic.sh
rsync -zah ${RESOURCES_DIR}/GSA-plates.txt ${WORK_DIR}

if $RUN_FALSE; then
    # Basic QC
    echo ">>> ROUND 1. Basic QC"
    plink --silent --bfile ${PREFIX} --maf 0.005 --make-bed --out ${PREFIX}-common
    ./match.pl -f ${PREFIX}-common.bim -g ${PREFIX}.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"rare, round 1"}' > ${PREFIX}-bad-snps.txt
    plink --silent --bfile ${PREFIX}-common --missing --out ${PREFIX}-missing
    Rscript $GITHUB/lib/plot-missingness-histogram.R ${PREFIX}-missing "${BATCH_LABEL} ${POP}"
    plink --silent --bfile ${PREFIX}-common --geno 0.05 --make-bed --out ${PREFIX}-95
    cut -f2 ${PREFIX}-common.bim ${PREFIX}-95.bim | sort | uniq -c | awk '{if($1==1) print($2)}' > ${PREFIX}-95-failed-snps.txt
    plink --silent --bfile ${PREFIX}-95 --geno 0.02 --make-bed --out ${PREFIX}-98
    plink --silent --bfile ${PREFIX}-98 --mind 0.02 --geno 0.02 --make-bed --out ${PREFIX}-call-rates
    cut -f2 ${PREFIX}-95.bim ${PREFIX}-call-rates.bim | sort | uniq -c | awk '{if($1==1) print($2)}' > ${PREFIX}-basic-qc-snp-call-rate-fail.txt

    plink --silent --bfile ${PREFIX}-call-rates --hwe 0.000001 --make-bed --out ${PREFIX}-basic-qc
    cut -f2 ${PREFIX}-call-rates.bim ${PREFIX}-basic-qc.bim | sort | uniq -c | awk '{if($1==1) print($2)}' > ${PREFIX}-basic-qc-snp-hwe-fail.txt

    plink --silent --bfile ${PREFIX}-basic-qc --chr 1-22 --het --missing --out ${PREFIX}-common
    Rscript $GITHUB/lib/plot-heterozygosity-common.R ${PREFIX}-common "${BATCH_LABEL} ${POP}"
    plink --silent --bfile ${PREFIX}-basic-qc --remove ${PREFIX}-common-het-fail.txt --make-bed --out ${PREFIX}-het

    # Sex check
    echo ">>> ROUND 1. Sex check"
    plink --silent --bfile ${PREFIX}-het --split-x b37 'no-fail' --make-bed --out ${PREFIX}-pseudo
    plink --silent --bfile ${PREFIX}-pseudo --check-sex --out ${PREFIX}-sexcheck-1
    plink --silent --bfile ${PREFIX}-pseudo --chr 23 --missing --out ${PREFIX}-chr23-miss
    ./match.pl -f ${PREFIX}-chr23-miss.imiss -g ${PREFIX}-sexcheck-1.sexcheck -k 2 -l 2 -v 6 > ${PREFIX}-1-chr23-plot.txt
    Rscript $GITHUB/lib/plot-sex.R ${PREFIX}-1-chr23-plot.txt "${BATCH_LABEL} ${POP}, round 1" topleft ${PREFIX}-1-sex-plot.png
    awk '$3!=0 && $5=="PROBLEM" {print $0}' ${PREFIX}-sexcheck-1.sexcheck > ${PREFIX}-bad-sex-1.txt
    awk '$3==1 && $6<0.5 || $3==2 && $6>0.5 {print $0}' ${PREFIX}-bad-sex-1.txt > ${PREFIX}-erroneous-sex-1.txt
    plink --silent --bfile ${PREFIX}-het --remove ${PREFIX}-erroneous-sex-1.txt --make-bed --out ${PREFIX}-sex-1

    # Duplicates
    # there is no duplicates in norment_feb20v3 batch:
    # plink --silent --bfile ${PREFIX}-pseudo --keep ../../../resources/gsa_duplicates.txt --make-bed --out dup_test
    # returns: "Error: No people remaining after --keep"

    # Unlinkable individuals
    echo ">>> ROUND 1. Unlinkable individuals"
    plink --silent --bfile ${PREFIX}-sex-1 --remove unlinkable_IDs_v${LINKAGE_VERSION}.txt --make-bed --out ${PREFIX}-linked-only
fi

if $RUN_FALSE; then
    # (5) Pedigree build and known relatedness
    echo ">>> ROUND 1. Pedigree build and known relatedness"
    cp age_v${LINKAGE_VERSION}.txt ${PREFIX}-linked-only.cov
    /cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b ${PREFIX}-linked-only.bed --related --ibs --cpus 32 --build --degree 2 --rplot --prefix ${PREFIX}-king-1 > ${PREFIX}-king-1-slurm.txt
fi

if $RUN_FALSE; then
    # (5.2) Update pedigree according to KING output
    echo ">>> ROUND 1. Update pedigree according to KING output."
    awk '{print $1,$2,$3,$2}' ${PREFIX}-king-1updateids.txt > ${PREFIX}-king-1updateids.txt-sentrix
    sed -r 's/[^\t]*->//g' ${PREFIX}-king-1updateparents.txt > ${PREFIX}-king-1updateparents.txt-sentrix
    plink --silent --bfile ${PREFIX}-linked-only --update-ids ${PREFIX}-king-1updateids.txt-sentrix --make-bed --out ${PREFIX}-king-1-ids
    plink --silent --bfile ${PREFIX}-king-1-ids --update-parents ${PREFIX}-king-1updateparents.txt-sentrix --make-bed --out ${PREFIX}-king-1-parents

    # (5.4) YOB and Sex check
    echo ">>> ROUND 1. Pedigree YOB and sex check."
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-1-parents.fam -k 2 -l 2 -v 3 > ${PREFIX}-king-1-children-yob.txt
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-1-children-yob.txt -k 2 -l 3 -v 3 > ${PREFIX}-king-1-children-fathers-yob.txt
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-1-children-fathers-yob.txt -k 2 -l 4 -v 3 > ${PREFIX}-king-1-yob.txt
    rm ${PREFIX}-king-1-children-yob.txt ${PREFIX}-king-1-children-fathers-yob.txt
    awk '{if ($7<$8 || $7<$9) print $0, "PROBLEM"; else print $0, "OK"}' ${PREFIX}-king-1-yob.txt > ${PREFIX}-king-1-yob-check.txt
    awk '$10=="PROBLEM" {print $0}' ${PREFIX}-king-1-yob-check.txt > ${PREFIX}-king-1-yob-problem.txt

    ./match.pl -f ${PREFIX}-king-1-parents.fam -g ${PREFIX}-king-1-parents.fam -k 2 -l 3 -v 5 > ${PREFIX}-king-1-father-sex.txt
    ./match.pl -f ${PREFIX}-king-1-parents.fam -g ${PREFIX}-king-1-father-sex.txt -k 2 -l 4 -v 5 > ${PREFIX}-king-1-sex.txt
    rm ${PREFIX}-king-1-father-sex.txt
    awk '{if ($7==2 || $8==1) print $0, "PROBLEM"; else print $0, "OK"}' ${PREFIX}-king-1-sex.txt > ${PREFIX}-king-1-sex-check.txt
    awk '$10=="PROBLEM" {print $0}' ${PREFIX}-king-1-sex-check.txt > ${PREFIX}-king-1-sex-problem.txt
    wc -l ${PREFIX}-king-1-yob-problem.txt
    wc -l ${PREFIX}-king-1-sex-problem.txt
fi

if $RUN_FALSE; then
    # (5.5) Examine the relationships within families (${PREFIX}-king-1.kin file)
    # Identify any instances where the inferred relationships do not match those reported in MoBa
    echo ">>> ROUND 1. Examine the relationships within families."
    awk '$16>0 {print $0}' ${PREFIX}-king-1.kin > ${PREFIX}-king-1.kin-errors
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-1.kin-errors -k 4 -l 2 -v 8 > ${PREFIX}-king-1.kin-errors-role1
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g  ${PREFIX}-king-1.kin-errors-role1 -k 4 -l 3 -v 8 > ${PREFIX}-king-1.kin-errors
    rm  ${PREFIX}-king-1.kin-errors-role1
    wc -l ${PREFIX}-king-1.kin-errors
    # Identify any specific unexpected relationships
    awk '$15=="Dup/MZ" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-MZ
    wc -l ${PREFIX}-king-1.kin-errors-MZ
    awk '$15=="PO" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-PO
    wc -l ${PREFIX}-king-1.kin-errors-PO
    awk '$15=="FS" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-FS
    wc -l ${PREFIX}-king-1.kin-errors-FS
    awk '$15=="2nd" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-2nd
    wc -l ${PREFIX}-king-1.kin-errors-2nd
    awk '$15=="3rd" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-3rd
    wc -l ${PREFIX}-king-1.kin-errors-3rd
    awk '$15=="4th" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-4th
    wc -l ${PREFIX}-king-1.kin-errors-4th
    awk '$15=="UN" {print $0}' ${PREFIX}-king-1.kin-errors > ${PREFIX}-king-1.kin-errors-UN
    wc -l ${PREFIX}-king-1.kin-errors-UN

    # (5.6) Examine the relationships between families (${PREFIX}-king-1.kin0 file)
    echo ">>> ROUND 1. Examine the relationships between families."
    awk '{if ($14=="Dup/MZ" || $14=="PO" || $14=="FS") print $0}' ${PREFIX}-king-1.kin0 > ${PREFIX}-king-1.kin0-errors
    ./match.pl -f ${RESOURCES_DIR}/genotyped_pedigree_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-1.kin0-errors -k 4 -l 2 -v 8 > ${PREFIX}-king-1.kin0-errors-role1
    ./match.pl -f ${RESOURCES_DIR}/genotyped_pedigree_v${LINKAGE_VERSION}.txt -g  ${PREFIX}-king-1.kin0-errors-role1 -k 4 -l 4 -v 8 > ${PREFIX}-king-1.kin0-errors
    rm  ${PREFIX}-king-1.kin0-errors-role1
    wc -l ${PREFIX}-king-1.kin0-errors
    # identify different kinds of unexpected relationships 
    awk '$14=="Dup/MZ" {print $0}' ${PREFIX}-king-1.kin0-errors > ${PREFIX}-king-1.kin0-errors-MZ
    wc -l ${PREFIX}-king-1.kin0-errors-MZ
    awk '$14=="PO" {print $0}' ${PREFIX}-king-1.kin0-errors > ${PREFIX}-king-1.kin0-errors-PO
    wc -l ${PREFIX}-king-1.kin0-errors-PO
    awk '$14=="FS" {print $0}' ${PREFIX}-king-1.kin0-errors > ${PREFIX}-king-1.kin0-errors-FS
    wc -l ${PREFIX}-king-1.kin0-errors-FS

    # (5.7) Plot relationships
    echo ">>> ROUND 1. Plot relathionships."
    awk '{print $2, $4, $19}' ${PREFIX}-king-1.ibs0 > ${PREFIX}-king-1.ibs0_hist
    Rscript $GITHUB/lib/plot-kinship-histogram.R ${PREFIX}-king-1.ibs0_hist ${PREFIX}-king-1-hist
    sh $GITHUB/tools/create-relplot.sh ${PREFIX}-king-1_relplot.R "${BATCH_LABEL} ${POP}" topright bottomright topright bottomright 
fi

if $RUN_FALSE; then
    # (5.8) Fix within and between family issues
    touch ${PREFIX}-king-1-unexpected-relationships.txt
    touch ${PREFIX}-king-1-fix-ids.txt
    touch ${PREFIX}-king-1-fix-parents.txt
    plink --silent --bfile ${PREFIX}-king-1-parents --remove ${PREFIX}-king-1-unexpected-relationships.txt --update-ids ${PREFIX}-king-1-fix-ids.txt --make-bed --out ${PREFIX}-king-1-fix-ids
    plink --silent --bfile ${PREFIX}-king-1-fix-ids --update-parents ${PREFIX}-king-1-fix-parents.txt --make-bed --out ${PREFIX}-king-1-fix-parents

    ./match.pl -f ${PREFIX}-king-1-fix-parents.fam -g age_v${LINKAGE_VERSION}.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > ${PREFIX}-king-1-fix-parents.cov
    sed -i '1 i FID IID Age' ${PREFIX}-king-1-fix-parents.cov
    /cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b ${PREFIX}-king-1-fix-parents.bed --build --degree 2 --prefix ${PREFIX}-king-1.5 > ${PREFIX}-king-1.5-slurm.txt
    echo "WARNING! Check produced *-king-1.5-slurm.txt file and fix if there are any issues. See (5.9.3) in the protocol."
    # There are no problems remain after this king run. The following step is done just to keep consistent naming with the google doc.
    for ext in bim bed fam; do cp ${PREFIX}-king-1-fix-parents.${ext} ${PREFIX}-king-1.5-fix-parents.${ext}; done
fi

if $RUN_FALSE; then
    # (6) PCA with 1000 Genomes
    echo "ROUND 1. PCA with 1kg."
    plink --silent --bfile ${PREFIX}-king-1.5-fix-parents --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-king-1.5-prune
    plink --silent --bfile ${PREFIX}-king-1.5-fix-parents --extract ${PREFIX}-king-1.5-prune.prune.in --make-bed --out ${PREFIX}-king-1.5-pruned
    plink --silent --bfile ${PREFIX}-king-1.5-pruned --make-set high-ld.txt --write-set --out ${PREFIX}-king-1.5-highld
    plink --silent --bfile ${PREFIX}-king-1.5-pruned --exclude ${PREFIX}-king-1.5-highld.set --make-bed --out ${PREFIX}-king-1.5-trimmed

    # (6.2) Identify SNPs overlapping with 1KG
    cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
    cut -f2 ${PREFIX}-king-1.5-trimmed.bim | sort -s > ${PREFIX}-king-1.5-trimmed.bim.sorted
    join 1kg.bim.sorted ${PREFIX}-king-1.5-trimmed.bim.sorted > ${PREFIX}-1kg-snps.txt
    rm -f 1kg.bim.sorted ${PREFIX}-king-1.5-trimmed.bim.sorted

    # (6.3) Merge with 1kg
    plink --silent --bfile ${PREFIX}-king-1.5-trimmed --extract ${PREFIX}-1kg-snps.txt --make-bed --out ${PREFIX}-1kg-common
    plink --silent --bfile 1kg --extract ${PREFIX}-1kg-snps.txt --make-bed --out 1kg-${PREFIX}-common
    plink --silent --bfile ${PREFIX}-1kg-common --bmerge 1kg-${PREFIX}-common --make-bed --out ${PREFIX}-1kg-merged
    if [[ $? > 0 ]]; then
        plink --silent --bfile 1kg-${PREFIX}-common --flip ${PREFIX}-1kg-merged-merge.missnp --make-bed --out 1kg-${PREFIX}-flip
        plink --silent --bfile ${PREFIX}-1kg-common --bmerge 1kg-${PREFIX}-flip --make-bed --out ${PREFIX}-1kg-second-merged 
        if [[ $? > 0 ]]; then
            plink --silent --bfile ${PREFIX}-1kg-common --exclude ${PREFIX}-1kg-second-merged-merge.missnp --make-bed --out ${PREFIX}-1kg-clean
            plink --silent --bfile 1kg-${PREFIX}-flip --exclude ${PREFIX}-1kg-second-merged-merge.missnp --make-bed --out 1kg-${PREFIX}-clean
            plink --silent --bfile ${PREFIX}-1kg-clean --bmerge 1kg-${PREFIX}-clean --make-bed --out ${PREFIX}-1kg-clean-merged
            for ext in bed bim fam; do cp ${PREFIX}-1kg-clean-merged.${ext} ${PREFIX}-1kg-merged.${ext}; done
        else
            for ext in bed bim fam; do cp ${PREFIX}-1kg-second-merged.${ext} ${PREFIX}-1kg-merged.${ext}; done
        fi
    fi
    
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' ${PREFIX}-1kg-merged.fam > ${PREFIX}-fam-populations.txt
    plink --silent --bfile ${PREFIX}-1kg-merged --pca --within ${PREFIX}-fam-populations.txt --pca-clusters populations.txt --out ${PREFIX}-1kg-pca

    sort -k2 ${PREFIX}-1kg-pca.eigenvec > ${PREFIX}-1kg-pca-sorted 
    a=$(cat ${PREFIX}-king-1.5-trimmed.fam | wc -l)
    head -n $a ${PREFIX}-1kg-pca-sorted > ${PREFIX}-pca-1
    b=$(cat 1kg.fam | wc -l)
    tail -n $b ${PREFIX}-1kg-pca-sorted | sort -k2 > 1kg-${INITIALS}-${POP}-pca-1
    cat ${PREFIX}-pca-1 1kg-${INITIALS}-${POP}-pca-1 > ${PREFIX}-1kg-pca
fi

if $RUN_FALSE; then
    Rscript ${GITHUB}/lib/plot-pca-with-1kg.R ${BATCH_LABEL} ${PREFIX}-1kg-pca bottomright ${PREFIX}-1kg
    Rscript $GITHUB/lib/select-subsamples-on-pca.R ${BATCH_LABEL} ${PREFIX}-1kg-pca ${PREFIX}-selection-2 ${PREFIX}-pca-core-select-custom.txt
    plink --silent --bfile ${PREFIX}-king-1.5-fix-parents --keep ${PREFIX}-selection-2-core-subsample-eur.txt --make-bed --out ${PREFIX}-1-keep
fi

if $RUN_FALSE; then
    # (7) PCA without 1KG
    echo "ROUND 1. PCA without 1kg."
    plink --silent --bfile ${PREFIX}-1-keep --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-1-keep-prune
    plink --silent --bfile ${PREFIX}-1-keep --extract ${PREFIX}-1-keep-prune.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-1-keep-highld
    plink --silent --bfile ${PREFIX}-1-keep --extract ${PREFIX}-1-keep-prune.prune.in --exclude ${PREFIX}-1-keep-highld.set --make-bed --out ${PREFIX}-1-keep-trimmed
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' ${PREFIX}-1-keep-trimmed.fam > ${PREFIX}-1-keep-populations.txt
    plink --silent --bfile ${PREFIX}-1-keep-trimmed --pca --within ${PREFIX}-1-keep-populations.txt --pca-clusters populations.txt --out ${PREFIX}-1-keep-pca
    awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red" }' ${PREFIX}-1-keep.fam > ${PREFIX}-1-keep-fam.txt
    ./match.pl -f ${PREFIX}-1-keep-fam.txt -g ${PREFIX}-1-keep-pca.eigenvec -k 2 -l 2 -v 3 > ${PREFIX}-1-keep-pca-fam.txt
    Rscript $GITHUB/lib/plot-batch-PCs.R ${PREFIX}-1-keep-pca-fam.txt "${BATCH_LABEL} ${POP}, round 1" bottomleft ${PREFIX}-1-pca.png
    # Remove outliers if needed, otherwise just copy previous bfile
    if true; then
        awk '{if($12>-0.3) print($1,$2)}' ${PREFIX}-1-keep-pca.eigenvec > ${PREFIX}-1-pca-keep.txt
        plink --silent --bfile ${PREFIX}-1-keep --keep ${PREFIX}-1-pca-keep.txt --make-bed --out ${PREFIX}-1-round-selection
        awk ' $12>-0.3 {print $0}' ${PREFIX}-1-keep-pca-fam.txt > ${PREFIX}-1-keep-pca-fam-keep.txt
        Rscript $GITHUB/lib/plot-batch-PCs.R ${PREFIX}-1-keep-pca-fam-keep.txt "${BATCH_LABEL} ${POP}, round 1" bottomleft ${PREFIX}-1-pca-keep.png
    else
        echo Warning!!! Selection in PCA without 1kg is disabled.
        for ext in bim bed fam; do cp ${PREFIX}-1-keep.${ext} ${PREFIX}-1-round-selection.${ext}; done
    fi
fi


if $RUN_FALSE; then
    # SECOND ROUND
    echo "ROUND2. Basic QC."
    plink --silent --bfile ${PREFIX}-1-round-selection --maf 0.005 --make-bed --out ${PREFIX}-2-common
    ./match.pl -f ${PREFIX}-2-common.bim -g ${PREFIX}-1-round-selection.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"rare, round 2"}' > ${PREFIX}-2-bad-snps.txt
    plink --silent --bfile ${PREFIX}-2-common --missing --out ${PREFIX}-2-common-missing
    Rscript $GITHUB/lib/plot-missingness-histogram.R ${PREFIX}-2-common-missing "${BATCH_LABEL} ${POP}, round 2"

    plink --silent --bfile ${PREFIX}-2-common --geno 0.05 --make-bed --out ${PREFIX}-2-95
    ./match.pl -f ${PREFIX}-2-95.bim -g ${PREFIX}-2-common.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"call-rate-below-95"}' >> ${PREFIX}-2-bad-snps.txt
    plink --silent --bfile ${PREFIX}-2-95 --geno 0.02 --make-bed --out ${PREFIX}-2-98
    plink --silent --bfile ${PREFIX}-2-98 --geno 0.02 --mind 0.02 --make-bed --out ${PREFIX}-2-call-rates
    ./match.pl -f ${PREFIX}-2-call-rates.bim -g ${PREFIX}-2-95.bim -k 2 -l 2 -v 1| awk '$7=="-" {print $2,"call-rate-below-98"}' >> ${PREFIX}-2-bad-snps.txt
    if [[ -f ${PREFIX}-2-call-rates.irem ]]; then
        awk '{print $1,$2,"call-rate-below-98"}' ${PREFIX}-2-call-rates.irem > ${PREFIX}-2-removed-individuals.txt
    else
        touch ${PREFIX}-2-removed-individuals.txt
    fi
    plink --silent --bfile ${PREFIX}-2-call-rates --hwe 0.000001 --make-bed --out ${PREFIX}-2-basic-qc
    ./match.pl -f ${PREFIX}-2-basic-qc.bim -g ${PREFIX}-2-call-rates.bim -k 2 -l 2 -v 1| awk '$7=="-" {print $2,"out-of-HWE"}' >> ${PREFIX}-2-bad-snps.txt
    plink --silent --bfile ${PREFIX}-2-basic-qc --chr 1-22 --het --missing --out ${PREFIX}-2-common-het-miss
    Rscript $GITHUB/lib/plot-heterozygosity-common.R ${PREFIX}-2-common-het-miss "${BATCH_LABEL} ${POP}, round 2"
    plink --silent --bfile ${PREFIX}-2-basic-qc --remove ${PREFIX}-2-common-het-miss-het-fail.txt --make-bed --out ${PREFIX}-2-het
    awk '{print $1,$2,"heterozygosity"}' ${PREFIX}-2-common-het-miss-het-fail.txt >> ${PREFIX}-2-removed-individuals.txt
    plink --silent --bfile ${PREFIX}-2-het --split-x b37 'no-fail' --make-bed --out ${PREFIX}-2-pseudo
    plink --silent --bfile ${PREFIX}-2-pseudo --check-sex --out ${PREFIX}-2-sexcheck
    plink --silent --bfile ${PREFIX}-2-pseudo --chr 23 --missing --out ${PREFIX}-2-chr23-miss
    ./match.pl -f ${PREFIX}-2-chr23-miss.imiss -g ${PREFIX}-2-sexcheck.sexcheck -k 2 -l 2 -v 6 > ${PREFIX}-2-chr23-plot.txt
    Rscript $GITHUB/lib/plot-sex.R ${PREFIX}-2-chr23-plot.txt "${BATCH_LABEL} ${POP}, round 2" topleft ${PREFIX}-2-sex-plot.png
    awk '$3!=0 && $5=="PROBLEM" {print $0}' ${PREFIX}-2-sexcheck.sexcheck > ${PREFIX}-2-bad-sex.txt
    awk '$3==1 && $6<0.5 || $3==2 && $6>0.5 {print $0}' ${PREFIX}-2-bad-sex.txt > ${PREFIX}-2-erroneous-sex.txt
    touch ${PREFIX}-2-erroneous-sex.txt # create empty if not created in the previous step
    plink --silent --bfile ${PREFIX}-2-het --remove ${PREFIX}-2-erroneous-sex.txt --make-bed --out ${PREFIX}-2-sex
    awk '{print $1,$2,"erroneous-sex-2"}' ${PREFIX}-2-erroneous-sex.txt >> ${PREFIX}-2-removed-individuals.txt
fi

if $RUN_FALSE; then
    # (10) Pedigree build and known relatedness
    echo "ROUND 2. Pedigree build and known relatedness."
    ./match.pl -f ${PREFIX}-2-sex.fam -g age_v${LINKAGE_VERSION}.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > ${PREFIX}-2-sex.cov
    sed -i '1 i FID IID Age' ${PREFIX}-2-sex.cov
    /cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b ${PREFIX}-2-sex.bed --related --ibs --build --degree 2 --rplot --prefix ${PREFIX}-king-2 > ${PREFIX}-king-2-slurm.txt
    if [[ -f ${PREFIX}-king-2updateids.txt ]]; then
        awk '{print $1,$2,$3,$2}' ${PREFIX}-king-2updateids.txt > ${PREFIX}-king-2updateids.txt-sentrix
    else
        touch ${PREFIX}-king-2updateids.txt-sentrix
    fi

    if [[ -s '${PREFIX}-king-2updateparents.txt' ]]; then
        sed -r 's/[^\t]*->//g' ${PREFIX}-king-2updateparents.txt > ${PREFIX}-king-2updateparents.txt-sentrix
    else
        touch ${PREFIX}-king-2updateparents.txt-sentrix
    fi

    plink --silent --bfile ${PREFIX}-2-sex --update-ids ${PREFIX}-king-2updateids.txt-sentrix --make-bed --out ${PREFIX}-king-2-ids
    plink --silent --bfile ${PREFIX}-king-2-ids --update-parents ${PREFIX}-king-2updateparents.txt-sentrix --make-bed --out ${PREFIX}-king-2-parents
fi

if $RUN_FALSE; then
    # (10.4) YOB and Sex check
    echo "ROUND 2. YOB and Sex check."
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-2-parents.fam -k 2 -l 2 -v 3 > ${PREFIX}-king-2-children-yob.txt
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-2-children-yob.txt -k 2 -l 3 -v 3 > ${PREFIX}-king-2-children-fathers-yob.txt
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-2-children-fathers-yob.txt -k 2 -l 4 -v 3 > ${PREFIX}-king-2-yob.txt
    rm ${PREFIX}-king-2-children-yob.txt ${PREFIX}-king-2-children-fathers-yob.txt
    awk '{if ($7<$8 || $7<$9) print $0, "PROBLEM"; else print $0, "OK"}' ${PREFIX}-king-2-yob.txt > ${PREFIX}-king-2-yob-check.txt
    awk '$10=="PROBLEM" {print $0}' ${PREFIX}-king-2-yob-check.txt > ${PREFIX}-king-2-yob-problem.txt

    ./match.pl -f ${PREFIX}-king-2-parents.fam -g ${PREFIX}-king-2-parents.fam -k 2 -l 3 -v 5 > ${PREFIX}-king-2-father-sex.txt
    ./match.pl -f ${PREFIX}-king-2-parents.fam -g ${PREFIX}-king-2-father-sex.txt -k 2 -l 4 -v 5 > ${PREFIX}-king-2-sex.txt
    rm ${PREFIX}-king-2-father-sex.txt
    awk '{if ($7==2 || $8==1) print $0, "PROBLEM"; else print $0, "OK"}' ${PREFIX}-king-2-sex.txt > ${PREFIX}-king-2-sex-check.txt
    awk '$10=="PROBLEM" {print $0}' ${PREFIX}-king-2-sex-check.txt > ${PREFIX}-king-2-sex-problem.txt

    # (10.5) Examine the relationships within families (kin file)
    echo "ROUND 2. Examine the relationships within families (kin file)"
    awk '$16>0 {print $0}' ${PREFIX}-king-2.kin > ${PREFIX}-king-2.kin-errors
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-2.kin-errors -k 4 -l 2 -v 8 > ${PREFIX}-king-2.kin-errors-role1
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g  ${PREFIX}-king-2.kin-errors-role1 -k 4 -l 3 -v 8 > ${PREFIX}-king-2.kin-errors
    rm  ${PREFIX}-king-2.kin-errors-role1
    wc -l ${PREFIX}-king-2.kin-errors
    awk '$15=="Dup/MZ" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-MZ
    wc -l ${PREFIX}-king-2.kin-errors-MZ
    awk '$15=="PO" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-PO
    wc -l ${PREFIX}-king-2.kin-errors-PO
    awk '$15=="FS" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-FS
    wc -l ${PREFIX}-king-2.kin-errors-FS
    awk '$15=="2nd" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-2nd
    wc -l ${PREFIX}-king-2.kin-errors-2nd
    awk '$15=="3rd" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-3rd
    wc -l ${PREFIX}-king-2.kin-errors-3rd
    awk '$15=="4th" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-4th
    wc -l ${PREFIX}-king-2.kin-errors-4th
    awk '$15=="UN" {print $0}' ${PREFIX}-king-2.kin-errors > ${PREFIX}-king-2.kin-errors-UN
    wc -l ${PREFIX}-king-2.kin-errors-UN

    # (10.6) Examine the relationships between families (kin0 file)
    echo "ROUND 2. Examine the relationships between families (kin0 file)."
    awk '{if ($14=="DUP/MZ" || $14=="PO" || $14=="FS") print $0}' ${PREFIX}-king-2.kin0 > ${PREFIX}-king-2.kin0-errors
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-2.kin0-errors -k 4 -l 2 -v 8 > ${PREFIX}-king-2.kin0-errors-role1
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g  ${PREFIX}-king-2.kin0-errors-role1 -k 4 -l 4 -v 8 > ${PREFIX}-king-2.kin0-errors
    rm  ${PREFIX}-king-2.kin0-errors-role1
    wc -l ${PREFIX}-king-2.kin0-errors
    awk '$14=="Dup/MZ" {print $0}' ${PREFIX}-king-2.kin0-errors > ${PREFIX}-king-2.kin0-errors-MZ
    wc -l ${PREFIX}-king-2.kin0-errors-MZ
    awk '$14=="PO" {print $0}' ${PREFIX}-king-2.kin0-errors > ${PREFIX}-king-2.kin0-errors-PO
    wc -l ${PREFIX}-king-2.kin0-errors-PO
    awk '$14=="FS" {print $0}' ${PREFIX}-king-2.kin0-errors > ${PREFIX}-king-2.kin0-errors-FS
    wc -l ${PREFIX}-king-2.kin0-errors-FS

    # (10.7) Plot the relationships
    echo "ROUND 2. Plot the relationships."
    awk '{print $2, $4, $19}' ${PREFIX}-king-2.ibs0 > ${PREFIX}-king-2.ibs0_hist
    Rscript $GITHUB/lib/plot-kinship-histogram.R ${PREFIX}-king-2.ibs0_hist ${PREFIX}-king-2-hist
    rm ${PREFIX}-king-2.ibs0_hist
    sh ${GITHUB}/tools/create-relplot.sh ${PREFIX}-king-2_relplot.R "${BATCH_LABEL} ${POP}, round 2" topright bottomright topright bottomright
fi

if $RUN_FALSE; then
    # WARNING! The following assumes no issues with relatedness. If there are any issues the following steps should be changed. See steps (10.8) and (10.9) the protocol.
    # (10.8) Fix within and between family issues
    # No unexpected relationships have to be fixed. So just copy/rename to have consistent naming with googledoc.
    for ext in bim fam bed; do cp ${PREFIX}-king-2-parents.${ext} ${PREFIX}-king-2-fix-parents.${ext}; done

    # (10.9) Identify any pedigree issues
    echo "ROUND 2. Identify any pedigree issues."
    ./match.pl -f ${PREFIX}-king-2-fix-parents.fam -g age_v${LINKAGE_VERSION}.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > ${PREFIX}-king-2-fix-parents.cov
    sed -i '1 i FID IID Age' ${PREFIX}-king-2-fix-parents.cov
    /cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b ${PREFIX}-king-2-fix-parents.bed --build --degree 2 --prefix ${PREFIX}-king-2.5 > ${PREFIX}-king-2.5-slurm.txt

    # Nothing to fix, just copy
    for ext in bed bim fam; do cp ${PREFIX}-king-2-fix-parents.${ext} ${PREFIX}-king-2.5-fix-parents.${ext}; done

fi


if $RUN_FALSE; then
    # (11) Cryptic relatedness
    echo "ROUND 2. Cryptic relatedness."
    ./cryptic.sh ${PREFIX}-king-2.ibs0 ${PREFIX}-cryptic-2
    Rscript $GITHUB/lib/plot-cryptic.R ${PREFIX}-cryptic-2-kinship-sum.txt ${PREFIX}-cryptic-2-counts.txt "${BATCH_LABEL} ${POP}" ${PREFIX}-cryptic-2
    if true; then
        # Remove Cryptic relatedness outliers
        echo Warning!!! Cryptic relatedness filtering is done, please ensure the threshold is correct!
        CRYPTIC_THRESHOLD_R2=9
        awk -v threshold=$CRYPTIC_THRESHOLD_R2 '$2>threshold {print $1}' ${PREFIX}-cryptic-2-kinship-sum.txt > ${PREFIX}-cryptic-2-sum-remove
        awk -v threshold=$CRYPTIC_THRESHOLD_R2 '$2<=threshold {print $0}' ${PREFIX}-cryptic-2-kinship-sum.txt > ${PREFIX}-cryptic-2-kinship-sum-filtered.txt
        join -1 1 -2 1 <(cut -f1 -d' ' ${PREFIX}-cryptic-2-kinship-sum-filtered.txt | sort) <(sort -k1,1 ${PREFIX}-cryptic-2-counts.txt) > ${PREFIX}-cryptic-2-counts-filtered.txt
        Rscript $GITHUB/lib/plot-cryptic.R ${PREFIX}-cryptic-2-kinship-sum-filtered.txt ${PREFIX}-cryptic-2-counts-filtered.txt "${BATCH_LABEL} ${POP}" ${PREFIX}-cryptic-2-filtered
        ./match.pl -f ${PREFIX}-king-2.5-fix-parents.fam -g ${PREFIX}-cryptic-2-sum-remove -k 2 -l 1 -v 1 | awk '{print $2, $1}' > ${PREFIX}-cryptic-2-sum-remove.txt
        plink --silent --bfile ${PREFIX}-king-2.5-fix-parents --remove ${PREFIX}-cryptic-2-sum-remove.txt --make-bed --out ${PREFIX}-cryptic-clean-2
        ./match.pl -f ${PREFIX}-king-2.5-fix-parents.fam -g ${PREFIX}-cryptic-clean-2.fam -k 2 -l 2 -v 1 | awk '$7=="-" {print $1,$2,"cryptic relatedness, round 2"}' >> ${PREFIX}-2-removed-individuals.txt
    else
        # Nothing to remove because of cryptic relatedness. Copy/rename to keep consistent naming.
        echo Warning!!! Cryptic relatedness filtering is disabled.
        for ext in bed bim fam; do cp ${PREFIX}-king-2.5-fix-parents.${ext} ${PREFIX}-cryptic-clean-2.${ext}; done
    fi

    # (12) Mendelian errors
    echo "ROUND 2. Mendelian errors."
    plink --silent --bfile ${PREFIX}-cryptic-clean-2 --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out ${PREFIX}-me-clean-sex-2
    awk '$3==0 {print $1,$2,$4}' ${PREFIX}-2-sexcheck.sexcheck > ${PREFIX}-2-sex-me.txt
    plink --silent --bfile ${PREFIX}-cryptic-clean-2 --update-sex ${PREFIX}-2-sex-me.txt --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out ${PREFIX}-me-clean-2
    awk '{print $1,$2,0}' ${PREFIX}-2-sex-me.txt > ${PREFIX}-2-sex-me-back.txt
    plink --silent --bfile ${PREFIX}-me-clean-2 --update-sex ${PREFIX}-2-sex-me-back.txt --make-bed --out ${PREFIX}-me-clean-sex-2
    ./match.pl -f ${PREFIX}-me-clean-sex-2.fam -g ${PREFIX}-cryptic-clean-2.fam -k 2 -l 2 -v 1 | awk '$7=="-" {print $1,$2,"Mendelian-error"}' >> ${PREFIX}-2-removed-individuals.txt
    ./match.pl -f ${PREFIX}-me-clean-sex-2.bim -g ${PREFIX}-cryptic-clean-2.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"Mendelian-error"}' >> ${PREFIX}-2-bad-snps.txt

fi

if $RUN_FALSE; then
    # (13) PCA with 1KG
    echo "ROUND 2. PCA with 1KG."
    plink --silent --bfile ${PREFIX}-me-clean-sex-2 --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-me-clean-sex-2-indep
    plink --silent --bfile ${PREFIX}-me-clean-sex-2 --extract ${PREFIX}-me-clean-sex-2-indep.prune.in --make-bed --out ${PREFIX}-me-clean-sex-2-pruned
    plink --silent --bfile ${PREFIX}-me-clean-sex-2-pruned --make-set high-ld.txt --write-set --out ${PREFIX}-me-clean-sex-2-highld
    plink --silent --bfile ${PREFIX}-me-clean-sex-2-pruned --exclude ${PREFIX}-me-clean-sex-2-highld.set --make-bed --out ${PREFIX}-me-clean-sex-2-trimmed
    cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
    cut -f2 ${PREFIX}-me-clean-sex-2-trimmed.bim | sort -s > ${PREFIX}-me-clean-sex-2-trimmed.bim.sorted
    join 1kg.bim.sorted ${PREFIX}-me-clean-sex-2-trimmed.bim.sorted > ${PREFIX}-me-clean-sex-2-1kg-snps.txt
    rm ${PREFIX}-me-clean-sex-2-trimmed.bim.sorted
    plink --silent --bfile ${PREFIX}-me-clean-sex-2-trimmed --extract ${PREFIX}-me-clean-sex-2-1kg-snps.txt --make-bed --out ${PREFIX}-me-clean-sex-2-1kg-common
    plink --silent --bfile 1kg --extract ${PREFIX}-me-clean-sex-2-1kg-snps.txt --make-bed --out 1kg-${PREFIX}-me-clean-sex-2-common
    plink --silent --bfile ${PREFIX}-me-clean-sex-2-1kg-common --bmerge 1kg-${PREFIX}-me-clean-sex-2-common --make-bed --out ${PREFIX}-me-clean-sex-2-1kg-merged
    if [[ $? > 0 ]]; then
        plink --silent --bfile 1kg-${PREFIX}-me-clean-sex-2-common --flip ${PREFIX}-me-clean-sex-2-1kg-merged-merge.missnp --make-bed --out 1kg-${PREFIX}-me-clean-sex-2-common-flip
        plink --silent --bfile ${PREFIX}-me-clean-sex-2-1kg-common --bmerge 1kg-${PREFIX}-me-clean-sex-2-common-flip --make-bed --out ${PREFIX}-me-clean-sex-2-1kg-second-merged
        if [[ $? > 0 ]]; then
            plink --silent --bfile ${PREFIX}-me-clean-sex-2-1kg-common --exclude ${PREFIX}-me-clean-sex-2-1kg-second-merged-merge.missnp --make-bed --out ${PREFIX}-me-clean-sex-2-1kg-common-clean
            plink --silent --bfile 1kg-${PREFIX}-me-clean-sex-2-common-flip --exclude ${PREFIX}-me-clean-sex-2-1kg-second-merged-merge.missnp --make-bed --out 1kg-${PREFIX}-me-clean-sex-2-common-flip-clean
            plink --silent --bfile ${PREFIX}-me-clean-sex-2-1kg-common-clean --bmerge 1kg-${PREFIX}-me-clean-sex-2-common-flip-clean --make-bed --out ${PREFIX}-me-clean-sex-2-1kg-clean-merged
            for ext in bed bim fam; do cp ${PREFIX}-me-clean-sex-2-1kg-clean-merged.${ext} ${PREFIX}-me-clean-sex-2-1kg-merged.${ext}; done
        else
            for ext in bed bim fam; do cp ${PREFIX}-me-clean-sex-2-1kg-second-merged.${ext} ${PREFIX}-me-clean-sex-2-1kg-merged.${ext}; done
        fi
    fi

    # (13.4) PCA
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}'  ${PREFIX}-me-clean-sex-2-1kg-merged.fam > ${PREFIX}-me-clean-sex-2-fam-populations.txt
    plink --silent --bfile ${PREFIX}-me-clean-sex-2-1kg-merged --pca --within ${PREFIX}-me-clean-sex-2-fam-populations.txt --pca-clusters populations.txt --out ${PREFIX}-me-clean-sex-2-1kg-pca
    sort -k2 ${PREFIX}-me-clean-sex-2-1kg-pca.eigenvec > ${PREFIX}-me-clean-sex-2-1kg-pca-sorted
    a=$(cat ${PREFIX}-me-clean-sex-2-trimmed.fam | wc -l)
    head -n $a ${PREFIX}-me-clean-sex-2-1kg-pca-sorted > ${PREFIX}-me-clean-sex-2-1kg-pca-1
    b=$(cat 1kg.fam | wc -l)
    tail -n $b ${PREFIX}-me-clean-sex-2-1kg-pca-sorted | sort -k2 > 1kg-initials-eur-2-pca-1
    cat ${PREFIX}-me-clean-sex-2-1kg-pca-1 1kg-initials-eur-2-pca-1 > ${PREFIX}-me-clean-sex-2-1kg-pca
fi

if $RUN_FALSE; then
    Rscript ${GITHUB}/lib/plot-pca-with-1kg.R ${BATCH_LABEL} ${PREFIX}-me-clean-sex-2-1kg-pca bottomright ${PREFIX}-me-clean-sex-2-1kg
    Rscript $GITHUB/lib/select-subsamples-on-pca.R ${BATCH_LABEL} ${PREFIX}-me-clean-sex-2-1kg-pca ${PREFIX}-selection-3 ${PREFIX}-pca-core-select-3-custom.txt
    # (13.6) Remove ancestry outliers if needed, else just copy to keep naming consistent
    for ext in bim bed fam; do cp ${PREFIX}-me-clean-sex-2.${ext} ${PREFIX}-3-keep.${ext}; done
fi

if $RUN_FALSE; then
    # (14) PCA without 1KG
    echo "ROUND 2. PCA without 1KG."
    plink --silent --bfile ${PREFIX}-3-keep --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-3-keep-indep
    plink --silent --bfile ${PREFIX}-3-keep --extract ${PREFIX}-3-keep-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-3-keep-highld
    plink --silent --bfile ${PREFIX}-3-keep --extract ${PREFIX}-3-keep-indep.prune.in --exclude ${PREFIX}-3-keep-highld.set --make-bed --out ${PREFIX}-3-trimmed
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' ${PREFIX}-3-trimmed.fam > ${PREFIX}-3-populations.txt
    plink --silent --bfile ${PREFIX}-3-trimmed --pca --within ${PREFIX}-3-populations.txt --pca-clusters populations.txt --out ${PREFIX}-3-pca

    awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red" }' ${PREFIX}-3-keep.fam > ${PREFIX}-3-keep-fam.txt
    ./match.pl -f ${PREFIX}-3-keep-fam.txt -g ${PREFIX}-3-pca.eigenvec -k 2 -l 2 -v 3 > ${PREFIX}-3-keep-pca-fam.txt
fi

if $RUN_FALSE; then
    Rscript ${GITHUB}/lib/plot-batch-PCs.R ${PREFIX}-3-keep-pca-fam.txt "${BATCH_LABEL} ${POP}, round 2" topright ${PREFIX}-3-pca.png
    # (14.4) Remove PC outliers
    # Remove outliers if needed, otherwise just copy previous bfile
    if false; then
        awk '{if($12<0.2 && $11<0.15) print($1,$2)}' ${PREFIX}-3-pca.eigenvec > ${PREFIX}-3-pca-keep.txt
        plink --silent --bfile ${PREFIX}-3-keep --keep ${PREFIX}-3-pca-keep.txt --make-bed --out ${PREFIX}-2-round-selection
        awk ' $12<0.2 && $11<0.15 {print $0}' ${PREFIX}-3-keep-pca-fam.txt > ${PREFIX}-3-keep-pca-fam-keep.txt
        Rscript $GITHUB/lib/plot-batch-PCs.R ${PREFIX}-3-keep-pca-fam-keep.txt "${BATCH_LABEL} ${POP}, round 2" bottomleft ${PREFIX}-3-pca-keep.png
    else
        echo Warning!!! Selection in PCA without 1kg is disabled.
        for ext in bim bed fam; do cp ${PREFIX}-3-keep.${ext} ${PREFIX}-2-round-selection.${ext}; done
    fi

fi


if $RUN_FALSE; then
    # (15) Plate effects.
    echo "ROUND 2. Plate effects."
    plink --silent --bfile ${PREFIX}-2-round-selection --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-2-round-indep
    plink --silent --bfile ${PREFIX}-2-round-selection --extract ${PREFIX}-2-round-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-2-round-highld
    plink --silent --bfile ${PREFIX}-2-round-selection --extract ${PREFIX}-2-round-indep.prune.in --exclude ${PREFIX}-2-round-highld.set --make-bed --out ${PREFIX}-2-round-trimmed
    plink --silent --bfile ${PREFIX}-2-round-trimmed --pca --within ${PREFIX}-3-populations.txt --pca-clusters populations.txt --out ${PREFIX}-2-round-pca
    ./match.pl -f GSA-plates.txt -g ${PREFIX}-2-round-pca.eigenvec -k 1 -l 2 -v 3 | awk '$23!="-" {print $0}' | sort -k23 > ${PREFIX}-3-pca-plates.txt
    awk '{print $1,$2,$23}' ${PREFIX}-3-pca-plates.txt > ${PREFIX}-3-plate-groups.txt
    Rscript ${GITHUB}/lib/plot-PC-by-plate.R ${PREFIX}-3-pca-plates.txt "${BATCH_LABEL} ${POP}, round 2" ${PREFIX}-3

    Rscript ${GITHUB}/lib/anova-for-PC-vs-plates.R ${PREFIX}-3-pca-plates.txt ${PREFIX}-3-pca-anova-results.txt

    plink --silent --bfile ${PREFIX}-2-round-selection --filter-founders --chr 1-22 --pheno ${PREFIX}-2-round-selection.fam --mpheno 3 --within ${PREFIX}-3-plate-groups.txt --mh2 --out ${PREFIX}-3-mh-plates
    Rscript ${GITHUB}/lib/plot-qqplot.R ${PREFIX}-3-mh-plates.cmh2 "${BATCH_LABEL} ${POP}, round 2" 5 ${PREFIX}-3-mh-plates-qq-plot
    sort -k5 -g ${PREFIX}-3-mh-plates.cmh2 | grep -v "NA" > ${PREFIX}-3-mh2-plates-sorted
    awk '$5<0.001 {print $2}' ${PREFIX}-3-mh2-plates-sorted > ${PREFIX}-3-mh2-plates-significant
    plink --silent --bfile ${PREFIX}-2-round-selection --exclude ${PREFIX}-3-mh2-plates-significant --make-bed --out ${PREFIX}-3-batch
    awk '{print $1,"plate-effect, round 2"}' ${PREFIX}-3-mh2-plates-significant >> ${PREFIX}-2-bad-snps.txt

    # (15.5) Re-run PCA
    plink --silent --bfile ${PREFIX}-3-batch --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-3-batch-indep
    plink --silent --bfile ${PREFIX}-3-batch --extract ${PREFIX}-3-batch-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-3-batch-highld
    plink --silent --bfile ${PREFIX}-3-batch --extract ${PREFIX}-3-batch-indep.prune.in --exclude ${PREFIX}-3-batch-highld.set --make-bed --out ${PREFIX}-3-batch-trimmed
    plink --silent --bfile ${PREFIX}-3-batch-trimmed --pca --within ${PREFIX}-3-populations.txt --pca-clusters populations.txt --out ${PREFIX}-3-batch-pca

    # (15.6) Re-run ANOVA
    ./match.pl -f GSA-plates.txt -g ${PREFIX}-3-batch-pca.eigenvec -k 1 -l 2 -v 3 | awk '$23!="-" {print $0}' | sort -k23 > ${PREFIX}-3-batch-pca-plates.txt
    Rscript ${GITHUB}/lib/anova-for-PC-vs-plates.R ${PREFIX}-3-batch-pca-plates.txt ${PREFIX}-3-batch-pca-anova-results.txt
fi

if $RUN_FALSE; then
    # THIRD ROUND
    echo "ROUND 3. Basic QC."
    plink --silent --bfile ${PREFIX}-3-batch --chr 1-22 --make-bed --out ${PREFIX}-round-3
    ./match.pl -f ${PREFIX}-round-3.bim -g ${PREFIX}-3-batch.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"sex chromosome, round 3"}' > ${PREFIX}-3-bad-snps.txt
    plink --silent --bfile ${PREFIX}-round-3 --chr 1-22 --maf 0.005 --make-bed --out ${PREFIX}-3-common
    ./match.pl -f ${PREFIX}-3-common.bim -g ${PREFIX}-round-3.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"rare, round 3"}' >> ${PREFIX}-3-bad-snps.txt
    plink --silent --bfile ${PREFIX}-3-common --missing --out ${PREFIX}-3-missing
    Rscript ${GITHUB}/lib/plot-missingness-histogram.R ${PREFIX}-3-missing "tag population, round 3"
    plink --silent --bfile ${PREFIX}-3-common --geno 0.05 --make-bed --out ${PREFIX}-3-95
    ./match.pl -f ${PREFIX}-3-95.bim -g ${PREFIX}-3-common.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"call-rate-below-95, round 3"}' >> ${PREFIX}-3-bad-snps.txt
    plink --silent --bfile ${PREFIX}-3-95 --geno 0.02 --make-bed --out ${PREFIX}-3-98
    plink --silent --bfile ${PREFIX}-3-98 --geno 0.02 --mind 0.02 --make-bed --out ${PREFIX}-3-call-rates
    ./match.pl -f ${PREFIX}-3-call-rates.bim -g ${PREFIX}-3-95.bim -k 2 -l 2 -v 1| awk '$7=="-" {print $2,"call-rate-below-98, round 3"}' >> ${PREFIX}-3-bad-snps.txt
    if [[ -f ${PREFIX}-3-call-rates.irem ]]; then
        awk '{print $1,$2,"call-rate-below-98, round 3"}' ${PREFIX}-3-call-rates.irem > ${PREFIX}-3-removed-individuals.txt
    else
        rm -f ${PREFIX}-3-removed-individuals.txt # in case you run this section multiple times
        touch ${PREFIX}-3-removed-individuals.txt
    fi
    plink --silent --bfile ${PREFIX}-3-call-rates --hwe 0.000001 --make-bed --out ${PREFIX}-3-basic-qc
    ./match.pl -f ${PREFIX}-3-basic-qc.bim -g ${PREFIX}-3-call-rates.bim -k 2 -l 2 -v 1| awk '$7=="-" {print $2,"out-of-HWE, round 3"}' >> ${PREFIX}-3-bad-snps.txt
    plink --silent --bfile ${PREFIX}-3-basic-qc --het --missing --out ${PREFIX}-3-common-het-miss
    Rscript $GITHUB/lib/plot-heterozygosity-common.R ${PREFIX}-3-common-het-miss "${BATCH_LABEL} ${POP}, round 3"
    plink --silent --bfile ${PREFIX}-3-basic-qc --remove ${PREFIX}-3-common-het-miss-het-fail.txt --make-bed --out ${PREFIX}-3-het
    awk '{print $1,$2,"heterozygosity, round 3"}' ${PREFIX}-3-common-het-miss-het-fail.txt >> ${PREFIX}-3-removed-individuals.txt
fi

if $RUN_FALSE; then
    # (17) Pedigree build and known relatedness
    echo "ROUND 3. Pedigree build and known relatedness."
    ./match.pl -f ${PREFIX}-3-het.fam -g age_v${LINKAGE_VERSION}.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > ${PREFIX}-3-het.cov
    sed -i '1 i\FID IID Age' ${PREFIX}-3-het.cov
    /cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b ${PREFIX}-3-het.bed --related --ibs  --build --degree 2 --rplot --prefix ${PREFIX}-king-3 > ${PREFIX}-king-3-slurm.txt

    if [[ -f ${PREFIX}-king-3updateids.txt ]]; then
        awk '{print $1,$2,$3,$2}' ${PREFIX}-king-3updateids.txt > ${PREFIX}-king-3updateids.txt-sentrix
    else
        touch ${PREFIX}-king-3updateids.txt-sentrix
    fi
    if [[ -s '${PREFIX}-king-3updateparents.txt' ]]; then
        sed -r 's/[^\t]*->//g' ${PREFIX}-king-3updateparents.txt > ${PREFIX}-king-3updateparents.txt-sentrix
    else
        touch ${PREFIX}-king-3updateparents.txt-sentrix
    fi
    plink --silent --bfile ${PREFIX}-3-het --update-ids ${PREFIX}-king-3updateids.txt-sentrix --make-bed --out ${PREFIX}-king-3-ids
    plink --silent --bfile ${PREFIX}-king-3-ids --update-parents ${PREFIX}-king-3updateparents.txt-sentrix --make-bed --out ${PREFIX}-king-3-parents

    # (17.4) YOB and Sex check
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-3-parents.fam -k 2 -l 2 -v 3 > ${PREFIX}-king-3-children-yob.txt
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-3-children-yob.txt -k 2 -l 3 -v 3 > ${PREFIX}-king-3-children-fathers-yob.txt
    ./match.pl -f yob_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-3-children-fathers-yob.txt -k 2 -l 4 -v 3 > ${PREFIX}-king-3-yob.txt
    rm ${PREFIX}-king-3-children-yob.txt ${PREFIX}-king-3-children-fathers-yob.txt
    awk '{if ($7<$8 || $7<$9) print $0, "PROBLEM"; else print $0, "OK"}' ${PREFIX}-king-3-yob.txt > ${PREFIX}-king-3-yob-check.txt
    awk '$10=="PROBLEM" {print $0}' ${PREFIX}-king-3-yob-check.txt > ${PREFIX}-king-3-yob-problem.txt

    ./match.pl -f ${PREFIX}-king-3-parents.fam -g ${PREFIX}-king-3-parents.fam -k 2 -l 3 -v 5 > ${PREFIX}-king-3-father-sex.txt
    ./match.pl -f ${PREFIX}-king-3-parents.fam -g ${PREFIX}-king-3-father-sex.txt -k 2 -l 4 -v 5 > ${PREFIX}-king-3-sex.txt
    rm ${PREFIX}-king-3-father-sex.txt
    awk '{if ($7==2 || $8==1) print $0, "PROBLEM"; else print $0, "OK"}' ${PREFIX}-king-3-sex.txt > ${PREFIX}-king-3-sex-check.txt
    awk '$10=="PROBLEM" {print $0}' ${PREFIX}-king-3-sex-check.txt > ${PREFIX}-king-3-sex-problem.txt

    wc -l ${PREFIX}-king-3-yob-problem.txt
    wc -l ${PREFIX}-king-3-sex-problem.txt

    # (17.5) Examine the relationships within families (kin file)
    awk '$16>0 {print $0}' ${PREFIX}-king-3.kin > ${PREFIX}-king-3.kin-errors
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-3.kin-errors -k 4 -l 2 -v 8 > ${PREFIX}-king-3.kin-errors-role1
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g  ${PREFIX}-king-3.kin-errors-role1 -k 4 -l 3 -v 8 > ${PREFIX}-king-3.kin-errors
    rm  ${PREFIX}-king-3.kin-errors-role1
    wc -l ${PREFIX}-king-3.kin-errors

    awk '$15=="Dup/MZ" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-MZ
    wc -l ${PREFIX}-king-3.kin-errors-MZ
    awk '$15=="PO" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-PO
    wc -l ${PREFIX}-king-3.kin-errors-PO
    awk '$15=="FS" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-FS
    wc -l ${PREFIX}-king-3.kin-errors-FS
    awk '$15=="2nd" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-2nd
    wc -l ${PREFIX}-king-3.kin-errors-2nd
    awk '$15=="3rd" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-3rd
    wc -l ${PREFIX}-king-3.kin-errors-3rd
    awk '$15=="4th" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-4th
    wc -l ${PREFIX}-king-3.kin-errors-4th
    awk '$15=="UN" {print $0}' ${PREFIX}-king-3.kin-errors > ${PREFIX}-king-3.kin-errors-UN
    wc -l ${PREFIX}-king-3.kin-errors-UN

    # (17.6) Examine the relationships between families (kin0 file)
    awk '{if ($14=="DUP/MZ" || $14=="PO" || $14=="FS") print $0}' ${PREFIX}-king-3.kin0 > ${PREFIX}-king-3.kin0-errors
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g ${PREFIX}-king-3.kin0-errors -k 4 -l 2 -v 8 > ${PREFIX}-king-3.kin0-errors-role1
    ./match.pl -f genotyped_pedigree_v${LINKAGE_VERSION}.txt -g  ${PREFIX}-king-3.kin0-errors-role1 -k 4 -l 4 -v 8 > ${PREFIX}-king-3.kin0-errors
    rm  ${PREFIX}-king-3.kin0-errors-role1
    wc -l ${PREFIX}-king-3.kin0-errors

    awk '$14=="Dup/MZ" {print $0}' ${PREFIX}-king-3.kin0-errors > ${PREFIX}-king-3.kin0-errors-MZ
    wc -l ${PREFIX}-king-3.kin0-errors-MZ
    awk '$14=="PO" {print $0}' ${PREFIX}-king-3.kin0-errors > ${PREFIX}-king-3.kin0-errors-PO
    wc -l ${PREFIX}-king-3.kin0-errors-PO
    awk '$14=="FS" {print $0}' ${PREFIX}-king-3.kin0-errors > ${PREFIX}-king-3.kin0-errors-FS
    wc -l ${PREFIX}-king-3.kin0-errors-FS

    awk '{print $2, $4, $19}' ${PREFIX}-king-3.ibs0 > ${PREFIX}-king-3.ibs0_hist
    Rscript $GITHUB/lib/plot-kinship-histogram.R ${PREFIX}-king-3.ibs0_hist ${PREFIX}-king-3-hist
    rm ${PREFIX}-king-3.ibs0_hist
    sh ${GITHUB}/tools/create-relplot.sh ${PREFIX}-king-3_relplot.R "${BATCH_LABEL} ${POP}, round 3" topright bottomright topright bottomright

    # No unexpected relationships have to be fixed. So just copy/rename to have consistent naming with googledoc.
    for ext in bim fam bed; do cp ${PREFIX}-king-3-parents.${ext} ${PREFIX}-king-3-fix-parents.${ext}; done

    # (17.9) Identify any pedigree issues
    echo "ROUND 3. Identify any pedigree issues."
    ./match.pl -f ${PREFIX}-king-3-fix-parents.fam -g age_v${LINKAGE_VERSION}.txt -k 2 -l 2 -v 1 | awk '$4!="-" {print $4, $2, $3}' > ${PREFIX}-king-3-fix-parents.cov
    sed -i '1 i FID IID Age' ${PREFIX}-king-3-fix-parents.cov
    /cluster/projects/p697/projects/moba_qc_imputation/software/king225 -b ${PREFIX}-king-3-fix-parents.bed --build --degree 2 --prefix ${PREFIX}-king-3.5 > ${PREFIX}-king-3.5-slurm.txt

    # Nothing to fix, just copy
    for ext in bed bim fam; do cp ${PREFIX}-king-3-fix-parents.${ext} ${PREFIX}-king-3.5-fix-parents.${ext}; done
fi

if $RUN_FALSE; then
    # (18) IBD estimation
    echo "ROUND 3. IBD estimation."
    plink --silent --bfile ${PREFIX}-king-3.5-fix-parents --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-king-3.5-indep
    plink --silent --bfile ${PREFIX}-king-3.5-fix-parents --extract ${PREFIX}-king-3.5-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-king-3.5-highld
    plink --silent --bfile ${PREFIX}-king-3.5-fix-parents --extract ${PREFIX}-king-3.5-indep.prune.in --exclude ${PREFIX}-king-3.5-highld.set --make-bed --out ${PREFIX}-king-3.5-trimmed
    wc -l ${PREFIX}-king-3.5-indep.prune.in
    cat ${PREFIX}-king-3.5-highld.set | grep -v hild | grep -v END | grep -v "^$" | wc -l
    wc -l ${PREFIX}-king-3.5-trimmed.bim

    plink --silent --bfile ${PREFIX}-king-3.5-trimmed --genome --out ${PREFIX}-king-3-ibd

    awk '{print $5,$7,$8,$10}' ${PREFIX}-king-3-ibd.genome > ${PREFIX}-king-3-ibd.csv
    Rscript ${GITHUB}/lib/plot-ibd.R ${PREFIX}-king-3-ibd.csv "${BATCH_LABEL} ${POP}, round 3"

    # (18.4) Check IBD patterns are as expected.
    awk '$5=="PO" && $10<0.4 || $5=="PO" && $10>0.6 {print $0}' ${PREFIX}-king-3-ibd.genome > ${PREFIX}-king-3-ibd-bad-parents.txt
    awk '$5=="FS" && $10<0.4 || $5=="FS" && $10>0.6 {print $0}' ${PREFIX}-king-3-ibd.genome > ${PREFIX}-king-3-ibd-bad-siblings.txt
    awk '$5=="HS" && $10<0.15 || $5=="HS" && $10>0.35 {print $0}' ${PREFIX}-king-3-ibd.genome > ${PREFIX}-king-3-ibd-bad-half-siblings.txt
    awk '$5!="PO" && $5!="FS" && $5!="HS" && $10>0.15 {print $0}' ${PREFIX}-king-3-ibd.genome > ${PREFIX}-king-3-ibd-bad-unrelated.txt
    touch ${PREFIX}-king-3-ibd-bad-relatedness.txt # create an empty file. Required if all of abd-unrelated/parents/siblings are empty.
    cat ${PREFIX}-king-3-ibd-bad-unrelated.txt ${PREFIX}-king-3-ibd-bad-parents.txt ${PREFIX}-king-3-ibd-bad-siblings.txt ${PREFIX}-king-3-ibd-bad-half-siblings.txt > ${PREFIX}-king-3-ibd-bad-relatedness.txt
    rm ${PREFIX}-king-3-ibd-bad-unrelated.txt ${PREFIX}-king-3-ibd-bad-parents.txt ${PREFIX}-king-3-ibd-bad-siblings.txt ${PREFIX}-king-3-ibd-bad-half-siblings.txt
    awk '{print $2,$3,$15}' ${PREFIX}-king-3.kin > ${PREFIX}-king-3.kin-RT
    awk '{print $2,$4,$14}' ${PREFIX}-king-3.kin0 > ${PREFIX}-king-3.kin0-RT
    cat ${PREFIX}-king-3.kin-RT ${PREFIX}-king-3.kin0-RT > ${PREFIX}-king-3.RT
    rm ${PREFIX}-king-3.kin-RT ${PREFIX}-king-3.kin0-RT
    
    # (18.4.3) Merge pairwise bad relatedness list with the KING inferred relatedness type
    echo '
bad <- read.table("'${PREFIX}-king-3-ibd-bad-relatedness.txt'",h=T,colClasses="character")
bad_match <- subset(bad, FID1==FID2)
bad_nonmatch <- subset(bad, FID1!=FID2)
rm(bad)
kin <- read.table("'${PREFIX}-king-3.RT'",h=T)
colnames(kin) <- c("IID1","IID2","InfType")
bad_kin1 <- merge(bad_match, kin, by=c("IID1", "IID2"))
bad_kin2 <- merge(bad_match, kin, by.x=c("IID1", "IID2"), by.y=c("IID2", "IID1"))
bad_kin <- rbind(bad_kin1, bad_kin2)
rm(bad_kin1, bad_kin2)
table(bad_kin$InfType)
bad_kin <- bad_kin[,c(3,1,4,2,5:15)]
write.table(bad_kin, "'${PREFIX}-king-3-ibd-bad-relatedness.txt-InfType'",row.names=F, col.names=T, sep="\t", quote=F)
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
write.table(bad_nonmatch, "'${PREFIX}-king-3-ibd-bad-relatedness.txt-Freq'",row.names=F, col.names=T, sep="\t", quote=F)
rm(bad_nonmatch)
q()
' | R --vanilla

    plink --silent --bfile ${PREFIX}-king-3-fix-parents --missing --out ${PREFIX}-king-3-missing
    ./match.pl -f ${PREFIX}-king-3-missing.imiss -g ${PREFIX}-king-3-ibd-bad-relatedness.txt-InfType -k 2 -l 2 -v 6 > ${PREFIX}-king-3-ibd-bad-relatedness.txt-InfType-call-rate1
    ./match.pl -f ${PREFIX}-king-3-missing.imiss -g ${PREFIX}-king-3-ibd-bad-relatedness.txt-InfType-call-rate1 -k 2 -l 4 -v 6 > ${PREFIX}-king-3-ibd-bad-relatedness.txt-InfType-call-rate
    ./match.pl -f ${PREFIX}-king-3-missing.imiss -g ${PREFIX}-king-3-ibd-bad-relatedness.txt-Freq -k 2 -l 2 -v 6 > ${PREFIX}-king-3-ibd-bad-relatedness.txt-Freq-call-rate1
    ./match.pl -f ${PREFIX}-king-3-missing.imiss -g ${PREFIX}-king-3-ibd-bad-relatedness.txt-Freq-call-rate1 -k 2 -l 4 -v 6 > ${PREFIX}-king-3-ibd-bad-relatedness.txt-Freq-call-rate
    rm ${PREFIX}-king-3-ibd-bad-relatedness.txt-InfType-call-rate1 ${PREFIX}-king-3-ibd-bad-relatedness.txt-Freq-call-rate1

fi

if $RUN_FALSE; then
    # create empty *-low-call-rate.txt and *-update-parents.txt files if do not exist
    touch ${PREFIX}-king-3-bad-relatedness-low-call-rate.txt
    touch ${PREFIX}-king-3-bad-relatedness-update-parents.txt
    plink --silent --bfile ${PREFIX}-king-3.5-fix-parents --update-parents ${PREFIX}-king-3-bad-relatedness-update-parents.txt --remove ${PREFIX}-king-3-bad-relatedness-low-call-rate.txt --make-bed --out ${PREFIX}-king-3-ibd-clean
    awk '{print $1,$2,"IBD, round 3"}' ${PREFIX}-king-3-bad-relatedness-low-call-rate.txt >> ${PREFIX}-3-removed-individuals.txt
fi

if $RUN_FALSE; then
    # (19) Cryptic relatedness
    echo "ROUND 3. Cryptic relatedness."
    ./cryptic.sh ${PREFIX}-king-3.ibs0 ${PREFIX}-cryptic-3
    Rscript $GITHUB/lib/plot-cryptic.R ${PREFIX}-cryptic-3-kinship-sum.txt ${PREFIX}-cryptic-3-counts.txt "${BATCH_LABEL} ${POP}" ${PREFIX}-cryptic-3
    if false; then
        # Remove Cryptic relatedness outliers
        echo Warning!!! Cryptic relatedness filtering is done, please ensure the threshold is correct!
        CRYPTIC_THRESHOLD_R2=9
        awk -v threshold=$CRYPTIC_THRESHOLD_R2 '$2>threshold {print $1}' ${PREFIX}-cryptic-3-kinship-sum.txt > ${PREFIX}-cryptic-3-sum-remove
        awk -v threshold=$CRYPTIC_THRESHOLD_R2 '$2<=threshold {print $0}' ${PREFIX}-cryptic-3-kinship-sum.txt > ${PREFIX}-cryptic-3-kinship-sum-filtered.txt
        join -1 1 -2 1 <(cut -f1 -d' ' ${PREFIX}-cryptic-3-kinship-sum-filtered.txt | sort) <(sort -k1,1 ${PREFIX}-cryptic-3-counts.txt) > ${PREFIX}-cryptic-3-counts-filtered.txt
        Rscript $GITHUB/lib/plot-cryptic.R ${PREFIX}-cryptic-3-kinship-sum-filtered.txt ${PREFIX}-cryptic-3-counts-filtered.txt "${BATCH_LABEL} ${POP}" ${PREFIX}-cryptic-3-filtered
        ./match.pl -f ${PREFIX}-king-3-ibd-clean.fam -g ${PREFIX}-cryptic-3-sum-remove -k 2 -l 1 -v 1 | awk '{print $2, $1}' > ${PREFIX}-cryptic-3-sum-remove.txt
        plink --silent --bfile ${PREFIX}-king-3-ibd-clean --remove ${PREFIX}-cryptic-3-sum-remove.txt --make-bed --out ${PREFIX}-cryptic-clean-3
        ./match.pl -f ${PREFIX}-king-3-ibd-clean.fam -g ${PREFIX}-cryptic-clean-3.fam -k 2 -l 2 -v 1 | awk '$7=="-" {print $1,$2,"cryptic relatedness, round 3"}' >> ${PREFIX}-3-removed-individuals.txt
    else
        # Nothing to remove because of cryptic relatedness. Copy/rename to keep consistent naming.
        echo Warning!!! Cryptic relatedness filtering is disabled.
        for ext in bed bim fam; do cp ${PREFIX}-king-3-ibd-clean.${ext} ${PREFIX}-cryptic-clean-3.${ext}; done
    fi
    
    # (20) Mendelian errors
    echo "ROUND 3. Mendelian errors."
    plink --silent --bfile ${PREFIX}-cryptic-clean-3 --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out ${PREFIX}-me-clean-sex-3
    awk '$3==0 {print $1,$2,$4}' ${PREFIX}-2-sexcheck.sexcheck > ${PREFIX}-3-sex-me.txt
    plink --silent --bfile ${PREFIX}-cryptic-clean-3 --update-sex ${PREFIX}-2-sex-me.txt --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out ${PREFIX}-me-clean-3
    awk '{print $1,$2,0}' ${PREFIX}-3-sex-me.txt > ${PREFIX}-3-sex-me-back.txt
    plink --silent --bfile ${PREFIX}-me-clean-3 --update-sex ${PREFIX}-3-sex-me-back.txt --make-bed --out ${PREFIX}-me-clean-sex-3
    ./match.pl -f ${PREFIX}-me-clean-sex-3.fam -g ${PREFIX}-cryptic-clean-3.fam -k 2 -l 2 -v 1 | awk '$7=="-" {print $1,$2,"Mendelian-error, round 3"}' >> ${PREFIX}-3-removed-individuals.txt
    ./match.pl -f ${PREFIX}-me-clean-sex-3.bim -g ${PREFIX}-cryptic-clean-3.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"Mendelian-error, round 3"}' >> ${PREFIX}-3-bad-snps.txt

fi

if $RUN_FALSE; then
    # (21) PCA with 1KG
    echo "ROUND 3. PCA with 1KG."
    plink --silent --bfile ${PREFIX}-me-clean-sex-3 --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-me-clean-sex-3-indep
    plink --silent --bfile ${PREFIX}-me-clean-sex-3 --extract ${PREFIX}-me-clean-sex-3-indep.prune.in --make-bed --out ${PREFIX}-me-clean-sex-3-pruned
    plink --silent --bfile ${PREFIX}-me-clean-sex-3-pruned --make-set high-ld.txt --write-set --out ${PREFIX}-me-clean-sex-3-highld
    plink --silent --bfile ${PREFIX}-me-clean-sex-3-pruned --exclude ${PREFIX}-me-clean-sex-3-highld.set --make-bed --out ${PREFIX}-me-clean-sex-3-trimmed

    # (21.2) Identify SNPs overlapping with 1KG
    cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
    cut -f2 ${PREFIX}-me-clean-sex-3-trimmed.bim | sort -s > ${PREFIX}-me-clean-sex-3-trimmed.bim.sorted
    join 1kg.bim.sorted ${PREFIX}-me-clean-sex-3-trimmed.bim.sorted > ${PREFIX}-me-clean-sex-3-1kg-snps.txt
    rm ${PREFIX}-me-clean-sex-3-trimmed.bim.sorted
    wc -l ${PREFIX}-me-clean-sex-3-1kg-snps.txt

    # (21.2) Merge with the 1KG dataset
    plink --silent --bfile ${PREFIX}-me-clean-sex-3-trimmed --extract ${PREFIX}-me-clean-sex-3-1kg-snps.txt --make-bed --out ${PREFIX}-me-clean-sex-3-1kg-common
    plink --silent --bfile 1kg --extract ${PREFIX}-me-clean-sex-3-1kg-snps.txt --make-bed --out 1kg-${PREFIX}-me-clean-sex-3-common

    plink --silent --bfile ${PREFIX}-me-clean-sex-3-1kg-common --bmerge 1kg-${PREFIX}-me-clean-sex-3-common --make-bed --out ${PREFIX}-me-clean-sex-3-1kg-merged
    if [[ $? > 0 ]]; then
        plink --silent --bfile 1kg-${PREFIX}-me-clean-sex-3-common --flip ${PREFIX}-me-clean-sex-3-1kg-merged-merge.missnp --make-bed --out 1kg-${PREFIX}-me-clean-sex-3-common-flip
        plink --silent --bfile ${PREFIX}-me-clean-sex-3-1kg-common --bmerge 1kg-${PREFIX}-me-clean-sex-3-common-flip --make-bed --out ${PREFIX}-me-clean-sex-3-1kg-second-merged
        if [[ $? > 0 ]]; then
            plink --silent --bfile ${PREFIX}-me-clean-sex-3-1kg-common --exclude ${PREFIX}-me-clean-sex-3-1kg-second-merged-merge.missnp --make-bed --out ${PREFIX}-me-clean-sex-3-1kg-common-clean
            plink --silent --bfile 1kg-${PREFIX}-me-clean-sex-3-common-flip --exclude ${PREFIX}-me-clean-sex-3-1kg-second-merged-merge.missnp --make-bed --out 1kg-${PREFIX}-me-clean-sex-3-common-flip-clean
            plink --silent --bfile ${PREFIX}-me-clean-sex-3-1kg-common-clean --bmerge 1kg-${PREFIX}-me-clean-sex-3-common-flip-clean --make-bed --out ${PREFIX}-me-clean-sex-3-1kg-clean-merged
            for ext in bed bim fam; do cp ${PREFIX}-me-clean-sex-3-1kg-clean-merged.${ext} ${PREFIX}-me-clean-sex-3-1kg-merged.${ext}; done
        else
            for ext in bed bim fam; do cp ${PREFIX}-me-clean-sex-3-1kg-second-merged.${ext} ${PREFIX}-me-clean-sex-3-1kg-merged.${ext}; done
        fi
    fi

    # (21.4) PCA
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}'  ${PREFIX}-me-clean-sex-3-1kg-merged.fam > ${PREFIX}-me-clean-sex-3-fam-populations.txt
    plink --silent --bfile ${PREFIX}-me-clean-sex-3-1kg-merged --pca --within ${PREFIX}-me-clean-sex-3-fam-populations.txt --pca-clusters populations.txt --out ${PREFIX}-me-clean-sex-3-1kg-pca

    # (21.5) Plot PCs
    sort -k2 ${PREFIX}-me-clean-sex-3-1kg-pca.eigenvec > ${PREFIX}-me-clean-sex-3-1kg-pca-sorted
    a=$(cat ${PREFIX}-me-clean-sex-3-trimmed.fam | wc -l)
    head -n $a ${PREFIX}-me-clean-sex-3-1kg-pca-sorted > ${PREFIX}-me-clean-sex-3-1kg-pca-1
    b=$(cat 1kg.fam | wc -l)
    tail -n $b ${PREFIX}-me-clean-sex-3-1kg-pca-sorted | sort -k2 > 1kg-initials-eur-3-pca-1
    cat ${PREFIX}-me-clean-sex-3-1kg-pca-1 1kg-initials-eur-3-pca-1 > ${PREFIX}-me-clean-sex-3-1kg-pca

fi

if $RUN_FALSE; then
    Rscript ${GITHUB}/lib/plot-pca-with-1kg.R ${BATCH_LABEL} ${PREFIX}-me-clean-sex-3-1kg-pca bottomright ${PREFIX}-me-clean-sex-3-1kg
    Rscript $GITHUB/lib/select-subsamples-on-pca.R ${BATCH_LABEL} ${PREFIX}-me-clean-sex-3-1kg-pca ${PREFIX}-selection-4 ${PREFIX}-pca-core-select-4-custom.txt
    plink --silent --bfile ${PREFIX}-me-clean-sex-3 --keep ${PREFIX}-selection-4-core-subsample-eur.txt --make-bed --out ${PREFIX}-4-keep
    ./match.pl -f ${PREFIX}-4-keep.fam -g ${PREFIX}-me-clean-sex-3.fam -k 2 -l 2 -v 1 | awk '$7=="-" {print $1,$2,"PCA-with-1kg-round-3"}' >> ${PREFIX}-3-removed-individuals.txt
fi


if $RUN_FALSE; then
    # (22) PCA without 1KG
    echo "ROUND 3. PCA without 1KG."
    plink --silent --bfile ${PREFIX}-4-keep --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-4-keep-indep
    plink --silent --bfile ${PREFIX}-4-keep --extract ${PREFIX}-4-keep-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-4-keep-highld
    plink --silent --bfile ${PREFIX}-4-keep --extract ${PREFIX}-4-keep-indep.prune.in --exclude ${PREFIX}-4-keep-highld.set --make-bed --out ${PREFIX}-4-trimmed
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' ${PREFIX}-4-trimmed.fam > ${PREFIX}-4-populations.txt
    plink --silent --bfile ${PREFIX}-4-trimmed --pca --within ${PREFIX}-4-populations.txt --pca-clusters populations.txt --out ${PREFIX}-4-pca
    awk '{if($3==0 && $4==0) print $1,$2,"black"; else print $1,$2,"red" }' ${PREFIX}-4-keep.fam > ${PREFIX}-4-keep-fam.txt
    ./match.pl -f ${PREFIX}-4-keep-fam.txt -g ${PREFIX}-4-pca.eigenvec -k 2 -l 2 -v 3 > ${PREFIX}-4-keep-pca-fam.txt
    Rscript ${GITHUB}/lib/plot-batch-PCs.R ${PREFIX}-4-keep-pca-fam.txt "${BATCH_LABEL} ${POP}, round 3" bottomright ${PREFIX}-4-pca.png
    
    if false; then
        awk '{if($11>-0.19 && $9>-0.15) print($1,$2)}' ${PREFIX}-4-pca.eigenvec > ${PREFIX}-4-pca-keep.txt
        plink --silent --bfile ${PREFIX}-4-keep --keep ${PREFIX}-4-pca-keep.txt --make-bed --out ${PREFIX}-3-round-selection
        awk ' $11>-0.19 && $9>-0.15 {print $0}' ${PREFIX}-4-keep-pca-fam.txt > ${PREFIX}-4-keep-pca-fam-keep.txt
        Rscript $GITHUB/lib/plot-batch-PCs.R ${PREFIX}-4-keep-pca-fam-keep.txt "${BATCH_LABEL} ${POP}, round 3" bottomleft ${PREFIX}-4-pca-keep.png
    else
        # Remove nothing. Copy for naming consistency.
        echo Warning!!! Selection in PCA without 1kg is disabled.
        for ext in bed bim fam; do cp ${PREFIX}-4-keep.${ext} ${PREFIX}-3-round-selection.${ext}; done
    fi
fi

if $RUN_TRUE; then
    # (23) Plate effects.
    echo "ROUND 3. Plate effects."
    plink --silent --bfile ${PREFIX}-3-round-selection --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-3-round-indep
    plink --silent --bfile ${PREFIX}-3-round-selection --extract ${PREFIX}-3-round-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-3-round-highld
    plink --silent --bfile ${PREFIX}-3-round-selection --extract ${PREFIX}-3-round-indep.prune.in --exclude ${PREFIX}-3-round-highld.set --make-bed --out ${PREFIX}-3-round-trimmed
    plink --silent --bfile ${PREFIX}-3-round-trimmed --pca --within ${PREFIX}-4-populations.txt --pca-clusters populations.txt --out ${PREFIX}-4-round-pca

    # (23.2) Plot PCs by plate
    ./match.pl -f GSA-plates.txt -g ${PREFIX}-4-round-pca.eigenvec -k 1 -l 2 -v 3 | awk '$23!="-" {print $0}' | sort -k23 > ${PREFIX}-4-pca-plates.txt
    awk '{print $1,$2,$23}' ${PREFIX}-4-pca-plates.txt > ${PREFIX}-4-plate-groups.txt
    Rscript ${GITHUB}/lib/plot-PC-by-plate.R ${PREFIX}-4-pca-plates.txt "${BATCH_LABEL} ${POP}, round 3" ${PREFIX}-4

    Rscript ${GITHUB}/lib/anova-for-PC-vs-plates.R ${PREFIX}-4-pca-plates.txt ${PREFIX}-4-pca-anova-results.txt
   
    # (23.4) Test for association between the plate and SNPs
    plink --silent --bfile ${PREFIX}-3-round-selection --filter-founders --chr 1-22 --pheno ${PREFIX}-3-round-selection.fam --mpheno 3 --within ${PREFIX}-4-plate-groups.txt --mh2 --out ${PREFIX}-4-mh-plates
    Rscript ${GITHUB}/lib/plot-qqplot.R ${PREFIX}-4-mh-plates.cmh2 "${BATCH_LABEL} ${POP}, round 3" 5 ${PREFIX}-4-mh-plates-qq-plot
    sort -k5 -g ${PREFIX}-4-mh-plates.cmh2 | grep -v "NA" > ${PREFIX}-4-mh2-plates-sorted
    awk '$5<0.001 {print $2}' ${PREFIX}-4-mh2-plates-sorted > ${PREFIX}-4-mh2-plates-significant
    if [[ -f ${PREFIX}-4-mh2-plates-significant ]]; then
        wc -l ${PREFIX}-4-mh2-plates-significant
        plink --silent --bfile ${PREFIX}-3-round-selection --exclude ${PREFIX}-4-mh2-plates-significant --make-bed --out ${PREFIX}-4-batch
        awk '{print $1,"plate-effect"}' ${PREFIX}-4-mh2-plates-significant >> ${PREFIX}-3-bad-snps.txt
    else
        for ext in bed bim fam; do cp ${PREFIX}-3-round-selection.${ext} ${PREFIX}-4-batch.${ext}; done
    fi
    
    # (23.5) Re-run PCA
    plink --silent --bfile ${PREFIX}-4-batch --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-4-batch-indep
    plink --silent --bfile ${PREFIX}-4-batch --extract ${PREFIX}-4-batch-indep.prune.in --make-set high-ld.txt --write-set --out ${PREFIX}-4-batch-highld
    plink --silent --bfile ${PREFIX}-4-batch --extract ${PREFIX}-4-batch-indep.prune.in --exclude ${PREFIX}-4-batch-highld.set --make-bed --out ${PREFIX}-4-batch-trimmed
    plink --silent --bfile ${PREFIX}-4-batch-trimmed --pca --within ${PREFIX}-4-populations.txt --pca-clusters populations.txt --out ${PREFIX}-4-batch-pca

    # (23.6) Re-run ANOVA
    ./match.pl -f GSA-plates.txt -g ${PREFIX}-4-batch-pca.eigenvec -k 1 -l 2 -v 3 | awk '$23!="-" {print $0}' | sort -k23 > ${PREFIX}-4-batch-pca-plates.txt
    Rscript ${GITHUB}/lib/anova-for-PC-vs-plates.R ${PREFIX}-4-batch-pca-plates.txt ${PREFIX}-4-batch-pca-anova-results.txt
fi
