# Module 7: Imputation

This document describes the following steps:
1. Imputation 
1. Merging imputation chunks across individuals
1. Compute per-SNP imputation INFO scores
1. Merging imputation chunks (dosage in .bgen format)
1. Convert dosages into hard calls format (plink’s format)
1. Filtering out SNPs based on MAF>=0.01 and INFO >=0.8
1. Merging hard calls across chromosomes 
1. Imputation report (also saves merged snp stats files to the result folder)

## Imputation using impute4

Steps to run imputation:

1. Run the following command to generate imputation .job files:

```
python make_jobs.py impute4 --prefix chr@ --hours 24 --num-ichunks <N>
```

1. Submit .job files by running Nx22 commands like this:

```
sbatch impute4_chrNN_ichunkXX.job  
```

Where XX corresponds to chunk number (varies from 1 to N). The previous step outputs Nx22 commands that can be copy-pasted and executed.

**(!) WARNING (!)** If there are too many jobs to execute (roughly Nx924, could exceed the TSD limit of 4500 jobs submitted to the queue per project). The solution is then to submit jobs for a few chromosomes at a time. For example, in order to run imputation jobs for first 5 chromosomes, you may run the following loop:
```
for ((NN=1; NN<=5; NN++)); do
    for ((XX=1; XX<=<N>; XX++)); do  
        sbatch impute4_chr${NN}_ichunk${XX}.job
    done
done
```

1. The jobs will take between 1 and 3 days to finish. We no longer expect jobs to fail due to “out of memory”, but if this happens you would need to re-generate failed jobs with increased memory limit. This can be done with “--missing-only” argument of the ``make_jobs.py impute4``:

```
python make_jobs.py impute4 --prefix chr@ --hours 48 --out impute4_chr@_4xMEM.job --mem-per-cpu 36000 --missing-only --num-ichunks <N>
```

1. Check that all batches exist, i.e. by counting the number of bgen files (``ls \*gen.gz | wc -l``), and comparing it to the number of chunks (``python make_jobs.py impute4 --prefix chr@ --num-ichunks <N> --out temp.job | grep Chunk | wc -l``)
## Merging imputation chunks across individuals
1. Re-generate all .job files by running the following:
```
python make_jobs.py impute4 --prefix chr@ --hours 24 --num-ichunks <N>
```
1. Submit .job files by running 22 commands like this:
```
sbatch impute4_chrNN_merge.job  
for ((NN=1; NN<=22; NN++)); do
    sbatch impute4_chr${NN}_merge.job  
done
```
The previous step outputs 22 commands that can be copy-pasted and executed. 

This step creates a set of .bgen files, and calculates imputation INFO scores using qctool. Due few duplicated rs# at the same CHR:BP we apply ``rename_multiallelic_snps.py`` to ensure a unique marker name. This is done before creating .bgen and INFO files - all of them have duplicated IDs replaced with ``CHR:BP_A1_A2 codes``. In total this affects about ~10.000 variants in HRC reference, the names for all other variants are kept unchanged.
## Merging imputation chunks (dosage data)
1. Re-generate “Makefile” file by running the following command:
```
python make_jobs.py impute4 --prefix chr@ --hours 48 --num-ichunks <N>
```
1. Copy <https://github.com/norment/moba_qc_imputation/blob/master/jobs/MERGE.job> to <ROOT> folder
1. Execute “sbatch MERGE.job” command.

The last step will convert from dosages (.bgen format) to hard calls (plink format), and merge INFO scores across imputation chunks. 
## Merging hard calls across chromosomes 
Submit the following script to merge the result across chromosomes: 

[https://github.com/norment/moba_qc_imputation/blob/master/jobs/](https://github.com/norment/moba_qc_imputation/blob/master/jobs/MERGE_PLINK_ALLCHR.job)[MERGE_PLINK_ALLCHR.job](https://github.com/norment/moba_qc_imputation/blob/master/jobs/MERGE_PLINK_ALLCHR.job)
## Imputation report

Change ``cohort`` variable in ``imputation_report.py`` script,
check that it points to correct path on the file system, and execute as ``python imputation_report.py``.