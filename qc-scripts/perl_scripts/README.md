## Contents

### HRC-1000G-check-bim.pl

Downloaded from https://www.well.ox.ac.uk/~wrayner/tools/, ``version HRC-1000G-check-bim-v4.2.13-NoReadKey.zip``

Program to check a QC'd plink .bim file against the HRC, 1000G or CAAPA reference SNP list in advance of imputation

### match.pl
**Function**
This script matches file one and file two on a specific key and then outputs a list of values from file one to file two.

**Usage** ``match.pl -f file1 -g filetwo -k 1 -l 2 -v 3 4 7``

**Options**
  * `-f` name of file one
  * `-g` name of file two
  * `-h` help
  * `-k` position of key in file one
  * `-l` position of key in file two
  * `-v` position of values in file one to be appended to file two
