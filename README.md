# MoBaPsychGen QC pipeline

## Overview

This repository is home to documentation and code for the MoBaPsychGen QC pipeline. This pipeline was developed for and applied to genotype data from the Norwegian Mother, Father, and Child Cohort study (MoBa).

The pipeline is described in the [preprint](https://doi.org/10.1101/2022.06.23.496289) entitled: "The Norwegian Mother, Father, and Child cohort study (MoBa) genotyping data resource: MoBaPsychGen pipeline v.1" and manuscript entitled “Unique opportunities to study health and behavior in genotyped family cohorts”. The latest reference should be cited by work based on either the data, procedures, or code from the MoBaPsychGen QC pipeline.

Analytic code for the exemplar trio analyses are available in a separate github repository [here](https://github.com/psychgen/moba-trio-analyses).

## Directory structure

* [qc-scripts](qc-scripts) - various tools and scripts written in R, python, perl, bash and SLURM scheduler
  used in the QC part of the pipeline (modules 0-4) and post-imputation QC.
  README files with information about what each script is used for can be found in the respective sub-directories.

* [imputation-jobs](imputation-jobs) - scripts and SLURM jobs used for phasing and imputation (modules 5-7).

* [pipeline-modules](pipeline-modules) - documentation of specific steps in each module of the QC and imputation pipeline, and undocumented shell scripts putting it all together. 

* [resources](resources) - overview of data resources used throughout the pipeline

## 3rd party software

External software dependencies used for this project are as follows:

```
plink v1.90b6.18 64-bit (16 Jun 2020)
plink2 v2.00a2.3LM 64-bit Intel (24 Jan 2020) 
king v2.2.5
BCFtools v1.9
qctool v2.0.8_rhel
cat-bgen v1.1.4
shapeit v2.r904
impute4.1.2_r300.3
impute_v2.3.2
flashpca_v2
  
R  4.0.5 
python 3.8.10
perl v5.32.1

gwas.sif, python3.sif, r.sif "COSGAP" containers from v1.0.0 release of [https://github.com/comorment/containers](https://github.com/comorment/containers/releases/tag/v1.0.0)
```

For details on COSGAP containers, see the [documentation](https://cosgap.readthedocs.io/en/latest) and the corresponding [GitHub repository](https://github.com/comorment/containers).

## Deprecated folder structure

The folder structure in this repository is re-organized, as original placement of files was inconsistent and not very thought through.
As older scripts, e.g. ``qc_m1.sh`` or ``qc_m2.sh``, may refer to obsolete location of the files, here is an overview of how files were relocated:

```
<old location>              <new location>
config                   -> qc-scripts/config
lib/*.R                  -> qc-scripts/R_scripts
tools/create-relplot.sh  -> qc-scripts/shell_scripts
software/*.py            -> qc-scripts/python_scripts
software/*.pl            -> qc-scripts/perl_scripts
jobs                     -> imputation-jobs
```

## Compute environment

The pipeline was developed and tested on [TSD](https://www.uio.no/english/services/it/research/sensitive-data/index.html) - the University of Oslo's trusted research environment for sensitive data.
The pipeline is designed to run on a SLURM-based HPC environment, and the scripts are written to be run in a containerized environment using Singularity or Apptainer.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.