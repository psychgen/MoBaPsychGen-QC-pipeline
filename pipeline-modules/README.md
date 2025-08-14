# Pipeline Modules
This repository contains the modules of the MoBaPsychGen QC pipeline, which is used for quality control of genetic data from the Norwegian Mother, Father and Child Cohort Study (MoBa).

The modules are designed to be run sequentially, with each module building on the output of the previous one. The modules cover various aspects of quality control, including harmonization of genotype data, classification against ancestral populations, merging datasets, pre-phasing QC, phasing, imputation, and post-imputation QC.

## Contents

* [Module 0](Module%200.%20Harmonization%20of%20genotype%20data.md) - Harmonize genotype data
* [Module 1](Module%201.%20Classification%20of%20MoBa%20individuals%20against%201000%20Genomes%20ancestral%20populations.md) - Classify MoBa individuals against 1000 Genomes ancestral populations
* [Module 2](Module%202.%20QC%20of%20ancestry%20populations.md) - QC of ancestry populations
* [Module 3](Module%203.%20Merge%20by%20genotyping%20array.md) - Merge by genotyping array
* [Module 4](Module%204.%20QC%20of%20ancestry%20populations%20in%20merged%20genotyping%20array%20datasets.md) - QC of ancestry populations in merged genotyping array datasets
* [Module 5](Module%205.%20Pre-phasing%20QC.md) - Pre-phasing QC
* [Module 6](Module%206.%20Phasing.md) - Phasing
* [Module 7](Module%207.%20Imputation.md) - Imputation
* [Module 8](Module%208.%20Post-imputation%20QC.md) - Post-imputation QC
* [Module 9](Module%209.%20Post-imputation%20QC%20of%20merged%20imputation%20batches.md) - Post-imputation QC of merged imputation batches
* [Module X](Module%20X.%20Chromosome%20X%20and%20pseudoautosomal%20regions%20(PAR)%20QC%20procedure.md) - Chromosome X and pseudoautosomal regions (PAR) QC procedure
* [Module MT](Module%20MT.%20Mitochondrial%20DNA%20haplotype%20estimation.md) - Mitochondrial DNA haplotype estimation
* [Module Y](Module%20Y.%20Chromosome%20Y%20haplotype%20estimation) - Chromosome Y haplotype estimation
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
