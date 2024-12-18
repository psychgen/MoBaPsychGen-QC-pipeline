#!/bin/bash

module load gcc # this is needed to get shared libraries required for some R packages (e.g. libgfortran.so.5 is required for DescTools package, but is not available with system default gcc suite)

# general parameters
MOBA_QC_DIR=/tsd/p697/data/durable/projects/moba_qc_imputation
RESOURCES_DIR=${MOBA_QC_DIR}/resources
SOFTWARE_DIR=${MOBA_QC_DIR}/software
GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba_qc_imputation

# batch and user specific parameters
WORK_DIR=${MOBA_QC_DIR}/AS/norment_mar2021_1531/M1
BATCH_ID="PDB1479_R1531_sentrix" # prefix of the original plink bfiles.
INITIALS="as"
PREFIX="${BATCH_ID}-${INITIALS}" # prefix of all produced files
BATCH_LABEL=Norment_Mar2021_1531 # to use in figures
BATCH_BFILE_DIR=${MOBA_QC_DIR}/NORMENT_Mar2021/1531 # will take ${BATCH_BFILE_DIR}/${BATCH_ID}.<bed/bim/fam> as original bfiles
UPDATE_SNP_IDS_FILE=GSA-24v3-0_A1_b151_rsids_unique.txt # will be taken from RESOURCES_DIR
LIFTOVER_CHAIN_FILE=hg38ToHg19.over.chain.gz # will be taken from RESOURCES_DIR
LINKAGE_VERSION=12

# flow control parameters
RUN_TRUE=true
RUN_FALSE=false
#--------------------------------------------------------------------

# copy input data
echo "Sync input data and resources."
rsync -zah ${BATCH_BFILE_DIR}/${BATCH_ID}.* ${WORK_DIR}
rsync -zah ${GITHUB}/software/match.pl ${WORK_DIR}
chmod +x match.pl
rsync -zah ${RESOURCES_DIR}/update_ids_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/update_parental_ids_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/sex_v${LINKAGE_VERSION}.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/${UPDATE_SNP_IDS_FILE} ${WORK_DIR}
rsync -zah ${SOFTWARE_DIR}/liftOver ${WORK_DIR}
rsync -zah ${SOFTWARE_DIR}/${LIFTOVER_CHAIN_FILE} ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/1kg.* ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/high-ld.txt ${WORK_DIR}
rsync -zah ${RESOURCES_DIR}/populations.txt ${WORK_DIR}

if $RUN_FALSE; then
    echo "Running M0"
    # update SNP IDs
    plink --silent --bfile ${BATCH_ID} --update-name ${UPDATE_SNP_IDS_FILE} --make-bed --out ${PREFIX}-rsids

    # Create the input file required by liftover
    echo '
bim <- read.table("'${PREFIX}-rsids.bim'",h=F, colClasses=c("integer","character","integer","integer","character","character"))
bim$V7 <- as.integer(bim$V4+1)
autosome <- subset(bim, V1<=22)
autosome$V8 <- paste("chr", autosome$V1, sep="")
X <- subset(bim, V1==23)
X$V8 <- "chrX"
Y <- subset(bim, V1==24)
Y$V8 <- "chrY"
bim <- rbind(autosome, X, Y)
lift <- bim[,c(8,4,7,2)]
write.table(lift, "'${PREFIX}-liftover_input.bed'",row.names=F, col.names=F, sep="\t",quote=F)
q()
' | R --vanilla

    # update the chromosomal positions and exclude SNPs whose chromosomal positions were not able to be updated
    ./liftOver ${PREFIX}-liftover_input.bed ${LIFTOVER_CHAIN_FILE} ${PREFIX}-liftover_output.bed ${PREFIX}-liftover_unlifted.bed
    awk '{print $4, $2}' ${PREFIX}-liftover_output.bed > ${PREFIX}-liftover-update-map.txt
    awk '{print $4}' ${PREFIX}-liftover_unlifted.bed > ${PREFIX}-liftover_unlifted.snps
    plink --silent --bfile ${PREFIX}-rsids --update-map ${PREFIX}-liftover-update-map.txt --exclude ${PREFIX}-liftover_unlifted.snps --make-bed --out ${PREFIX}-liftover
    ./match.pl -f ${PREFIX}-liftover.bim -g ${PREFIX}-rsids.bim -k 2 -l 2 -v 1 | awk '$7=="-" {print $2,"no-build-liftover"}' >> ${PREFIX}-bad-snps.txt

fi

if $RUN_FALSE; then
    echo "Running M1"
    # update FIDs
    plink --silent --bfile ${PREFIX}-liftover --update-ids update_ids_v${LINKAGE_VERSION}.txt --make-bed --out ${PREFIX}-id
    # update parental ids
    plink --silent --bfile ${PREFIX}-id --update-parents update_parental_ids_v${LINKAGE_VERSION}.txt --make-bed --out ${PREFIX}-parental
    # update sex
    plink --silent --bfile ${PREFIX}-parental --update-sex sex_v${LINKAGE_VERSION}.txt --make-bed --out ${PREFIX}-sex
fi

if $RUN_FALSE; then
    # remove SNPs and individuals with low call rate, not in hwe, and low maf
    plink --silent --bfile ${PREFIX}-sex --maf 0.01 --make-bed --out ${PREFIX}-common
    plink --silent --bfile ${PREFIX}-common --geno 0.05 --make-bed --out ${PREFIX}-95
    plink --silent --bfile ${PREFIX}-95 --geno 0.05 --mind 0.05 --make-bed --out ${PREFIX}-call-rates
    plink --silent --bfile ${PREFIX}-call-rates --hwe 0.001 --make-bed --out ${PREFIX}-basic-qc

    # Prune MoBa data
    awk '$3==0 && $4==0 {print $1,$2}' ${PREFIX}-basic-qc.fam > ${PREFIX}-founders.txt
    plink --silent --bfile ${PREFIX}-basic-qc --indep-pairwise 3000 1500 0.1 --out ${PREFIX}-prune
    plink --silent --bfile ${PREFIX}-basic-qc --extract ${PREFIX}-prune.prune.in --make-bed --out ${PREFIX}-pruned

    # long LD regions
    plink --silent --bfile ${PREFIX}-pruned --make-set high-ld.txt --write-set --out ${PREFIX}-highld
    plink --silent --bfile ${PREFIX}-pruned --exclude ${PREFIX}-highld.set --make-bed --out ${PREFIX}-trimmed

    # Identify SNPs that are present both in MoBa and in 1KG
    cut -f2 1kg.bim | sort -s > 1kg.bim.sorted
    cut -f2 ${PREFIX}-trimmed.bim | sort -s > ${PREFIX}-trimmed.bim.sorted
    join 1kg.bim.sorted ${PREFIX}-trimmed.bim.sorted > ${PREFIX}-1kg-snps.txt
    rm -f 1kg.bim.sorted ${PREFIX}-trimmed.bim.sorted

    # Extract the overlapping SNPs from MoBa and from 1KG
    plink --silent --bfile ${PREFIX}-trimmed --extract ${PREFIX}-1kg-snps.txt --make-bed --out ${PREFIX}-1kg-common
    plink --silent --bfile 1kg --extract ${PREFIX}-1kg-snps.txt --make-bed --out 1kg-${PREFIX}-common

    # Merge the MoBa and 1KG data
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
    # run PCA
    awk '{if($3==0 && $4==0) print $1,$2,"parent"; else print $1,$2,"child"}' ${PREFIX}-1kg-merged.fam > ${PREFIX}-fam-populations.txt
    plink --silent --bfile ${PREFIX}-1kg-merged --pca --within ${PREFIX}-fam-populations.txt --pca-clusters populations.txt --out ${PREFIX}-1kg-pca

    # order 1KG samples
    A=$(cat ${PREFIX}-1kg-common.fam | wc -l)
    B=$(cat 1kg.fam | wc -l)
    head -n $A ${PREFIX}-1kg-pca.eigenvec > ${PREFIX}-pca-1
    tail -n $B  ${PREFIX}-1kg-pca.eigenvec | sort -k2 > 1kg-${INITIALS}-pca-1
    cat ${PREFIX}-pca-1 1kg-${INITIALS}-pca-1 > ${BATCH_ID}-1kg-${INITIALS}-pca
fi

if $RUN_TRUE; then
    Rscript ${GITHUB}/lib/plot-pca-with-1kg.R ${BATCH_LABEL} ${BATCH_ID}-1kg-${INITIALS}-pca bottomright ${PREFIX}
    Rscript ${GITHUB}/lib/select-subsamples-on-pca.R ${BATCH_LABEL} ${BATCH_ID}-1kg-${INITIALS}-pca ${PREFIX} config/${PREFIX}-pca-core-select-custom.txt
    Rscript ${GITHUB}/lib/select-subsamples-on-pca-ellipse.R ${BATCH_LABEL} ${BATCH_ID}-1kg-${INITIALS}-pca ${PREFIX} config/${PREFIX}-pca-core-select-ellipse-custom.txt

    plink --silent --bfile ${PREFIX}-sex --keep ${PREFIX}-core-subsample-eur-fin.txt --make-bed --out ${PREFIX}-eur-fin
    plink --silent --bfile ${PREFIX}-sex --keep ${PREFIX}-core-subsample-afr.txt --make-bed --out ${PREFIX}-afr
    plink --silent --bfile ${PREFIX}-sex --keep ${PREFIX}-core-subsample-asian.txt --make-bed --out ${PREFIX}-asian

fi

echo "Done"

