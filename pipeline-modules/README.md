## Contents

* [Module 0] - Harmonize genotype data
* [Module 1] - Classify MoBa individuals against 1000 Genomes ancestral populations
* [Module 2] - QC of ancestry populations
* [Module 3] - Merge by genotyping array
* [Module 4] - QC of ancestry populations in merged genotyping array datasets
* [Module 5] - Pre-phasing QC
* [Module 6] - Phasing
* [Module 7] - Imputation
* [Module 8] - Post-imputation QC
* [Module 9] - Post-imputation QC of merged imputation batches
* [Module X] - Chromosome X and pseudoautosomal regions (PAR) QC procedure
* [Module MT] - Mitochondrial DNA haplotype estimation
* [Module Y] - Chromosome Y haplotype estimation

* [qc_m1.sh](#qc_m1sh)
* [qc_m2.sh](#qc_m2sh)
* [qc_chrX.sh](#qc_chrxsh)

Modules 5-7 (pre-phasing QC, phasing and imputation) are highly coupled, and should be generally considered a single module performing imputation.
The input to module 5 consists of one “bfile” in plink format (.bed/.bim/.fam), with approximately 400K-800K genetic variants. The output of module 7 is dosage data (in bgen format, split per chromosome, with 40M genetic variants) and hard calls (in plink “bfile” format, one file concatenated across chromosomes, with between 5M and 10M genetic variants selected by INFO and MAF filters).

## Summary of scripts

### qc_m1.sh
This script performs module 1 of the QC pipeline.

### qc_m2.sh
This script performs module 0 and 1 of the QC pipeline.

### qc_chrX.sh
This script performs the chromosome X module of the QC pipeline.
