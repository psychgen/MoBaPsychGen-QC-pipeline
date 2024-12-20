## Mitochondrial DNA haplotype estimation

A pipeline for mitohondria impuation is based on the [MitoImpute](https://github.com/sjfandrews/MitoImpute/tree/master), also see the original [paper](https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-021-04337-8).

Environment containing impute2, R and pyhton libraries required for the pipeline can be created using `micromamba` on linux machine with internet connection:

```
mkdir -p micromamba/root
cd micromamba
wget -qO- https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
export MAMBA_ROOT_PREFIX=${PWD}/root
eval "$(./bin/micromamba shell hook -s posix)"
micromamba activate
micromamba create -n mitoimp -c conda-forge python pandas matplotlib-base conda-pack \
    -c bioconda -c sjfandrews r-base=3.6.3 r-readxl r-tidyverse=1.3.0 r-devtools=2.3.2 \
    r-ggfittext=0.9.0 r-himc=0.1.1.5 impute2=2.3.2
micromamba activate mitoimp
conda-pack -p root/envs/mitoimp -o mitoimp.tar.gz
```

Then `mitoimp.tar.gz` file can be delivered to the server without internet connection (e.g. TSD) and deployed:
```
mkdir mitoimp
tar -zxf mitoimp.tar.gz -C mitoimp/
source mitoimp/bin/activate
conda-unpack
```

For any subsequent useage of the `mitoimp` environment, you only need to souce it `source mitoimp/bin/activate`.
