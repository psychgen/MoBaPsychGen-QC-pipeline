## Contents

* [PRE_PHASING_QC.job](#pre_phasing_qcjob)
* [pre_phasing_qc_report.py](#pre_phasing_qc_reportpy)
* [make_hrc_format_conversion_scripts.py](#make_hrc_format_conversion_scriptspy)
* [make_jobs.py](#make_jobspy)

## Summary of scripts

### PRE_PHASING_QC.job
Contains the pre-phasing QC steps. The input to this script is one “bfile” in plink format (.bed/.bim/.fam), with approximately 400K-800K genetic variants.

### pre_phasing_qc_report.py
Generagtes a report describing how many SNPs were excluded during pre-phasing QC and why they were removed. Additionally the number of SNPs with updated IDs and strand flips, ect. is described.

### make_hrc_format_conversion_scripts.py
Converts original publically available HRC reference panel files to a format compatible with shapeit2.

### make_jobs.py
Generate phasing job files and defines chunks of individulas for imputation.


