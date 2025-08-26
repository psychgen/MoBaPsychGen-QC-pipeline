# Module X. Chromosome X QC

The steps in the “Chromosome X QC” are intended to be executed on each core subsample. As an example, the steps below use the European subsample as we will prioritize the European subsamples because they account for the majority of the MoBa cohort. Once you have finished QC-ing the European subsample, please re-run all the steps on other subsamples in your batch. Please keep the file names the same, except for the population indicator. We use “eur” to indicate a European subsample, please use “afr” and “asian” as indicators of African and Asian subsamples. When you read “record” in the instructions below, it means to fill out the google sheet named “MoBa\_QC\_numbers” that is created to keep track of the QC numbers for the report.


## Quality Control (QC) steps

Load PLINK module

Follow the same setup as described in module 1 step-by-step document , e.g. set `GITHUB=/ess/p697/data/durable/s3-api/github/norment/moba_qc_imputation`.

Unless otherwise specified, all commands are supposed to be run in your working directory (named with your initials) in DATA/DURABLE (see folder-structure-moba-2020.pdf)

All plots produced in this module should be copied to /tsd/p697/data/durable/projects/moba\_qc\_imputation/export/Module\_X\_Plots folder when indicated. “Record” in the instructions below refers to recording the numbers in MoBa\_QC\_numbers spreadsheet on Google drive, when indicated. Please contact Elizabeth if you have any doubts/questions about the process.


## FIRST ROUND

1. ### Harmonize and restrict to sex chromosomes

   1. Copy relevant batch bfiles from to your working directory\
      cp /ess/p697/cluster/projects/moba\_qc\_imputation/OF/chrX\_imputation/batches/original.\* /ess/p697/data/durable/projects/moba\_qc\_imputation/initials/ChrX/batch

2. ### Restrict to individuals passing autosome QC and update pedigree to match

   1. plink --bfile original --update-ids /ess/p697/data/durable/projects/moba\_qc\_imputation/resources/MoBa\_PsychGen\_v1\_update\_ids.txt --chr 23-25 --make-bed --out original-sex\_chr-initials-update-ids

   2. plink --bfile original-sex\_chr-initials-update-ids --keep /ess/p697/data/durable/projects/moba\_qc\_imputation/resources/MoBa\_PsychGen\_v1\_keep.txt  --update-parents /ess/p697/data/durable/projects/moba\_qc\_imputation/resources/MoBa\_PsychGen\_v1\_update\_parents.txt --make-bed --out original-sex\_chr-initials-keep

3. ### Split by chromosome and where relevant by sex

   1. Chr 23 females\
      plink --bfile original-sex\_chr-initials-keep --chr 23 --filter-females --make-bed --out original-initials-chr23-female

   2. Chr 23 males\
      plink --bfile original-sex\_chr-initials-keep --chr 23 --filter-males --make-bed --out original-initials-chr23-male

   3. Chr 24 females\
      plink --bfile original-sex\_chr-initials-keep --chr 24 --filter-females --make-bed --out original-initials-chr24-female

   4. Chr 24 males\
      plink --bfile original-sex\_chr-initials-keep --chr 24 --fillter-males --make-bed --out original-initials-chr24-male

   5. Chr 25 (females and males)\
      plink --bfile original-sex\_chr-initials-keep --chr 25 --make-bed --out original-initials-chr25

4. ### Basic QC

   1. #### MAF

      1. Chr23 females\
         plink --bfile original-initials-chr23-female --maf 0.005 --make-bed --out original-initials-chr23-female-common

      2. Chr23 males\
         plink --bfile original-initials-chr23-male --maf 0.005 --make-bed --out original-initials-chr23-male-common

      3. Chr 24 males\
         plink --bfile original-initials-chr24-male --maf 0.005 --make-bed --out original-initials-chr24-male-common

      4. Chr 25\
         plink --bfile original-initials-chr25 --maf 0.005 --make-bed --out original-initials-chr25-common

   2. #### Call rates

      1. Chr 23 females\
         plink --bfile original-initials-chr23-female-common --missing --out original-initials-chr23-female-missing\
         Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr23-female-missing "original females, chromosome X"\
         plink --bfile original-initials-chr23-female-common --geno 0.05 --make-bed --out original-initials-chr23-female-95\
         plink --bfile original-initials-chr23-female-95 --geno 0.02 --make-bed --out original-initials-chr23-female-98\
         plink --bfile original-initials-chr23-female-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr23-female-call-rates

      2. Chr 23 males\
         plink --bfile original-initials-chr23-male-common --missing --out original-initials-chr23-male-missing\
         Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr23-male-missing "original males, chromosome X"\
         plink --bfile original-initials-chr23-male-common --geno 0.05 --make-bed --out original-initials-chr23-male-95\
         plink --bfile original-initials-chr23-male-95 --geno 0.02 --make-bed --out original-initials-chr23-male-98\
         plink --bfile original-initials-chr23-male-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr23-male-call-rates

   3. Chr 24 males\
      plink --bfile original-initials-chr24-male-common --missing --out original-initials-chr24-male-missing\
      Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr24-male-missing "original males, chromosome Y"\
      plink --bfile original-initials-chr24-male-common --geno 0.05 --make-bed --out original-initials-chr24-male-95\
      plink --bfile original-initials-chr24-male-95 --geno 0.02 --make-bed --out original-initials-chr24-male-98\
      plink --bfile original-initials-chr24-male-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr24-male-call-rates

   4. Chr 25\
      plink --bfile original-initials-chr25-common --missing --out original-initials-chr25-missing\
      Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr25-missing "original, chromosome XY"\
      plink --bfile original-initials-chr25-common --geno 0.05 --make-bed --out original-initials-chr25-95\
      plink --bfile original-initials-chr25-95 --geno 0.02 --make-bed --out original-initials-chr25-98\
      plink --bfile original-initials-chr25-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr25-call-rates

   5. #### HWE

      1. Chr 23 females\
         plink --bfile original-initials-chr23-female-call-rates --hwe 0.000001 --make-bed --out original-initials-chr23-female-basic-qc

      2. Chr 23 males\
         plink --bfile original-initials-chr23-male-call-rates --hwe 0.000001 --make-bed --out original-initials-chr23-male-basic-qc

      3. Chr 24 males\
         plink --bfile original-initials-chr24-male-call-rates --hwe 0.000001 --make-bed --out original-initials-chr24-male-basic-qc

      4. Chr 25\
         plink --bfile original-initials-chr25-call-rates --hwe 0.000001 --make-bed --out original-initials-chr25-basic-qc

   6. #### Hetrozygosity

Unless distribution is non-normal don't remove individuals  - instead rely on checks performed in autosome QC 

1. Only run in chr 25\
   plink --bfile original-initials-chr25-basic-qc --het --missing --out original-initials-chr25-het-miss\
   Rscript $GITHUB/lib/plot-heterozygosity-common.R original-initials-chr25-het-miss "original, chromosome XY"\
   tail -n +2 original-initials-chr25-het-miss-het-fail.txt | wc -l

5) ### Sex check

   1. #### Merge all sex chromosomes

      1. Create SNP list\
         R\
         library(data.table)\
         f <- fread('original-initials-chr23-female-basic-qc.bim', h=F)\
         m <- fread('original-initials-chr23-male-basic-qc.bim', h=F)\
         f <- f\[,2]\
         m <- m\[,2]\
         overlap <- merge(f, m, by="V2")\
         m24 <- fread('original-initials-chr24-male-basic-qc.bim', h=F)\
         m24 <- m24\[,2]\
         par <- fread('original-initials-chr25-basic-qc.bim')\
         par <- par\[,2]\
         snps <- rbind(overlap, m24, par)\
         fwrite(snps, 'original-initials-chr23-24-25-keep.snps', quote=F, row\.names=F, col.names=F, sep='\t')\
         rm(f, m, overlap, m24, snps, par)

      2. Create individual list\
         m23 <- fread('original-initials-chr23-male-basic-qc.fam',h=F)\
         m24 <- fread('original-initials-chr24-male-basic-qc.fam',h=F)\
         m23 <- m23\[,c(1:2)]\
         m24 <- m24\[,c(1:2)]\
         m <- merge(m23, m24, by=c("V1","V2"))\
         f23 <- fread('original-initials-chr23-female-basic-qc.fam',h=F)\
         f23 <- f23\[,c(1:2)]\
         ind <- rbind(f23, m)\
         par <- fread('original-initials-chr25-basic-qc.fam',h=F)\
         par <- par\[,c(1:2)]\
         keep <- merge(ind, par, by=c("V1","V2"))\
         fwrite(keep, 'original-initials-chr23-24-25-keep.ind', quote=F, row\.names=F, col.names=F, sep='\t')\
         q()

      3. Create merge list\
         cat > original-initials-chr23-24-25\_merge.txt\
         original-initials-chr23-female-basic-qc\
         original-initials-chr23-male-basic-qc\
         original-initials-chr24-male-basic-qc\
         original-initials-chr24-female\
         original-initials-chr25-basic-qc\
         \<Control D>

      4. PLINK merge\
         plink --merge-list original-initials-chr23-24-25\_merge.txt --keep original-initials-chr23-24-25-keep.ind --extract original-initials-chr23-24-25-keep.snps --make-bed --out original-initials-chr23-24-25-basic-qc

   2. #### Run sex check

      1. Regular sex check based on chr x only\
         plink --bfile original-initials-chr23-24-25-basic-qc --check-sex --out original-initials-chr23-24-25-sex-check

      2. Sex check based on y chromosome data\
         plink --bfile original-initials-chr23-24-25-basic-qc --check-sex y-only --out original-initials-chr23-24-25-sex-check-y-only

      3. Merge output from chr x and y plus missingness information\
         plink --bfile original-initials-chr23-24-25-basic-qc --missing --out original-initials-chr23-24-25-miss\
         ./match.pl -f original-initials-chr23-24-25-sex-check-y-only.sexcheck -g original-initials-chr23-24-25-sex-check.sexcheck -k 2 -l 2 -v 6 > original-initials-chr23-24-25.sexcheck\
         ./match.pl -f original-initials-chr23-24-25-miss.imiss -g original-initials-chr23-24-25.sexcheck -k 2 -l 2 -v 6 > original-initials-chr23-24-25-sex-plot.txt

      4. Create plot\
         Rscript $GITHUB/lib/plot-sex.R original-initials-chr23-24-25-sex-plot.txt "original, chromosome X" topleft original-initials-chr23-24-25-sex-plot.png

      5. Identify individuals to remove\
         awk '$3!=0 && $5=="PROBLEM" {print $0}' original-initials-chr23-24-25-sex-plot.txt > original-initials-chr23-24-25-bad-sex.txt\
         wc -l original-initials-chr23-24-25-bad-sex.txt\
         plink --bfile original-initials-chr23-24-25-basic-qc --remove original-initials-chr23-24-25-bad-sex.txt --make-bed --out original-initials-chr23-24-25-pass-sex-check

6) ### ME

   1. All sex chromosomes\
      plink --bfile original-initials-chr23-24-25-pass-sex-check --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out original-initials-chr23-24-25-me

7) ### Plate effects

   1. Create shuffled sex phenotype\
      echo -e "FID\tIID\tPHENO" > original-initials-chr23-24-25-shuffle\_sex.txt\
      paste <(cut -d' ' -f1,2 original-initials-chr23-24-25-me.fam | tr ' ' $'\t') <(cut -f5 -d' ' original-initials-chr23-24-25-me.fam | shuf --random-source <(yes "moba")) >> original-initials-chr23-24-25-shuffle\_sex.txt

   2. Create plate file\
      ./match.pl -f ARRAY-plates.txt -g original-initials-chr23-24-25-me.fam -k 1 -l 2 -v 3 | awk '$7!="-" {print $0}' | sort -k 7 | awk '{print $1,$2,$7}' > original-initials-chr23-24-25-plates.txt

   3. Run mh2 test\
      plink --bfile original-initials-chr23-24-25-me --filter-founders --pheno original-initials-chr23-24-25-shuffle\_sex.txt --within original-initials-chr23-24-25-plates.txt --mh2 --out original-initials-chr23-24-25-mh-plates

   4. Create QQ plot\
      Rscript $GITHUB/lib/plot-qqplot.R original-initials-chr23-24-25-mh-plates.cmh2 "original, sex chromosomes" 5 original-initials-chr23-24-25-mh-plates-qq-plot

   5. Identify SNPs to remove\
      sort -k 5 -g original-initials-chr23-24-25-mh-plates.cmh2 | grep -v "NA" > original-initials-chr23-24-25-mh-plates-sorted\
      awk '$5<0.001 {print $2}' original-initials-chr23-24-25-mh-plates-sorted > original-initials-chr23-24-25-mh-plates-significant\
      wc -l original-initials-chr23-24-25-mh-plates-significant

   6. Exclude SNPs\
      plink --bfile original-initials-chr23-24-25-me --exclude original-initials-chr23-24-25-mh-plates-significant --make-bed --out original-initials-chr23-24-25-batch


## SECOND ROUND

8. ### Split by chromosome and where relevant by sex

   1. Chr 23 females\
      plink --bfile original-initials-chr23-24-25-batch --chr 23 --filter-females --make-bed --out original-initials-chr23-female-2

   2. Chr 23 males\
      plink --bfile original-initials-chr23-24-25-batch --chr 23 --filter-males --make-bed --out original-initials-chr23-male-2

   3. Chr 24 females\
      plink --bfile original-initials-chr23-24-25-batch --chr 24 --filter-females --make-bed --out original-initials-chr24-female-2

   4. Chr 24 males\
      plink --bfile original-initials-chr23-24-25-batch --chr 24 --filter-males --make-bed --out original-initials-chr24-male-2

   5. Chr 25\
      plink --bfile original-initials-chr23-24-25-batch --chr 25 --make-bed --out original-initials-chr25-2

9. ### Basic QC

   1. #### MAF

      1. Chr 23 females\
         plink --bfile original-initials-chr23-female-2 --maf 0.005 --make-bed --out original-initials-chr23-female-2-common

      2. Chr 23 males\
         plink --bfile original-initials-chr23-male-2 --maf 0.005 --make-bed --out original-initials-chr23-male-2-common

      3. Chr 24 males\
         plink --bfile original-initials-chr24-male-2 --maf 0.005 --make-bed --out original-initials-chr24-male-2-common

      4. Chr 25\
         plink --bfile original-initials-chr25-2 --maf 0.005 --make-bed --out original-initials-chr25-2-common

   2. #### Call rates

      1. Chr 23 females\
         plink --bfile original-initials-chr23-female-2-common --missing --out original-initials-chr23-female-2-missing\
         Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr23-female-2-missing "original females, chromosome X"\
         plink --bfile original-initials-chr23-female-2-common --geno 0.05 --make-bed --out original-initials-chr23-female-2-95\
         plink --bfile original-initials-chr23-female-2-95 --geno 0.02 --make-bed --out original-initials-chr23-female-2-98\
         plink --bfile original-initials-chr23-female-2-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr23-female-2-call-rates

      2. Chr 23 males\
         plink --bfile original-initials-chr23-male-2-common --missing --out original-initials-chr23-male-2-missing\
         Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr23-male-2-missing "original males, chromosome X"\
         plink --bfile original-initials-chr23-male-2-common --geno 0.05 --make-bed --out original-initials-chr23-male-2-95\
         plink --bfile original-initials-chr23-male-2-95 --geno 0.02 --make-bed --out original-initials-chr23-male-2-98\
         plink --bfile original-initials-chr23-male-2-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr23-male-2-call-rates

      3. Chr 24 males\
         plink --bfile original-initials-chr24-male-2-common --missing --out original-initials-chr24-male-2-missing\
         Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr24-male-2-missing "original males, chromosome Y"\
         plink --bfile original-initials-chr24-male-2-common --geno 0.05 --make-bed --out original-initials-chr24-male-2-95\
         plink --bfile original-initials-chr24-male-2-95 --geno 0.02 --make-bed --out original-initials-chr24-male-2-98\
         plink --bfile original-initials-chr24-male-2-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr24-male-2-call-rates

      4. Chr 25\
         plink --bfile original-initials-chr25-2-common --missing --out original-initials-chr25-2-missing\
         Rscript $GITHUB/lib/plot-missingness-histogram.R original-initials-chr25-2-missing "original, chromosome XY"\
         plink --bfile original-initials-chr25-2-common --geno 0.05 --make-bed --out original-initials-chr25-2-95\
         plink --bfile original-initials-chr25-2-95 --geno 0.02 --make-bed --out original-initials-chr25-2-98\
         plink --bfile original-initials-chr25-2-98 --geno 0.02 --mind 0.02 --make-bed --out original-initials-chr25-2-call-rates

   3. #### HWE

      1. Chr 23 female\
         plink --bfile original-initials-chr23-female-2-call-rates --hwe 0.000001 --make-bed --out original-initials-chr23-female-2-basic-qc

      2. Chr 23 male\
         plink --bfile original-initials-chr23-male-2-call-rates --hwe 0.000001 --make-bed --out original-initials-chr23-male-2-basic-qc

      3. Chr 24 males\
         plink --bfile original-initials-chr24-male-2-call-rates --hwe 0.000001 --make-bed --out original-initials-chr24-male-2-basic-qc

      4. Chr 25\
         plink --bfile original-initials-chr25-2-call-rates --hwe 0.000001 --make-bed --out original-initials-chr25-2-basic-qc

   4. #### Hetrozygosity

Unless distribution is non-normal don't remove individuals  - instead rely on checks performed in autosome QC

1. Chr 25\
   plink --bfile original-initials-chr25-2-basic-qc --het --missing --out original-initials-chr25-2-het-miss\
   Rscript $GITHUB/lib/plot-heterozygosity-common.R original-initials-chr25-2-het-miss "original, chromosome XY"\
   tail -n +2 original-initials-chr25-2-het-miss-het-fail.txt | wc -l

10) ### Sex check

    1. #### Merge all sex chromosomes

       1. Create SNP list\
          R\
          library(data.table)\
          f <- fread('original-initials-chr23-female-2-basic-qc.bim', h=F)\
          m <- fread('original-initials-chr23-male-2-basic-qc.bim', h=F)\
          f <- f\[,2]\
          m <- m\[,2]\
          overlap <- merge(f, m, by="V2")\
          m24 <- fread('original-initials-chr24-male-2-basic-qc.bim', h=F)\
          m24 <- m24\[,2]\
          par <- fread('original-initials-chr25-2-basic-qc.bim')\
          par <- par\[,2]\
          snps <- rbind(overlap, m24, par)\
          fwrite(snps, 'original-initials-chr23-24-25-2-keep.snps', quote=F, row\.names=F, col.names=F, sep='\t')\
          rm(f, m, overlap, m24, snps, par)

       2. Create individual list\
          m23 <- fread('original-initials-chr23-male-2-basic-qc.fam',h=F)\
          m24 <- fread('original-initials-chr24-male-2-basic-qc.fam',h=F)\
          m23 <- m23\[,c(1:2)]\
          m24 <- m24\[,c(1:2)]\
          m <- merge(m23, m24, by=c("V1","V2"))\
          f23 <- fread('original-initials-chr23-female-2-basic-qc.fam',h=F)\
          f23 <- f23\[,c(1:2)]\
          ind <- rbind(f23, m)\
          par <- fread('original-initials-chr25-2-basic-qc.fam',h=F)\
          par <- par\[,c(1:2)]\
          keep <- merge(ind, par, by=c("V1","V2"))\
          fwrite(keep, 'original-initials-chr23-24-25-2-keep.ind', quote=F, row\.names=F, col.names=F, sep='\t')\
          q()

       3. Create merge list\
          cat > original-initials-chr23-24-25-2\_merge.txt\
          original-initials-chr23-female-2-basic-qc\
          original-initials-chr23-male-2-basic-qc\
          original-initials-chr24-male-2-basic-qc\
          original-initials-chr24-female-2\
          original-initials-chr25-2-basic-qc\
          \<Control D>

       4. PLINK merge\
          plink --merge-list original-initials-chr23-24-25-2\_merge.txt --keep original-initials-chr23-24-25-2-keep.ind --extract original-initials-chr23-24-25-2-keep.snps --make-bed --out original-initials-chr23-24-25-2-basic-qc

    2. #### Run sex check

       1. Regular sex check based on chr x only\
          plink --bfile original-initials-chr23-24-25-2-basic-qc --check-sex --out original-initials-chr23-24-25-2-sex-check

       2. Sex check based on y chromosome data\
          plink --bfile original-initials-chr23-24-25-2-basic-qc --check-sex y-only --out original-initials-chr23-24-25-2-sex-check-y-only

       3. Merge output from chr x and y plus missingness information\
          plink --bfile original-initials-chr23-24-25-2-basic-qc --missing --out original-initials-chr23-24-25-2-miss\
          ./match.pl -f original-initials-chr23-24-25-2-sex-check-y-only.sexcheck -g original-initials-chr23-24-25-2-sex-check.sexcheck -k 2 -l 2 -v 6 > original-initials-chr23-24-25-2.sexcheck\
          ./match.pl -f original-initials-chr23-24-25-miss.imiss -g original-initials-chr23-24-25-2.sexcheck -k 2 -l 2 -v 6 > original-initials-chr23-24-25-2-sex-plot.txt

       4. Create plot\
          Rscript $GITHUB/lib/plot-sex.R original-initials-chr23-24-25-2-sex-plot.txt "original, chromosome X" topleft original-initials-chr23-24-25-2-sex-plot.png

    3. Identify individuals to remove\
       awk '$3!=0 && $5=="PROBLEM" {print $0}' original-initials-chr23-24-25-2-sex-plot.txt > original-initials-chr23-24-25-2-bad-sex.txt\
       wc -l original-initials-chr23-24-25-2-bad-sex.txt\
       plink --bfile original-initials-chr23-24-25-2-basic-qc --remove original-initials-chr23-24-25-2-bad-sex.txt --make-bed --out original-initials-chr23-24-25-2-pass-sex-check

11) ### ME

    1. All sex chromosomes\
       plink --bfile original-initials-chr23-24-25-2-pass-sex-check --me 0.05 0.01 --set-me-missing --mendel-duos --make-bed --out original-initials-chr23-24-25-2-me

12) ### Plate effects

    1. Create plate file\
       ./match.pl -f ARRAY-plates.txt -g original-initials-chr23-24-25-2-me.fam -k 1 -l 2 -v 3 | awk '$7!="-" {print $0}' | sort -k 7 | awk '{print $1,$2,$7}' > original-initials-chr23-24-25-2-plates.txt

    2. Run mh2 test (using original shuffled sex phenotype)\
       plink --bfile original-initials-chr23-24-25-2-me --filter-founders --pheno original-initials-chr23-24-25-shuffle\_sex.txt --within original-initials-chr23-24-25-2-plates.txt --mh2 --out original-initials-chr23-24-25-2-mh-plates

    3. Create QQ plot\
       Rscript $GITHUB/lib/plot-qqplot.R original-initials-chr23-24-25-2-mh-plates.cmh2 "original, sex chromosomes" 5 original-initials-chr23-24-25-2-mh-plates-qq-plot

    4. Identify SNPs to remove\
       sort -k 5 -g original-initials-chr23-24-25-2-mh-plates.cmh2 | grep -v "NA" > original-initials-chr23-24-25-2-mh-plates-sorted\
       awk '$5<0.001 {print $2}' original-initials-chr23-24-25-2-mh-plates-sorted > original-initials-chr23-24-25-2-mh-plates-significant\
       wc -l original-initials-chr23-24-25-2-mh-plates-significant

    5. Exclude SNPs\
       plink --bfile original-initials-chr23-24-25-2-me --exclude original-initials-chr23-24-25-2-mh-plates-significant --make-bed --out original-initials-chr23-24-25-2-batch
