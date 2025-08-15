
# QC Scripts

This directory contains various tools and scripts written in R, python, perl, bash and SLURM scheduler
used in the QC part of the pipeline (modules 0-4) and post-imputation QC.
README files with information about what each script is used for can be found in the respective sub-directories.

## Summary of Subdirectories (AI generated summary)

This repository contains a comprehensive collection of quality control scripts organized by programming language and functionality:

### R_scripts/ (21 scripts)

**Visualization and Statistical Analysis Tools**

- **PCA and Population Structure**: Scripts for principal component analysis with 1000 Genomes integration, ancestry plotting, and population subsample selection
  - `plot-pca-with-1kg.R` - PCA plots with 1000 Genomes reference
  - `select-subsamples-on-pca.R` - Core population selection based on PCA
  - `select-subsamples-on-pca-ellipse.R` - Ellipse-based sample selection
  - `plot-pca-selected-subsample.R` - Plots of selected samples

- **Quality Control Visualizations**: Comprehensive plotting functions for various QC metrics
  - `plot-missingness-histogram.R` - Missing data rate histograms
  - `plot-heterozygosity-common.R` - Heterozygosity vs missingness plots with outlier detection
  - `plot-ibd.R` - Identity-by-descent relationship plots
  - `plot-sex.R` - X-chromosome inbreeding coefficient plots by sex
  - `plot-kinship-histogram.R` - Kinship coefficient distributions

- **Batch Effect Analysis**: Tools for detecting and visualizing technical artifacts
  - `plot-batch-PCs.R` - Principal component plots for batch analysis
  - `plot-PC-by-batch.R` / `plot-PC-by-plate.R` - PC plots colored by technical variables
  - `anova-for-PC-vs-plates.R` - Statistical tests for batch effects

- **Relatedness and Cryptic Structure**:
  - `plot-cryptic.R` - Cryptic relatedness visualization
  - `merge-relatedness-rt.R` - Merge IBD results with KING relationship types
  - `IBD.R` - Identity-by-descent analysis workflows

- **Data Processing Utilities**:
  - `create-liftover-input.R` / `create-update-chr-input.R` - Genome coordinate conversion
  - `plot-qqplot.R` - Q-Q plots for association testing

### python_scripts/ (2 scripts)

**Interactive Sample Selection Tools**

- `ellipseselect.py` - Modern interactive sample selection using bokeh web interface
- `select_samples.py` - Legacy matplotlib-based sample selection (obsolete)

Both scripts enable interactive selection of population subsamples from PCA plots with 1000 Genomes reference data.

### perl_scripts/ (2 scripts)

**Data Matching and Validation**

- `match.pl` - Flexible file matching utility for joining datasets on common keys
- `HRC-1000G-check-bim.pl` - Pre-imputation validation against HRC/1000G reference panels

### shell_scripts/ (2 scripts)

**Analysis Workflow Helpers**

- `create-relplot.sh` - KING relatedness plot generation with customizable layouts
- `cryptic.sh` - Cryptic relatedness analysis (kinship coefficient summaries)

### slurm_jobs/ (2 scripts)

**HPC Job Templates**

- `IBD.job` - SLURM template for identity-by-descent calculations
- `KING.job` - SLURM template for KING relatedness and pedigree analysis

### config/ (9 files)

**Configuration Templates**

Batch-specific and study-specific parameter files for:

- PCA threshold definitions for different populations (EUR, AFR, ASIAN)
- Ellipse selection parameters for sample filtering
- AWK scripts for custom filtering logic

## Key Features

**Comprehensive QC Pipeline**: Scripts cover all major aspects of genetic QC including:

- Data missingness assessment
- Population structure analysis
- Relatedness and family structure validation
- Batch effect detection and correction
- Sex concordance verification
- Hardy-Weinberg equilibrium testing

**Integration with Standard Tools**: Compatible with:

- PLINK (primary genetic analysis software)
- KING (kinship and relatedness analysis)
- 1000 Genomes reference data
- HRC imputation reference panel

**Visualization Focus**: Extensive plotting capabilities for:

- Quality assessment
- Population structure
- Relationship verification
- Batch effect identification
- Statistical distributions

**HPC Ready**: SLURM job templates and modular design suitable for high-performance computing environments.

**Interactive Capabilities**: Web-based and GUI tools for manual sample curation and quality assessment.

