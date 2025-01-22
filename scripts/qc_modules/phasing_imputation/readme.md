## Contents

* [PRE_PHASING_QC.job](#Pre-Phasing_QC)
* [pre_phasing_qc_report.py](#Pre-phasing_report)

## Summary of R scripts

### PRE_PHASING_QC.job

**Function**
Contains the pre-phasing QC steps. The input to this script is one “bfile” in plink format (.bed/.bim/.fam), with approximately 400K-800K genetic variants.

### pre_phasing_qc_report.py

**Function**
Generagtes a report describing how many SNPs were excluded during pre-phasing QC and why they were removed. Additionally the number of SNPs with updated IDs and strand flips, ect. is described.
