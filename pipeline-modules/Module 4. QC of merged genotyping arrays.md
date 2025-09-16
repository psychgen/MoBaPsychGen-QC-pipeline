# Module 4\. QC of merged core subsamples

The steps in Module 4 are intended to be executed on each merged dataset separately for each core-subsample. The steps are essentially the same as those in Module 2, as such, this document will detail the steps to run and any required variation.

# Quality Control (QC) steps

Load PLINK module

Follow the same setup as described in module 1 step-by-step document , e.g. set **GITHUB=/cluster/projects/p697/github/norment/moba\_qc\_imputation** if you work on machine with /cluster access (e.g. p697-submit), or **GITHUB=/tsd/p697/data/durable/s3-api/github/norment/moba\_qc\_imputation** if you work on a machine without /cluster access.

Unless otherwise specified, all commands are supposed to be run in your working directory (named with your initials) in DATA/DURABLE (see folder-structure-moba-2020.pdf)

All plots produced in this module should be copied to /tsd/p697/data/durable/projects/moba\_qc\_imputation/export/Module\_IV\_Plots folder when indicated. “Record” in the instructions below refers to recording the numbers in MoBa\_QC\_numbers spreadsheet on Google drive, when indicated. Please contact Elizabeth if you have any doubts/questions about the process.

# FIRST ROUND

1. ## Basic QC

   1. Run all of Module 2 step 1\.

2. ## Duplicates

QC of duplicates will only be done in the first round of this module if there are across batch duplicates. If there are no across batch duplicates proceed to step 3.To determine if your batch has across batch duplicates refer to the latest version of the /tsd/p697/data/durable/projects/moba\_qc\_imputation/resources/duplicates.xlsx file. If across array duplicates are in your batch do not run this step.

1. Run Module 2 step 3.1 and 3.2, making sure to use the final PLINK bfile produced in step 1\. With the added step of updating the hce\_duplicates.txt, omni\_duplicates.txt, or gsa\_duplicates.txt to include the updated FIDs. See command below:  
   ./match.pl \-f original-initials-eur-het.fam \-g hce\_duplicates.txt \-k 2 \-l 2 \-v 3 | awk {print $3, $2}’ \> hce\_duplicates\_kingFID.txt  
   2. We will impute both genotyping runs of the duplicates, however, some steps are need to be run without the duplicates (e.g., cryptic relatedness). Therefore, we need to create a list of one individual to remove from each duplicate pair. To do this run Module 2 step 3.3.

3. ## Unlinkable individuals

   1. If there has been a new unlinkable\_IDs.txt file created since Module 2 was run for all the batches, run Module 2 step 4 with the most uptodate file. To ensure any updated FIDs are accounted for run the following command:  
      ./match.pl \-f original-initials-eur-het.fam \-g unlinkable\_IDs.txt \-k 2 \-l 2 \-v 1 | awk ‘{print $3, $2}’ \> original-initials-unlinkable\_IDs.txt

4. ## Pedigree build and known relatedness

Since the number of individuals in the merged batches is so large we are no longer able to plot the whole pairwise-kinship distribution. To reduce the size of the output file we will use king225\_patch1, which is a customly modified "king" program that produces a smaller output file in "king \--ibs". Only individuals with kinship above 0.025 are reported.

1. Run all of Module 2 step 5 replacing king225 with king225\_patch1. Also make sure any updates to the FID are accounted for by running step 10.1.1.2.

5. ## PCA with 1000 Genomes (1KG)

PLINK can only handle running PCA with samples less than 50,000 individuals. Therefore, For the merged dataset we will be using FlashPCA2 ([https://academic.oup.com/bioinformatics/article/33/17/2776/3798630](https://academic.oup.com/bioinformatics/article/33/17/2776/3798630)). The path to the executable is: /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64

1. Run Module 2 steps 6.1 to 6.4.2  
   2. Create a list of founders  
      awk ‘$3==”parent” {print $0}’ original-initials-fam-populations.txt \> original-initials-eur-1kg-clean-merged-founders  
   3. Create PLINK bfile of founders keeping the allele order the same  
      plink \--bfile original-initials-eur-1kg-merged \--keep original-initials-eur-1kg-clean-merged-founders \--keep-allele-order \--make-bed \--out original-initials-eur-1kg-clean-merged-founders  
   4. Run the PCA  
      /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64 \--bfile original-initials-eur-1kg-clean-merged-founders \-d 20 \--outload original-initials-eur-1kg-founders-loadings.txt \--outmeansd original-initials-eur-1kg-founders-meansd.txt \--suffix \-original-initials-eur-1kg-founders-pca.txt \> original-initials-eur-1kg-founders-pca.log

      /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64 \--bfile original-initials-eur-1kg-clean-merged \-d 20 \--project \--inload  original-initials-eur-1kg-founders-loadings.txt \--inmeansd original-initials-eur-1kg-founders-meansd.txt \--outproj original-initials-eur-1kg-projections.txt \-v \> original-initials-eur-1kg-projections.log  
   5. Run Module 2 steps 6.5 to the end of step 6  
      1. For step 6.5.1 update the command “sort \-k2 original-initials-eur-1kg-pca.eigenvec \> original-initials-eur-1kg-pca-sorted” to:  
         tail \-n \+2 original-initials-eur-1kg-pca.eigenvec | sort \-k2 \> original-initials-eur-1kg-pca-sorted

6. ## PCA without 1KG

   1. Run Module 2 steps 7.1 to 7.2.2  
   2. Create a list of founders  
      awk ‘’$3==”parent” {print $0}’ original-initials-eur-1-keep-populations.txt \> original-initials-eur-1-dounders  
   3. Create PLINK bfile of founders keeping the allele order the same  
      plink \--bfile original-initials-eur-1-keep-trimmed \--make-bed –out original-initials-eur-1-keep-trimmed-founders  
   4. Run the PCA  
      /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64 \--bfile original-initials-eur-1-trimmed-founders \-d 20 \--outload original-initials-eur-1-founders-loadings.txt \--outmeansd original-initials-eur-1-founders-meansd.txt \--suffix \-original-initials-eur-1-founders-pca.txt \> original-initials-eur-1-founders-pca.log

      /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64 \--bfile original-initials-eur-1-trimmed \-d 20 \--project \--inload original-initials-eur-1-founders-loadings.txt \--inmeansd original-initials-eur-1-founders-meansd.txt \--outproj original-initials-eur-1-projections.txt \-v \> original-initials-eur-1-projections.log

      tail \-n \+2 original-initials-eur-1-projections.txt \> original-initials-eur-1-pca.eigenvec  
   5. Run Module 2 steps 7.3 to the end of step 7

# SECOND ROUND

7. ## Basic QC

   1. Run all of Module 2 step 8\.

8. ## Pedigree build and known relatedness

Since the number of individuals in the merged batches is so large we are no longer able to plot the whole pairwise-kinship distribution. To reduce the size of the output file we will use king225\_patch1, which is a customly modified "king" program that produces a smaller output file in "king \--ibs". Only individuals with kinship above 0.025 are reported.

1. Run all of Module 2 step 10 replacing king225 with king225\_patch1.

9. ## Cryptic relatedness

   1. Run all of Module 2 step 11

10. ## Mendelian errors

    1. Run all of Module 2 step 12

11. ## PCA with 1KG

PLINK can only handle running PCA with samples less than 50,000 individuals. Therefore, For the merged dataset we will be using FlashPCA2 ([https://academic.oup.com/bioinformatics/article/33/17/2776/3798630](https://academic.oup.com/bioinformatics/article/33/17/2776/3798630)). The path to the executable is: /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64

1. Run all of Module 2 step 13, updating to using FlashPCA2 as detailed in Module 4 step 5

12. ## PCA without 1KG

    1. Run all of Module 2 step 14, updating to using FlashPCA2 as detailed in Module 4 step 6

13. ## Batch effects

The plate effect check performed in Module 2 is updated to a batch effect check in Module 4\.

1. Run all of Module 2 step 15, updating to using FlashPCA2 for the PCA as previously described. Replacing the “HCE-plates.txt, GSA-plates.txt, or OMNI-plates.txt” files with the relevant “HCE-batches.txt, GSA-batches.txt, or OMNI-batches.txt” files.

# THIRD ROUND

14. ## Basic QC

The sex chromosome data has already been performed, therefore, run all of Module 2 step 16 from 16.2 onwards

15. ## Pedigree build and known relatedness

Since the number of individuals in the merged batches is so large we are no longer able to plot the whole pairwise-kinship distribution. To reduce the size of the output file we will use king225\_patch1, which is a customly modified "king" program that produces a smaller output file in "king \--ibs". Only individuals with kinship above 0.025 are reported.

1. Run all of Module 2 step 17 replacing king225 with king225\_patch1.

16. ## IBD estimation

    1. Run all of Module 2 step 18

17. ## Cryptic relatedness

    1. Run all of Module 2 step 19

18. ## Mendelian errors

    1. Run all of Module 2 step 20

19. ## PCA with 1KG

PLINK can only handle running PCA with samples less than 50,000 individuals. Therefore, For the merged dataset we will be using FlashPCA2 ([https://academic.oup.com/bioinformatics/article/33/17/2776/3798630](https://academic.oup.com/bioinformatics/article/33/17/2776/3798630)). The path to the executable is: /tsd/p697/data/durable/projects/moba\_qc\_imputation/software/flashpca\_x86-64

1. Run all of Module 2 step 21, updating to using FlashPCA2 as detailed in Module 4 step 5

20. ## PCA without 1KG

    1. Run all of Module 2 step 22, updating to using FlashPCA2 as detailed in Module 4 step 6

21. ## Batch effects

The plate effect check performed in Module 2 is updated to a batch effect check in Module 4\.

1. Run all of Module 2 step 23, updating to using FlashPCA2 for the PCA as previously described. Replacing the “HCE-plates.txt, GSA-plates.txt, or OMNI-plates.txt” files with the relevant “HCE-batches.txt, GSA-batches.txt, or OMNI-batches.txt” files.