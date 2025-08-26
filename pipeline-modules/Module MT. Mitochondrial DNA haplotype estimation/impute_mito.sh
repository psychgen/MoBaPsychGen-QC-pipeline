#!/bin/bash

# Main parameters.
MOBA_QC_DIR=/tsd/p697/data/durable/projects/moba_qc_imputation
BATCH_LABEL=Norment_nov2020_1066
BATCH_BFILE_DIR=${MOBA_QC_DIR}/NORMENT_Nov2020/1066
BATCH_ID="PDB1479_R1066_sentrix" # Prefix of the original bfile, full path to the original bfile is ${BATCH_BFILE_DIR}/${BATCH_ID}
SCRIPTS="/ess/p697/data/durable/projects/moba_qc_imputation/AS/mito/scripts"
UPDATE_ALLELES=false # true for batches on HCE chips, otherwise false
# humancoreexome-12v1-1_A.update_alleles.txt for HARVEST12good and HARVEST12bad, humancoreexome-24v1-0_A.update_alleles.txt for HARVEST24
UPDATE_ALLELES_FNAME="${MOBA_QC_DIR}/resources/humancoreexome-24v1-0_A.update_alleles.txt" 
ENVS="/ess/p697/data/durable/projects/moba_qc_imputation/AS/mito"
REF_DIR="/ess/p697/data/durable/projects/moba_qc_imputation/AS/mito/MitoImpute-master/resources/ReferencePanel_v1_0.001"
WORK_DIR=$(pwd)

# NB! At the moment lifting is DISABLED since it seems that MT coordinates are the same in hg19 and hg38. So the following three parameters are not used.
GENO_BUILD="hg38" # Either "hg38" (then lifted to hg19) or "hg19" (no lift is performed).
SOFTWARE_DIR=${MOBA_QC_DIR}/software
LIFTOVER_CHAIN_FILE=hg38ToHg19.over.chain.gz # will be taken from SOFTWARE_DIR

# Parameters (taken from MitoImpute config.yaml file)
IMP_ITER=2
IMP_BURNIN=1
IMP_KHAP=500
INFOCUT=0

source ${ENVS}/mitoimp/bin/activate

echo "Work dir: ${WORK_DIR}"
echo "Plink: $(which plink) version $(plink --version)"
echo "R: $(which R)"
echo "Impute2: $(which impute2)"

# Lift is disabled since mitochondrial coordinates are the same for hg19 and hg38 builds.
if false; then
    rsync -zah ${SOFTWARE_DIR}/liftOver ${WORK_DIR}
    rsync -zah ${SOFTWARE_DIR}/${LIFTOVER_CHAIN_FILE} ${WORK_DIR}
fi

BFILE=${WORK_DIR}/${BATCH_ID}
for ext in bed bim fam; do rsync -zah ${BATCH_BFILE_DIR}/${BATCH_ID}.${ext} ${BFILE}.${ext}; done

# Update alleles if needed
if ${UPDATE_ALLELES}; then
    OUT_BFILE="${BFILE}_update_alleles"
    plink --silent --bfile ${BFILE} --update-alleles ${UPDATE_ALLELES_FNAME} --make-bed --out ${OUT_BFILE}
    BFILE=${OUT_BFILE}
fi

# Change sex of all samples to male.
awk '{$5="1"; print}' ${BFILE}.fam > ${BFILE}_maleOnly.fam

# Extract variants on mitohondrial chromosome.
# Keep only SNPs with ATGC alleles.
OUT_BFILE="${BFILE}_chrMT"
plink --silent --bfile ${BFILE} --fam ${BFILE}_maleOnly.fam --chr 26 --output-chr 26 --snps-only 'just-acgt' --keep-allele-order --make-bed --out ${OUT_BFILE}
BFILE=${OUT_BFILE}

# Perform basic QC:
#    - Remove monomorphic variants and variants with genotype missingness > 98%.
#    - Keep only the first variant among variants with the same position and alleles.
#    - Remove individuals with genotype missingness > 98%.
OUT_BFILE="${BFILE}_vqc"
plink --silent --bfile ${BFILE} --mac 1 --geno 0.99 --make-bed --out ${OUT_BFILE}
BFILE=${OUT_BFILE}
DUP_VARIANTS="${BFILE}_dup_variants"
plink --silent --bfile ${BFILE} --list-duplicate-vars 'ids-only' 'suppress-first' --out ${DUP_VARIANTS}
OUT_BFILE="${BFILE}_sqc"
plink --silent --bfile ${BFILE} --mac 1 --geno 0.99 --mind 0.99 --exclude "${DUP_VARIANTS}.dupvar" --make-bed --out ${OUT_BFILE}
BFILE=${OUT_BFILE}

# Lift is disabled since mitochondrial coordinates are the same for hg19 and hg38 builds.
if false; then
    # It seems that GRCh37 and GRCh38 coordinates for mitochondria are identical (however, liftover changes coordinates! It seems it uses "Yoruba" reference for hg19 and "rCRS" for hg38).
    # Lift to hg19 if needed.
    OUT_BFILE="${BFILE}_hg19"
    if [ "$GENO_BUILD" = "hg38" ]; then
        LIFTOVER_IN="${BFILE}.liftover_in.bed"
        LIFTOVER_OUT="${BFILE}.liftover_out.bed"
        LIFTOVER_UNLIFTED="${BFILE}.liftover_unlifted.bed"
        # it is supposed that bim file contains only mitochondrial variants
        awk 'BEGIN{OFS="\t"} {print("chrM", $4-1, $4, $2)}' "${BFILE}.bim" > ${LIFTOVER_IN}
        ./liftOver ${LIFTOVER_IN} ${LIFTOVER_CHAIN_FILE} ${LIFTOVER_OUT} ${LIFTOVER_UNLIFTED}
        UPDATE_MAP="${BFILE}.liftover_update_map.txt"
        UNLIFTED_IDS="${BFILE}.liftover_unlifted_ids.txt"
        awk '{print($4,$2+1)}' ${LIFTOVER_OUT} > ${UPDATE_MAP}
        awk '{print($4)}' ${LIFTOVER_UNLIFTED} > ${UNLIFTED_IDS}
        plink --silent --bfile ${BFILE} --update-map ${UPDATE_MAP} --exclude ${UNLIFTED_IDS} --make-bed --out ${OUT_BFILE}
    elif [ "$GENO_BUILD" = "hg19" ]; then
        for ext in bed bim fam; do cp ${BFILE}.${ext} ${OUT_BFILE}.${ext}; done
    else
        echo "GENO_BULD must be either 'hg38' or 'hg19'"
        exit 1
    fi
    BFILE=${OUT_BFILE}
fi

# Check if mitochondrial SNPs are mapped to  rCRS, if not liftover.
REF_SNPS="${REF_DIR}/ReferencePanelSNPs_MAF0.001.txt"
BIM="${BFILE}.bim"
BIM_RCRS="${BFILE}_rcrsFlipped.bim"
Rscript ${SCRIPTS}/yri_to_rcrs_flip.R ${REF_SNPS} ${BIM} ${BIM_RCRS}

# Convert plink bfiles to oxford format.
PREFIX_RCRS="${BFILE}_rcrsFlipped"
plink --silent --bfile ${BFILE} --bim ${BIM_RCRS} --recode oxford --keep-allele-order --out ${PREFIX_RCRS}

# Convert plink bfile to ped/map format.
PREFIX_TYPED="${BFILE}_typedOnly"
plink --silent --bfile ${BFILE} --bim ${BIM_RCRS} --recode --keep-allele-order --out ${PREFIX_TYPED}

# Use impute2 to impute mitochondrial SNPs.
echo "Running imputation."
MT_MAP="${REF_DIR}/ReferencePanel_v1_0.001_MtMap.txt"
HAP="${REF_DIR}/ReferencePanel_v1_0.001.hap.gz"
LEGEND="${REF_DIR}/ReferencePanel_v1_0.001.legend.gz"
GEN="${PREFIX_RCRS}.gen"
SAMPLE="${PREFIX_RCRS}.sample"
OUT_IMP="${PREFIX_RCRS}_imputed"
impute2 -chrX -m ${MT_MAP} -h ${HAP} -l ${LEGEND} -g ${GEN} -sample_g ${SAMPLE} -int 1 16569 -Ne 20000 -o ${OUT_IMP} -iter ${IMP_ITER} -burnin ${IMP_BURNIN} -k_hap ${IMP_KHAP}

# Change MT chromosome name to '26'
IMP_CHR_FIXED="${OUT_IMP}_ChromFixed"
awk '{$1=26; print}' ${OUT_IMP} > ${IMP_CHR_FIXED}

# Convert oxford files to plink bfiles.
plink --silent --gen ${IMP_CHR_FIXED} --sample "${OUT_IMP}_samples" --hard-call-threshold 0.49 --keep-allele-order --make-bed --output-chr 26 --out ${OUT_IMP}
# Convert Oxford files to .map/.ped files
OUT_IMP_PLOTS="${OUT_IMP}_for_plots"
plink --silent --gen ${IMP_CHR_FIXED} --sample "${OUT_IMP}_samples" --hard-call-threshold 0.49 --keep-allele-order --recode --output-chr 26 --out ${OUT_IMP_PLOTS}

# Make INFO and haplogroups plots.
PLOT_OUT_PREFIX=$(basename ${OUT_IMP})
Rscript ${SCRIPTS}/plots.R "${PREFIX_TYPED}.map" "${PREFIX_TYPED}.ped" "${OUT_IMP_PLOTS}.map" "${OUT_IMP_PLOTS}.ped" "${OUT_IMP}_info" ${WORK_DIR} ${PLOT_OUT_PREFIX} ${INFOCUT}

# Make MAF vs INFO figure
FREQ="${OUT_IMP}_info_freq"
plink --silent --bfile ${OUT_IMP} --freq --out ${FREQ}
FREQ_INFO_PLOT="${OUT_IMP}_info_maf.png"
python ${SCRIPTS}/mito_plots.py "${FREQ}.frq" "${OUT_IMP}_info" ${BATCH_LABEL} ${FREQ_INFO_PLOT}

