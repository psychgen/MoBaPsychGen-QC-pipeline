## Contents

* [qc_m1.sh](#qc_m1sh)
* [qc_m2.sh](#qc_m2sh)
* [qc_chrX.sh](#qc_chrxsh)
* [PRE_PHASING_QC.job](#pre_phasing_qcjob)
* [pre_phasing_qc_report.py](#pre_phasing_qc_reportpy)

## Summary of scripts

### qc_m1.sh
This script performs module 0 and 1 of the QC pipeline.

### qc_m2.sh
This script performs module 0 and 1 of the QC pipeline.

### qc_chrX.sh
This script performs the chromosome X module of the QC pipeline.

### PRE_PHASING_QC.job
Contains the pre-phasing QC steps. The input to this script is one “bfile” in plink format (.bed/.bim/.fam), with approximately 400K-800K genetic variants.

### pre_phasing_qc_report.py
Generagtes a report describing how many SNPs were excluded during pre-phasing QC and why they were removed. Additionally the number of SNPs with updated IDs and strand flips, ect. is described.
