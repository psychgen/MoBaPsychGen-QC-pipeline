## Contents

This folder contains R, python, perl, bash, and HPC jobs scripts used to run perform the QC, phasing, imputation, and post-imputation QC. 

README files with information about what each script is used for can be found in each sub-directories.

This software was re-organized into a cleaner folder structure.
As older scripts may refer to obsolete location of the files, here is an overview of how files were relocated:

```
config                   -> scripts/config
lib/*.R                  -> scripts/R_scripts
tools/create-relplot.sh  -> scripts/shell_scripts
software/*.py            -> scripts/python_scripts
software/*.pl            -> scripts/perl_scripts
```
