## Overview of data resources

Files included in this repository:

```
1kg.fam - set of subjects from 1kG phase 1 (N=1083 subjects)
Respective 1kg.bim file hsa 11610488 SNPs.

high-ld.txt - list of high LD regions with their hg19 coordinates
```

Other resources to be download separately:

- HRC r1.1 reference files require application, then can be fetched from EGA, see [here](https://web2.ega-archive.org/datasets/EGAD00001002729/files)). For HRC r1.1 release notes see [here](https://imputationserver.sph.umich.edu/start.html#!pages/hrc-r1.1).

    ```
    #.{haplotypes.bcf.gz,haplotypes.bcf.gz.csi,legend.gz,samples}
    HRC/_egaz00001239271_hrc.r1-1.ega.grch37.chr4.*
    HRC/_egaz00001239270_hrc.r1-1.ega.grch37.chr3.*
    HRC/_egaz00001239269_hrc.r1-1.ega.grch37.chr2.*
    HRC/_egaz00001239268_hrc.r1-1.ega.grch37.chr1.noibd.*
    HRC/_egaz00001239292_hrc.r1-1.ega.grch37.chrx_par2.*
    HRC/_egaz00001239291_hrc.r1-1.ega.grch37.chrx_nonpar.*
    HRC/_egaz00001239290_hrc.r1-1.ega.grch37.chrx_par1.*
    HRC/_egaz00001239289_hrc.r1-1.ega.grch37.chr22.*
    HRC/_egaz00001239288_hrc.r1-1.ega.grch37.chr21.*
    HRC/_egaz00001239287_hrc.r1-1.ega.grch37.chr20.*
    HRC/_egaz00001239286_hrc.r1-1.ega.grch37.chr19.*
    HRC/_egaz00001239285_hrc.r1-1.ega.grch37.chr18.*
    HRC/_egaz00001239284_hrc.r1-1.ega.grch37.chr17.*
    HRC/_egaz00001239283_hrc.r1-1.ega.grch37.chr16.*
    HRC/_egaz00001239282_hrc.r1-1.ega.grch37.chr15.*
    HRC/_egaz00001239281_hrc.r1-1.ega.grch37.chr14.*
    HRC/_egaz00001239280_hrc.r1-1.ega.grch37.chr13.*
    HRC/_egaz00001239279_hrc.r1-1.ega.grch37.chr12.*
    HRC/_egaz00001239278_hrc.r1-1.ega.grch37.chr11.*
    HRC/_egaz00001239277_hrc.r1-1.ega.grch37.chr10.*
    HRC/_egaz00001239276_hrc.r1-1.ega.grch37.chr9.*
    HRC/_egaz00001239275_hrc.r1-1.ega.grch37.chr8.*
    HRC/_egaz00001239274_hrc.r1-1.ega.grch37.chr7.*
    HRC/_egaz00001239273_hrc.r1-1.ega.grch37.chr6.*
    HRC/_egaz00001239272_hrc.r1-1.ega.grch37.chr5.*
    ```

- HRC sites file (`HRC/HRC.r1-1.GRCh37.wgs.mac5.sites.tab.gz`) - was fetched from [here](http://www.haplotype-reference-consortium.org) but URL no longer works; this is a non-sensitive file listing alleles and their frequencies; see ``imputation-jobs/HRC_sites_download.sh`` for downloadable URLs.

- files specific to genotyping chips: 
    ```
    https://www.well.ox.ac.uk/~wrayner/strand/ABtoTOPstrand.html
    humancoreexome-12v1-1_A.update_alleles
    humancoreexome-24v1-0_A.update_alleles
    GSA-24v1-0_C2_b150_rsids_unique.txt
    GSA-24v3-0_A1_b151_rsids_unique.txt
    
    pchip_blackList_dec2015_stripped.txt
    ```

-  LiftOver chain files - https://hgdownload.soe.ucsc.edu/goldenPath/hg38/liftOver/
    ```
    hg38ToHg19.over.chain.gz
    hg19ToHg38.over.chain.gz
    ```

- genetic maps 
    ```
    # wget https://mathgen.stats.ox.ac.uk/impute/1000GP_Phase3/genetic_map_chr$i_combined_b37.txt # i=1..22, X_PAR1, X_PAR2, X_nonPAR
    genetic_map_chr@_combined_b37.txt
    ```
