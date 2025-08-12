## Contents

This folder contains R, python, perl, bash, and HPC jobs scripts used to run perform the QC in modules 0,1,2,3, and post-imputation QC. 

README files with information about what each script is used for can be found in each sub-directories.

This software was re-organized into a cleaner folder structure.
As older scripts may refer to obsolete location of the files, here is an overview of how files were relocated:

```
config                   -> qc-scripts/config
lib/*.R                  -> qc-scripts/R_scripts
tools/create-relplot.sh  -> qc-scripts/shell_scripts
software/*.py            -> qc-scripts/python_scripts
software/*.pl            -> qc-scripts/perl_scripts
```

