# Module 5. Pre-phasing QC

These steps are run using the ``imputation-scripts/PRE_PHASING_QC.job`` SLURM job, followed by ``imputation-scripts/pre_phasing_qc_report.py``.

The steps are intended to be excuted on each merged dataset to ensure the data matches the reference pannel.

Pre-phasing QC does not exclude any individuals. Therefore, pre-phasing QC report describes the changes at SNP level - how many SNPs were excluded (and why), how many got a new rs#, flip strand, etc.

## Pre-phasing QC steps

1. Remove all duplicate variants, all indels and all strand ambiguous SNPs (A/T and C/G)
2. Zero out all Mendelian errors
3. Check the call rates and HWE (remove individuals and SNPs with call rate below 98% and remove SNPs with HWE p<1.00x10-6)
4. Remove the SNPs not present in HRC (Oxford perl script can be used for this)
5. Remove SNPs with allele freq differences between a MoBa batch and HRC that are more than |0.2| (Oxford perl script can be used for this). Make a scatter plot of allele frequencies with MoBa batch on X axis and HRC on the Y axis.
6. Remove SNPs with alleles different to HRC (Oxford perl script can be used for this)
7. Flip the strand where needed (Oxford perl script can be used for this)
8. Update SNP IDs to match those in HRC (Oxford perl script can be used for this)
9. Change ref/alt allele assignments where needed (Oxford perl script can be used for this)

Steps to run the script as as follows:

1. Copy input bfile to /cluster/projects/p697/projects/moba\_qc\_imputation/OF/<batch>, where <batch> is the name of the imputation batch (i.e. HCE, OMNI, GSA, or similar). This folder will be referred to as <ROOT>. 
1. Copy PRE\_PHASING\_QC.job to the <ROOT> folder.
1. Edit PRE\_PHASING\_QC.job by changing  “hce-ec-eur-fin-pass-qc”  to the actual name of your input bfile
1. Run “sbatch PRE\_PHASING\_QC.job”. This may take approximately 10 minutes. 
1. Run “python pre_phasing_qc_report.py” to generate pre-phasing QC reports.
