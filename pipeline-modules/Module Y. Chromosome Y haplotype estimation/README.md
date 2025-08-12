## Chromosome Y haplotype estimation

The pipeline for Y chromosome impuation is similar to the mitocondrial DNA pipeline using the gnomAD v3.1.2 as the reference panel, due to the lack of Y chromosome data in the HRC.

Haplogroups were then estimated using yHaplo31, which employs the ISOGG Y-DNA tree 2016 version (https://isogg.org/tree/2016/index16.html) with default settings, based on genotyped and imputed variants with INFO scores greater than 0.8.
