# Module 6. Phasing

The steps in the &quot;Phasing&quot; module are intended to be excuted on each merged dataset before imputation.

## Convert reference panel files to format compatible with the phasing software
For the MoBa data phasing was performed using the publically available HRC reference panel. As such, we needed to converte the original reference panel files to a format compatible with SHAPEIT2. The conversion was performed using the ``make_hrc_format_conversion_scripts.py`` python script. This only needs to be performed the first time the files are used for phasing with SHAPEIT2.

## Phasing
Whole chromosome phasing including the publically available HRC as the reference panel using the ``make_jobs.py`` python script with the following steps.
1. Define chunks of individulas using the following command ``python make_jobs.py ichunks --prefix chr@``.
Note how many chunks of individuals `ichunks` were generated. This could be confusing: phasing is going to be executed without forming chunks of individuals, but the result of phasing is then split into chunks using the `shapeit2 --convert` command.
2. Generate phasing job files using the following command ``python make_jobs.py shapeit2 --prefix chr@ --hours 168 --num-ichunks <N>``
3. Submit the phasing job for each chromosome run on the HPC using the following command ``sbatch shapeit2_chrNN.job``. The `NN` is updated to the chromosome number. The jobs will take between 1 and 3 days to finish (for a N=30K batch). Alternatively if submitting all autosome phasing jobs at once the following commands can be used:
```
for ((NN=1; NN<=22; NN++)); do
sbatch shapeit2_chr${NN}.job  
done
```

NOTE: The chunks of individuals `ichunks` have individuals re-shuffled to guarantee that families were not split across imputation chunks. A new chr@.ichunk_merged.fam file was generated at step 2 listing the new order of individuals.
