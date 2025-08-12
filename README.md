# MoBaPsychGen QC pipeline code and documentation repository for manuscript entitled “Unique opportunities to study health and behavior in genotyped family cohorts”

## Overview

This repository is home to documentation and code for the MoBaPsychGen QC pipeline. This pipeline was developed for and applied to genotype data from the Norwegian Mother, Father, and Child Cohort study (MoBa).

The pipeline is described in the [preprint](https://doi.org/10.1101/2022.06.23.496289) entitled: "The Norwegian Mother, Father, and Child cohort study (MoBa) genotyping data resource: MoBaPsychGen pipeline v.1" and manuscript entitled “Unique opportunities to study health and behavior in genotyped family cohorts”. The latest reference should be cited by work based on either the data, procedures, or code from the MoBaPsychGen QC pipeline. 

## Structure

* [qc-modules](qc-modules) - Documents with listing QC steps of each module.
* [scripts](scripts) - Scripts used throughout the QC pipeline.

Analytic code for the exemplar trio analyses are available [here](https://github.com/psychgen/moba-trio-analyses).

## 3rd party

External software dependencies not included in this repository:

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
  
R  4.0.5 
python 3.8.10
perl v5.32.1

gwas.sif, python3.sif, R.sif containers from v1.0.0 release of https://github.com/comorment/containers
```
