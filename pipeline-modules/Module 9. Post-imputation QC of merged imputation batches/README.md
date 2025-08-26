# Post-imputation QC of merged imputation batches

The [MobaPsychGen_v1.sh](MobaPsychGen_v1.sh) script is a comprehensive shell script for post-imputation quality control (QC) of merged imputation batches in the MoBaPsychGen_v1 dataset. 

Overview of the Script (AI generated summary):

Purpose: Post-imputation QC of merged genotype data from multiple releases (Release1 HCE/OMNI/GSA, Release2-4) of the MoBa (Norwegian Mother, Father and Child Cohort Study) dataset.

Main QC Steps:

- Merge Releases - Combines data from different genotyping platforms and releases
- Basic QC - MAF filtering, missingness filtering, HWE testing
- Duplicate Detection - Identifies and handles duplicate/triplicate samples
- Pedigree Building - Uses KING software for relatedness analysis and pedigree construction
- Cryptic Relatedness - Detects unexpected relationships using IBD analysis
- LD Pruning - Removes high-LD regions for analysis
- IBD Analysis - Validates family relationships
- Mendelian Error Checking - Identifies and corrects inheritance inconsistencies
- Population Structure Analysis - PCA with 1000 Genomes reference
- Batch Effect Detection - Tests for systematic differences between batches

Key Features:

- Uses PLINK for most genetic data operations
- Employs KING software for kinship and relatedness analysis
- Includes R scripts for plotting and statistical analysis
- Handles complex family structures and multi-generational data
- Performs comprehensive QC across multiple genotyping platforms
- The script is designed to run on a high-performance computing cluster with specific software dependencies (PLINK, KING, FlashPCA, R) and follows best practices for large-scale genomic QC pipelines.
