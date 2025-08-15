# Module 8: Post-imputation QC

This module contains shell scripts for performing post-imputation quality control (QC) on individual genotype release batches before merging. Each script processes a specific release/platform combination from the MoBa study.

## Overview - AI generated summary

Post-imputation QC is performed on each release separately to ensure data quality before merging batches in Module 9. This approach allows for batch-specific quality control and easier identification of platform-specific issues.

## Scripts

### Individual Release QC Scripts

- **`release1-gsa.sh`** - QC for Release 1 GSA (Global Screening Array) platform
- **`release1-hce.sh`** - QC for Release 1 HumanCoreExome platform
- **`release1-omni.sh`** - QC for Release 1 Omni platform
- **`release2.sh`** - QC for Release 2 data
- **`release3.sh`** - QC for Release 3 data
- **`release4.sh`** - QC for Release 4 data

## QC Pipeline Steps

Each script performs the following standardized QC steps:

### 1. Data Import and Initial Filtering

- Copy imputed data (INFO ≥ 0.8, MAF ≥ 0.01) from imputation results
- Generate missingness reports and plots

### 2. Basic Quality Control

- **Genotype call rate filtering**: Remove SNPs with >5% missing data (--geno 0.05)
- **Strict genotype filtering**: Additional filter at 2% missing for high-quality SNP set
- **Sample call rate filtering**: Remove samples with >2% missing data (--mind 0.02)
- **Hardy-Weinberg Equilibrium**: Remove SNPs with HWE p-value < 1×10⁻⁶

### 3. Heterozygosity Assessment

- Calculate heterozygosity rates for quality assessment
- Generate plots for heterozygosity distribution
- Remove samples with extreme heterozygosity (if applicable)

### 4. Relatedness and Pedigree Analysis

- **LD pruning**: Create independent SNP set for kinship analysis
- **KING relatedness analysis**:
  - Detect family relationships and build pedigrees
  - Generate relatedness plots
  - Identify pedigree errors and unexpected relationships
- **Cryptic relatedness detection**: Identify unrecorded relationships

### 5. Identity-by-Descent (IBD) Analysis

- **LD pruning**: Remove high-LD regions for IBD calculation
- **IBD estimation**: Calculate IBD sharing for all pairs with π̂ > 0.15
- **Relationship validation**:
  - Parent-offspring: Expected π̂ ≈ 0.5
  - Full siblings: Expected π̂ ≈ 0.5
  - Half siblings: Expected π̂ ≈ 0.25
- **Identify problematic relationships**: Flag relationships with unexpected IBD values

### 6. Mendelian Error Detection

- Set Mendelian errors to missing (--me 0.05 0.01 --set-me-missing)
- Handle parent-offspring duos with --mendel-duos

### 7. Population Structure Analysis

#### PCA with 1000 Genomes Reference

- Merge with 1000 Genomes reference populations
- Perform PCA to assess population structure
- Generate ancestry plots and population selection criteria

#### Internal PCA

- PCA using only study samples
- Generate plots distinguishing founders vs. offspring
- Assess population stratification within the cohort

### 8. Batch Effect Detection

- **PC-batch association tests**: Test for association between PCs and genotyping batches
- **Cochran-Mantel-Haenszel test**: Test for allele frequency differences across batches
- **Batch effect correction**: Remove SNPs showing significant batch effects (p < 5×10⁻⁸)
- **Post-correction validation**: Repeat PCA and statistical tests after SNP removal

### 9. Final QC Summary

- Generate final quality-controlled dataset
- Produce summary statistics and QC plots
- Prepare data for cross-batch merging in Module 9

## Key Software Dependencies

- **PLINK v1.90**: Primary tool for genetic data manipulation and QC
- **KING v2.2.5**: Kinship analysis and pedigree inference
- **FlashPCA**: Fast principal component analysis
- **R**: Statistical analysis and visualization
- **Custom scripts**: Perl matching scripts and R plotting functions

## Output Files

Each script generates:

- Quality-controlled genotype files (`.bed/.bim/.fam`)
- QC summary statistics and plots (`.png` files)
- Lists of excluded samples and SNPs
- Relatedness and population structure results

## Usage Notes

1. **Platform-specific considerations**: Each platform may require slight modifications to QC thresholds
2. **Computational requirements**: Scripts are designed for HPC cluster environments
3. **File paths**: Update paths to match your local environment
4. **Dependencies**: Ensure all required software and reference files are available
