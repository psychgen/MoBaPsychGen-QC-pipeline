# Module 5. Pre-phasing QC

This steps in the &quot;Pre-phasing QC&quot; are intended to be excuted on each merged dataset to ensure the data matches the reference pannel.

## Pre-phasing QC steps performed
1. Remove all duplicate variants, all indels and all strand ambiguous SNPs (A/T and C/G)
2. Zero out all Mendelian errors
3. Check the call rates and HWE (remove individuals and SNPs with call rate below 98% and remove SNPs with HWE p<1.00x10-6)
4. Remove the SNPs not present in HRC (Oxford perl script can be used for this)
5. Remove SNPs with allele freq differences between a MoBa batch and HRC that are more than |0.2| (Oxford perl script can be used for this). Make a scatter plot of allele frequencies with MoBa batch on X axis and HRC on the Y axis.
6. Remove SNPs with alleles different to HRC (Oxford perl script can be used for this)
7. Flip the strand where needed (Oxford perl script can be used for this)
8. Update SNP IDs to match those in HRC (Oxford perl script can be used for this)
9. Change ref/alt allele assignments where needed (Oxford perl script can be used for this)

Please inspect PLINK log files in each of the steps outlined above and make sure that the number of SNPs to which various changes were applied matches the expectation (e.g. if you have a list of 100 SNPs whose strand needs to be flipped, please make sure that all 100 are flipped).
Please record the numbers of SNPs altered/removed in each step outlined above. As a first, “quick-and-dirty” look, I’ve made a table of all the relevant numbers as produced by the Oxford perl script (this is just to give us an idea in which ball park the numbers are). The numbers are summarized in “number-of-allele-discrepancies-per-batch.xlsx” file, uploaded to this google folder. For some batches genotyped on Omni Express, there seem to be unusually high number of SNPs that need strand flipping. This needs to be investigated and the first steps would be to (1) double-check the MAF comparisons and (2) find out information about the strand (potentially present in GenomeStudio reports that were requested from Lavinia).  

These steps are run using the [PRE_PHASING_QC.job](https://github.com/psychgen/MoBaPsychGen-QC-pipeline/tree/main/scripts/qc_modules/phasing_imputation/PRE_PHASING_QC.job) script. The input to this script is one “bfile” in plink format (.bed/.bim/.fam), with approximately 400K-800K genetic variants.

## Pre-phasing QC report

Pre-phasing QC does not exclude any individuals. Therefore, pre-phasing QC report describes the changes at SNP level - how many SNPs were excluded (and why), how many got a new rs#, flip strand, etc.
The report is generated using the python [pre_phasing_qc_report.py](https://github.com/psychgen/MoBaPsychGen-QC-pipeline/tree/main/scripts/qc_modules/phasing_imputation/pre_phasing_qc_report.py) script.
