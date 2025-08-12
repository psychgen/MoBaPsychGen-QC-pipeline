This folder contains scripts and SLURM jobs used to  merge dosage data for MoBaPsychGen_v1 release.

The steps were as follows:

1. Write the list of SNPs passing QC
   ```
   cat /cluster/projects/p697/genotype/MoBaPsychGen_v1/MoBaPsychGen_v1-ec-eur-batch-basic-qc.bim | cut -f 2 > MoBaPsychGen_v1-ec-eur-batch-basic-qc.snps
   ```

2. Write the list of samples passing QC; this also writes .sample file for each cohort, after renaming samples as defined in /cluster/projects/p697/genotype/MoBaPsychGen_v1/IID_Changes.txt
   ```
   python generate_sample_file.py
   ```

3. Select SNPs
   ```
   sbatch extract_release1_GSA.job
   sbatch extract_release1_HCE.job
   sbatch extract_release1_OMNI.job
   sbatch extract_GSA_may2021.job
   sbatch extract_Release3.job
   sbatch extract_Release4.job
   ```

4. Merge .bgen files across six batches, and extract samples passing QC. This script also converts from .bgen to .vcf. 
   ```
   sbatch merge_bgen.job
   ```

Done.

This produces a set of 22 .bgen, .sample and .vcf files, split across chromosomes.
Files hasn't been merged across chromosomes - due to large size it's more convenient to keep them separately.
The resulting file has genotype call probabilities - i.e. 3 values for each SNP for each subject.
Subjects are identified with SentrixID. Family information, MotherID and FatherID is not included in sample files - if you need this information, take it from .fam file (from hard calls).

