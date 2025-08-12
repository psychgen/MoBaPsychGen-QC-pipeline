import os
import sys
import argparse
import pandas as pd
import numpy as np
import glob

script_header = """#!/bin/bash
#SBATCH --job-name={job_name}
#SBATCH --account={account}
#SBATCH --time={hours}:00:00
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu={mem_per_cpu}M
#SBATCH --cpus-per-task={cpus_per_task}
#SBATCH --array={array}

source /cluster/bin/jobsetup

# If you have other way of running PLINK2 and python software feel free to replace the set of commands below
module load singularity/3.7.1
module load Java/11.0.2
module load BCFtools/1.9-foss-2018b
export COMORMENT=/cluster/projects/p697/github/comorment
export SINGULARITY_BIND=""$COMORMENT/containers/reference:/REF:ro,/cluster/projects/p697:/cluster/projects/p697""
export SIF=$COMORMENT/containers/singularity
export PLINK="singularity exec --home $PWD:/home $SIF/gwas.sif plink"
export PLINK2="singularity exec --home $PWD:/home $SIF/gwas.sif plink2"
export PYTHON="singularity exec --home $PWD:/home $SIF/python3.sif python"

export MINIMAC4="singularity exec --home $PWD:/home /cluster/projects/p697/github/comorment/containers/singularity/gwas.sif minimac4"
export BEAGLE_CONFORM_GT=/cluster/projects/p697/projects/moba_qc_imputation/software/beagle_download/conform-gt.24May16.cee.jar
export BEAGLE=/cluster/projects/p697/projects/moba_qc_imputation/software/beagle_download/beagle.28Jun21.220.jar
export HRC=/cluster/projects/p697/projects/moba_qc_imputation/resources/HRC
export impute5=/cluster/projects/p697/projects/moba_qc_imputation/software/impute5_1.1.5_static
export hrc_prefix=_egaz00001239288_hrc.r1-1.ega.grch37.chr21.haplotypes

set -o errexit
"""

shapeit2_command = """
{shapeit2} -T 64 --input-bed {prefix} --input-map {input_map} --input-ref $HRC/haplegendsample/{hrc_prefix}.hap.gz $HRC/haplegendsample/{hrc_prefix}.legend.gz $HRC/haplegendsample/{hrc_prefix}.samples --duohmm -O {prefix}.phased --seed 54321 --output-log {prefix}.phased.log
{shapeit2} -convert --input-haps {prefix}.phased --output-vcf {prefix}.phased.vcf  --output-log {prefix}.phased.vcf.log
bgzip {prefix}.phased.vcf --stdout > {prefix}.phased.vcf.gz
bcftools index -t {prefix}.phased.vcf.gz
"""

shapeit2_convert_command = """
{shapeit2} -convert --input-haps {prefix}.phased --output-haps {prefix}.phased.ichunk{ichunk} --output-log {prefix}.phased.ichunk{ichunk}.log --include-ind ichunk{ichunk}.iid
{shapeit2} -convert --input-haps {prefix}.phased.ichunk{ichunk} --output-vcf {prefix}.phased.ichunk{ichunk}.vcf  --output-log {prefix}.phased.ichunk{ichunk}.vcf.log
bgzip {prefix}.phased.ichunk{ichunk}.vcf --stdout > {prefix}.phased.ichunk{ichunk}.vcf.gz
bcftools index -t {prefix}.phased.ichunk{ichunk}.vcf.gz
"""

minimac4_command = """
$MINIMAC4 --refHaps $HRC/m3vcf_copy/{hrc_prefix}.m3vcf.gz --haps {prefix}.phased.ichunk${{SLURM_ARRAY_TASK_ID}}.vcf --ChunkLengthMb 20 --ChunkOverlapMb 3 --prefix {prefix}.minimac4.ichunk${{SLURM_ARRAY_TASK_ID}} --cpus {cpus_per_task}

for T in 0.1 0.2 0.3 0.4; do
$PLINK2 --vcf {prefix}.minimac4.ichunk${{SLURM_ARRAY_TASK_ID}}.dose.vcf.gz dosage=DS --make-bed --out {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}} --hard-call-threshold $T
cat {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.bim | $PYTHON rename_all_snps.py {chr_label} > {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_snps.bim
cat {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.fam | $PYTHON rename_all_fams.py             > {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_subj.fam
mv {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_snps.bim {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.bim
mv {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_subj.fam {prefix}.minimac4.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.fam
done
"""

beagle5_command = """
java -jar $BEAGLE_CONFORM_GT ref=$HRC/vcf/{hrc_prefix}.vcf.gz gt={prefix}.phased.ichunk${{SLURM_ARRAY_TASK_ID}}.vcf out={prefix}.beagle5_conf.ichunk${{SLURM_ARRAY_TASK_ID}} chrom={chr_label} match=POS
java -Xmx52g -jar $BEAGLE gt={prefix}.beagle5_conf.ichunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz out={prefix}.beagle5.ichunk${{SLURM_ARRAY_TASK_ID}} ref=$HRC/vcf/{hrc_prefix}.vcf.gz window=40 overlap=2 seed=12345 nthreads={cpus_per_task} map=/cluster/projects/p697/projects/moba_qc_imputation/resources/genetic_maps/beagle/plink.chr{chr_label}.GRCh37.map

for T in 0.1 0.2 0.3 0.4; do
$PLINK2 --vcf {prefix}.beagle5.ichunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz dosage=DS --make-bed --out {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}  --hard-call-threshold $T
cat {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.bim | $PYTHON rename_all_snps.py {chr_label} > {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_snps.bim
cat {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.fam | $PYTHON rename_all_fams.py             > {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_subj.fam
mv {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_snps.bim {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.bim
mv {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.rename_subj.fam {prefix}.beagle5.hct_$T.ichunk${{SLURM_ARRAY_TASK_ID}}.fam
done
"""

# TBD: it's a good idea to replace 'imputed' with 'impute4' - this will be consistent with how we use other tools (impute5, minimac4, beagle) in file names
# TBD: consider using .vcf.gz instead of .vcf for phased genotypes for minimac4 and beagle5 imputation


impute4_command = """
declare -A CHUNKS=({chunks})
/cluster/projects/p697/projects/moba_qc_imputation/software/impute4.1.2_r300.3 -g {prefix}.phased.ichunk{ichunk}.haps -h $HRC/haplegendsample/{hrc_prefix}.hap.gz -l $HRC/haplegendsample/{hrc_prefix}.legend.gz -m {input_map} -o {prefix}.imputed.ichunk{ichunk}.chunk${{SLURM_ARRAY_TASK_ID}} -no_maf_align -o_gz -int ${{CHUNKS[${{SLURM_ARRAY_TASK_ID}}]}} -Ne 20000 -buffer 1000 -seed 54321
"""

impute4_merge_commands = """
{qctool} -g {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.gen.gz -snp-stats -osnp {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.snp.stats
{qctool} -g {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.gen.gz -og {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.bgen -os {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.sample
"""

impute5_merge_commands = """
#{qctool} -g {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz -og {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}.bgen -os {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}.sample -vcf-genotype-field DS

# https://www.cog-genomics.org/plink/2.0/input#oxford
# beware of this: you cannot use PLINK 2 to losslessly convert VCF FORMAT/GP data to e.g. BGEN format
$PLINK2 --vcf {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz dosage=DS --export bgen-1.2 --out {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}
"""

impute5_command = """
declare -A CHUNKS=({chunks})

$impute5 --h $HRC/imp5/{hrc_prefix}.imp5 --m {input_map} --g {prefix}.phased.ichunk{ichunk}.vcf.gz --r {chr_label}:${{CHUNKS[${{SLURM_ARRAY_TASK_ID}}]}} --o {prefix}.impute5.ichunk{ichunk}.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz --l {prefix}.impute5.ichunk{ichunk}.chunk${{SLURM_ARRAY_TASK_ID}}.log --b 1000 --threads 1
bcftools index -t {prefix}.impute5.ichunk{ichunk}.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz
"""

hrc_fname = """
_egaz00001239268_hrc.r1-1.ega.grch37.chr1.haplotypes.noibd
_egaz00001239269_hrc.r1-1.ega.grch37.chr2.haplotypes
_egaz00001239270_hrc.r1-1.ega.grch37.chr3.haplotypes
_egaz00001239271_hrc.r1-1.ega.grch37.chr4.haplotypes
_egaz00001239272_hrc.r1-1.ega.grch37.chr5.haplotypes
_egaz00001239273_hrc.r1-1.ega.grch37.chr6.haplotypes
_egaz00001239274_hrc.r1-1.ega.grch37.chr7.haplotypes
_egaz00001239275_hrc.r1-1.ega.grch37.chr8.haplotypes
_egaz00001239276_hrc.r1-1.ega.grch37.chr9.haplotypes
_egaz00001239277_hrc.r1-1.ega.grch37.chr10.haplotypes
_egaz00001239278_hrc.r1-1.ega.grch37.chr11.haplotypes
_egaz00001239279_hrc.r1-1.ega.grch37.chr12.haplotypes
_egaz00001239280_hrc.r1-1.ega.grch37.chr13.haplotypes
_egaz00001239281_hrc.r1-1.ega.grch37.chr14.haplotypes
_egaz00001239282_hrc.r1-1.ega.grch37.chr15.haplotypes
_egaz00001239283_hrc.r1-1.ega.grch37.chr16.haplotypes
_egaz00001239284_hrc.r1-1.ega.grch37.chr17.haplotypes
_egaz00001239285_hrc.r1-1.ega.grch37.chr18.haplotypes
_egaz00001239286_hrc.r1-1.ega.grch37.chr19.haplotypes
_egaz00001239287_hrc.r1-1.ega.grch37.chr20.haplotypes
_egaz00001239288_hrc.r1-1.ega.grch37.chr21.haplotypes
_egaz00001239289_hrc.r1-1.ega.grch37.chr22.haplotypes
""".split()
hrc_fname = {str(i+1):hrc_fname[i] for i in range(22)}

def add_slurm_arguments(parser, job_name, account, hours, mem_per_cpu, cpus_per_task):
    parser.add_argument("--job-name", default=job_name, type=str, help="SBATCH --job-name argument")
    parser.add_argument("--account", default=account, type=str, choices=['p697', 'p697_norment', 'p697_norment_dev', 'p697_tsd'], help="SBATCH --account argument")
    parser.add_argument("--hours", default=hours, type=int, help="SBATCH --time argument (in hours)")
    parser.add_argument("--mem-per-cpu", default=mem_per_cpu, type=int, help="SBATCH --mem-per-cpu argument (in megabytes)")
    parser.add_argument("--cpus-per-task", default=cpus_per_task, type=int, help="SBATCH --cpus-per-task argument")

def add_chr2use(parser):
    parser.add_argument("--chr2use", type=str, default="1-22",
        help=("Chromosome ids to user (e.g. 1,2,3 or 1-4,12,16-20 or 19-22,X,Y). "
              "The order in the figure will correspond to the order in this argument. "
              "Chromosomes with non-integer ids should be indicated separately. "))

def add_inpute_map(parser):
    parser.add_argument("--input-map", type=str, default="/cluster/projects/p697/projects/moba_qc_imputation/resources/1000Genomes/genetic_map_chr@_combined_b37.txt", help='input map, with @ indicating chromosome label')    

def process_args(args):
    arg_dict = vars(args)
    if 'chr2use' in arg_dict:
        chr2use_arg = arg_dict["chr2use"]
        if chr2use_arg is not None:
            chr2use = []
            for a in chr2use_arg.split(","):
                if "-" in a:
                    start, end = [int(x) for x in a.split("-")]
                    chr2use += [str(x) for x in range(start, end+1)]
                else:
                    chr2use.append(a.strip())
            arg_dict["chr2use"] = chr2use

def make_ichunk(args):
    chr2use = 1
    prefix = args.prefix.replace('@', str(chr2use))
    fname='{prefix}.fam'.format(prefix=prefix)
    fam=pd.read_csv(fname, delim_whitespace=True, header=None, names='FID IID  FatherID MotherID Sex Pheno'.split())
    if fam.duplicated('IID').any(): raise(ValueError('Found duplicated IID in .fam file, this is not supported'))
    fam.sort_values('FID', inplace=True)

    num_chunks = int(np.ceil(len(fam) / args.chunk_size))
    fids = fam['FID'].unique()

    np.random.seed(123)
    np.random.shuffle(fids)
    fid_chunks = np.array_split(fids, num_chunks)

    for idx, fid_chunk in enumerate(fid_chunks):
        fam.loc[fam['FID'].isin(fid_chunk), 'IID'].to_csv('ichunk{}.iid'.format(idx+1), header=None,index=False)
    print('chunkNNN.iid files were generated')

    # now we generate chr@.ichunk_merged.fam file, which follows the order of IIDs after phasing
    # first we read back original .fam file
    fam=pd.read_csv(fname, delim_whitespace=True, header=None, names='FID IID  FatherID MotherID Sex Pheno'.split())

    # now, we preserve the order of IIDs within each ichunk, and concatenate across chunks.
    fam_vec = []
    for ichunk in range(1, num_chunks+1):
        iid_ichunk = pd.read_csv(f'ichunk{ichunk}.iid', header=None, names=['IID'])
        iid_ichunk['isin'] = 1
        fam_vec.append(pd.merge(fam, iid_ichunk, on='IID', how='left').dropna(subset=['isin']).drop(columns=['isin']))
    pd.concat(fam_vec).reset_index(drop=True).to_csv('chr@.ichunk_merged.fam',sep='\t',header=None,index=False)

    print('Done. {num_chunks} chunks generated. Use "--num-ichunks {num_chunks}" in your subsequent commands.'.format(num_chunks=num_chunks))
    print('chr@.ichunk_merged.fam file was generated. This file gives the order of individuals after phasing, which is different from the order before phasing as same FIDs are kept in the same chunk.')

def make_shapeit2(args):
    if not args.prefix: raise(ValueError('--prefix is required'))
    for chr_label in args.chr2use:
        command = ""
        command += script_header.format(job_name=args.job_name.replace('@', chr_label), account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array='999') 
        command += shapeit2_command.format(shapeit2=args.shapeit2, prefix=args.prefix.replace('@', chr_label), input_map=args.input_map.replace('@', chr_label), hrc_prefix=hrc_fname[chr_label])
        for ichunk in range(1, args.num_ichunks + 1):
            command += shapeit2_convert_command.format(shapeit2=args.shapeit2, prefix=args.prefix.replace('@', chr_label), ichunk=ichunk)
        out_name = args.out.replace('@', chr_label) + '.job'
        with open(out_name, 'w') as f: f.write(command)
        print('sbatch {}'.format(out_name))


def make_beagle5(args):
    if not args.prefix: raise(ValueError('--prefix is required'))
    for chr_label in args.chr2use:
        command = ""
        command += script_header.format(job_name=args.job_name.replace('@', chr_label), account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array='1-{}'.format(args.num_ichunks))
        command += beagle5_command.format(prefix=args.prefix.replace('@', chr_label), hrc_prefix=hrc_fname[chr_label], chr_label=chr_label, cpus_per_task=args.cpus_per_task)
        out_name = args.out.replace('@', chr_label) + '.job'
        with open(out_name, 'w') as f: f.write(command)
        print('sbatch {}'.format(out_name))
    command = ""
    prefix=args.prefix.replace('@', '${SLURM_ARRAY_TASK_ID}')
    command += script_header.format(job_name='MERGE_BEAGLE5', account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array=','.join(args.chr2use))
    for hct in ['0.1', '0.2', '0.3', '0.4']:
        command += f"for ICHUNK in `seq 2 {args.num_ichunks}`; do echo {prefix}.beagle5.hct_{hct}.ichunk${{ICHUNK}}; done > chr${{SLURM_ARRAY_TASK_ID}}.beagle5.hct_{hct}.merge_list\n"
        command += f"$PLINK --bfile {prefix}.beagle5.hct_{hct}.ichunk1 --merge-list chr${{SLURM_ARRAY_TASK_ID}}.beagle5.hct_{hct}.merge_list --make-bed --out {prefix}.beagle5.hct_{hct}\n"
    with open("MERGE_BEAGLE5.job", 'w') as f: f.write(command)
    print('sbatch MERGE_BEAGLE5.job')

def make_minimac4(args):
    if not args.prefix: raise(ValueError('--prefix is required'))
    for chr_label in args.chr2use:
        command = ""
        command += script_header.format(job_name=args.job_name.replace('@', chr_label), account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array='1-{}'.format(args.num_ichunks))
        command += minimac4_command.format(prefix=args.prefix.replace('@', chr_label), hrc_prefix=hrc_fname[chr_label], chr_label=chr_label, cpus_per_task=args.cpus_per_task)
        out_name = args.out.replace('@', chr_label) + '.job'
        with open(out_name, 'w') as f: f.write(command)
        print('sbatch {}'.format(out_name))

    command = ""
    prefix=args.prefix.replace('@', '${SLURM_ARRAY_TASK_ID}')
    command += script_header.format(job_name='MERGE_MINIMAC4', account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array=','.join(args.chr2use))
    for hct in ['0.1', '0.2', '0.3', '0.4']:
        command += f"for ICHUNK in `seq 2 {args.num_ichunks}`; do echo {prefix}.minimac4.hct_{hct}.ichunk${{ICHUNK}}; done > chr${{SLURM_ARRAY_TASK_ID}}.minimac4.hct_{hct}.merge_list\n"
        command += f"$PLINK --bfile {prefix}.minimac4.hct_{hct}.ichunk1 --merge-list chr${{SLURM_ARRAY_TASK_ID}}.minimac4.hct_{hct}.merge_list --make-bed --out {prefix}.minimac4.hct_{hct}\n"
    with open("MERGE_MINIMAC4.job", 'w') as f: f.write(command)
    print('sbatch MERGE_MINIMAC4.job')

def make_merge2(args, num_chunks_per_chr):
    with open("Makefile", "w") as f:
        f.write("all: \n\techo 'make <fname>'\n\n")
        for impute_version in ['imputed', 'impute5']:
            chr_out_template = '{prefix}.{impute_version}.bgen'.format(prefix=args.prefix.replace('@', '{chri}'), impute_version=impute_version)

            for chri, num_chunks in num_chunks_per_chr:
                in_bgen = ' '.join(['{}.{}.chunk{}.bgen'.format(args.prefix.replace('@', str(chri)),impute_version,chunk) for chunk in range(1, num_chunks+1)])
                out_bgen = chr_out_template.format(chri=chri)
                f.write(f'{out_bgen}:\n\t/cluster/projects/p697/projects/moba_qc_imputation/software/cat-bgen -g {in_bgen} -og {out_bgen} -clobber\n\n')

def make_impute4(args):
    make_impute(args, impute_version='impute4')

def make_impute5(args):
    make_impute(args, impute_version='impute5')

def make_impute(args, impute_version):  # impute_version can be 'impute4' or 'impute5'
    if not args.prefix: raise(ValueError('--prefix is required'))

    chunk_def = {'chr':[], 'chunk':[], 'num_snps_in_chunk':[], 'a':[], 'b':[]}

    num_chunks_per_chr = []; sbatch_list = []
    for chr_label in args.chr2use:
        bim_fname = '{}.bim'.format(args.prefix).replace('@', chr_label)
        print('reading {}...'.format(bim_fname))
        bim=pd.read_csv(bim_fname, sep='\t', header=None, names='CHR SNP GP BP A1 A2'.split())
        from_mb=int((bim.BP.min()-1)/1e6); to_mb=int(bim.BP.max()/1e6)+1
        chunks=[(x, x+args.chunk_size_mb) for x in range(from_mb, to_mb, args.chunk_size_mb)]
        num_snps = [np.sum((bim.CHR.astype(str)==chr_label) & (bim.BP > a*1e6) & (bim.BP <= b*1e6)) for a, b in chunks]
        chunks =  [chunk for chunk, num_snps_per_chunk in zip(chunks, num_snps) if (num_snps_per_chunk > args.min_snps_per_chunk)]
        num_snps =[num_snps_per_chunk for num_snps_per_chunk in num_snps if (num_snps_per_chunk > args.min_snps_per_chunk)]
        print('chr{} has {} chunks'.format(chr_label, len(chunks)))
        num_chunks_per_chr.append((chr_label, len(chunks)))

        for index, ((a, b), num_snps_in_chunk) in enumerate(zip(chunks, num_snps)):
            chunk_def['chr'].append(chr_label)
            chunk_def['chunk'].append(index + 1)
            chunk_def['a'].append(a)
            chunk_def['b'].append(b)
            chunk_def['num_snps_in_chunk'].append(num_snps_in_chunk)

        for ichunk in range(1, args.num_ichunks + 1):
            print('ichunk{}: Number of SNPs per chunk:'.format(ichunk))
            gen_missing = []
            for index, ((a, b), num_snps_in_chunk) in enumerate(zip(chunks, num_snps)):
                gen_exists = os.path.exists('{prefix}.imputed.ichunk{ichunk}.chunk{chunk}.gen.gz'.format(prefix=args.prefix.replace('@', chr_label), chunk=index+1, ichunk=ichunk))
                if gen_exists:
                    if args.missing_only: continue
                else:
                    gen_missing.append(str(index + 1))
                print('Chr{}, ichunk {}, Chunk {}, {}-{} MB - {} SNPs ({})'.format(chr_label, ichunk, index+1, a, b, num_snps_in_chunk, 'imputation results for this chunk already exists' if gen_exists else 'imputation results for this chunk are currently missing'))

            if args.missing_only and len(gen_missing) == 0: continue
            array = ','.join(gen_missing) if args.missing_only else '1-{}'.format(len(chunks))

            # impute4 intervals are closed on both ends, i.e. both "a" and "b" will be included for [a, b] range
            if impute_version=='impute4': chunks_def = ' '.join(['[{}]="{}000001 {}000000"'.format(index+1, a, b) for index, (a, b) in enumerate(chunks)])
            if impute_version=='impute5': chunks_def = ' '.join(['[{}]="{}000001-{}000000"'.format(index+1, a, b) for index, (a, b) in enumerate(chunks)])   # use '-' instead of ' '

            imputeX_command = impute4_command if (impute_version=='impute4') else impute5_command

            command = ""
            command += script_header.format(job_name=args.job_name.replace('@', chr_label), account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array=array) 
            command += imputeX_command.format(prefix=args.prefix.replace('@', chr_label), input_map=args.input_map.replace('@', chr_label), hrc_prefix=hrc_fname[chr_label], chunks=chunks_def, chr_label=chr_label, ichunk=ichunk)

            out_name = args.out.replace('@', chr_label) + '_ichunk{}'.format(ichunk) + '.job'
            with open(out_name, 'w') as f: f.write(command)
            sbatch_list.append('sbatch {}'.format(out_name))

    for chr_label, num_chunks in num_chunks_per_chr:
        bgen_missing = []
        for index in range(num_chunks):
            if impute_version=='impute4': bgen_exists = os.path.exists('{prefix}.imputed.chunk{chunk}.bgen'.format(prefix=args.prefix.replace('@', chr_label), chunk=index+1))
            if impute_version=='impute5': bgen_exists = os.path.exists('{prefix}.impute5.chunk{chunk}.bgen'.format(prefix=args.prefix.replace('@', chr_label), chunk=index+1))
            if bgen_exists:
                if args.missing_only: continue
            else:
                bgen_missing.append(str(index + 1))

        if args.missing_only and len(bgen_missing) == 0: continue
        array = ','.join(bgen_missing) if args.missing_only else '1-{}'.format(num_chunks)

        prefix = args.prefix.replace('@', chr_label)
        command = ""
        command += script_header.format(job_name=args.job_name.replace('@', chr_label), account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=args.cpus_per_task, array=array) 
        command += "\nzcat {prefix}.imputed.ichunk1.chunk${{SLURM_ARRAY_TASK_ID}}.gen.gz | cut -d ' ' -f 1-5 | $PYTHON rename_multiallelic_snps.py {chr_label} > {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.renamed_snps".format(prefix=prefix,chr_label=chr_label)
        command += '\npaste <(cat {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.renamed_snps) \\\n'.format(prefix=prefix)
        command += " \\\n".join(["  <(cut -d ' ' -f 6- <(zcat {prefix}.imputed.ichunk{ichunk}.chunk${{SLURM_ARRAY_TASK_ID}}.gen.gz))".format(prefix=prefix, ichunk=ichunk) for ichunk in range(1, args.num_ichunks + 1)])
        command += " | sed 's/\\t/ /g' | gzip > {prefix}.imputed.chunk${{SLURM_ARRAY_TASK_ID}}.gen.gz".format(prefix=prefix)
        command += '\n'
        command += impute4_merge_commands.format(qctool=args.qctool, prefix=prefix, chr_label=chr_label)

        # overwrite cpus-per-task to 8 to give give enough memory to merge .vcf files
        command5 = ""
        command5 += script_header.format(job_name=args.job_name.replace('@', chr_label), account=args.account, hours=args.hours, mem_per_cpu=args.mem_per_cpu, cpus_per_task=8, array=array) 
        command5 += f"for ICHUNK in `seq 1 {args.num_ichunks}`; do echo {prefix}.impute5.ichunk${{ICHUNK}}.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz ; done > chr${{SLURM_ARRAY_TASK_ID}}.impute5.merge_list\n"
        command5 += f"bcftools merge --file-list chr${{SLURM_ARRAY_TASK_ID}}.impute5.merge_list -Oz -o {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz -m none\n"
        command5 += f"bcftools index -t {prefix}.impute5.chunk${{SLURM_ARRAY_TASK_ID}}.vcf.gz\n"
        command5 += impute5_merge_commands.format(qctool=args.qctool, prefix=prefix, chr_label=chr_label)

        out_name = args.out.replace('@', chr_label) + '_merge.job'
        with open(out_name, 'w') as f: f.write(command if impute_version=='impute4' else command5)
        sbatch_list.append('sbatch {}'.format(out_name))

    make_merge2(args, num_chunks_per_chr)

    for sbatch in sbatch_list:
        print(sbatch)

    print('sbatch --array {} MERGE.job           # to merge .bgen files'.format(','.join(args.chr2use)))

    chunk_def_fname = '{}.chunk_def.csv'.format(args.prefix) 
    pd.DataFrame(chunk_def).to_csv(chunk_def_fname, sep='\t', index=False)
    print(f'FYI, chunk definitions are written to {chunk_def_fname}.')

def parse_args(args):
    parser = argparse.ArgumentParser(description="A helper tool to prepare MoBa jobs on Colossus. Many arguments have reasonable defaults and you don't need to specify them.") #, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    
    parent_parser = argparse.ArgumentParser(add_help=False)
    
    subparsers = parser.add_subparsers()

    parser_ichunk = subparsers.add_parser("ichunks", parents=[parent_parser], help='Generate chunk files splitting individuals in a way that respects FIDs')
    parser_ichunk.add_argument("--prefix", type=str, help='prefix of the input PLINK .bed/.bim/.fam file')
    parser_ichunk.add_argument("--chunk-size", type=int, default=5000, help='size of the chunks')
    parser_ichunk.set_defaults(func=make_ichunk)

    parser_shapeit2 = subparsers.add_parser("shapeit2", parents=[parent_parser], help='Scripts to perform phasing with shapeit2')
    add_slurm_arguments(parser_shapeit2, 'phase_@', 'p697', 168, 8000, 64)
    parser_shapeit2.add_argument("--prefix", type=str, help='prefix of the input PLINK .bed/.bim/.fam file')
    parser_shapeit2.add_argument("--shapeit2", type=str, default="/cluster/projects/p697/projects/moba_qc_imputation/software/shapeit", help='path to the shapeit2 executable')
    parser_shapeit2.add_argument("--num-ichunks", type=int, help='number of chunks along individuals (must be pre-generated and stored in ichunkNNN.iid files)')
    add_inpute_map(parser_shapeit2)
    parser_shapeit2.add_argument("--out", type=str, default="shapeit2_chr@", help='name of the output script')
    add_chr2use(parser_shapeit2)
    parser_shapeit2.set_defaults(func=make_shapeit2)

    parser_minimac4 = subparsers.add_parser("minimac4", parents=[parent_parser], help='Scripts to perform imputation with minimac4')
    add_slurm_arguments(parser_minimac4, 'mmac4_@', 'p697', 168, 8000, 16)
    parser_minimac4.add_argument("--prefix", type=str, help='prefix of the input PLINK .bed/.bim/.fam file')
    parser_minimac4.add_argument("--num-ichunks", type=int, help='number of chunks along individuals (must be pre-generated and stored in ichunkNNN.iid files)')
    parser_minimac4.add_argument("--out", type=str, default="mmac4_chr@", help='name of the output script')
    add_chr2use(parser_minimac4)
    parser_minimac4.set_defaults(func=make_minimac4)

    parser_beagle5 = subparsers.add_parser("beagle5", parents=[parent_parser], help='Scripts to perform imputation with beagle5')
    add_slurm_arguments(parser_beagle5, 'bgle5_@', 'p697', 168, 8000, 16)
    parser_beagle5.add_argument("--prefix", type=str, help='prefix of the input PLINK .bed/.bim/.fam file')
    parser_beagle5.add_argument("--num-ichunks", type=int, help='number of chunks along individuals (must be pre-generated and stored in ichunkNNN.iid files)')
    parser_beagle5.add_argument("--out", type=str, default="beagle5_chr@", help='name of the output script')
    add_chr2use(parser_beagle5)
    parser_beagle5.set_defaults(func=make_beagle5)

    parser_impute4 = subparsers.add_parser("impute4", parents=[parent_parser], help='Scripts to perform imputation with impute4')
    add_slurm_arguments(parser_impute4, 'impt4_@', 'p697', 24, 8000, 1)
    parser_impute4.add_argument("--prefix", type=str, help='prefix of the input PLINK .bed/.bim/.fam file (use the same --prefix as in shapeit2 command, i.e. ".phased" will be added automatically)')
    parser_impute4.add_argument("--num-ichunks", type=int, help='number of chunks along individuals (must be pre-generated and stored in ichunkNNN.iid files)')    
    parser_impute4.add_argument("--qctool", type=str, default="/cluster/projects/p697/projects/moba_qc_imputation/software/qctool_v2.0.8_rhel", help='path to the qctool executable')
    add_inpute_map(parser_impute4)
    parser_impute4.add_argument("--out", type=str, default="impute4_chr@", help='name of the output script')
    parser_impute4.add_argument("--chunk-size-mb", type=int, default=3, help='chunk size (in MB)')
    parser_impute4.add_argument("--min-snps-per-chunk", type=int, default=1, help='minimum number of SNPs in chunk')
    parser_impute4.add_argument("--missing-only", action="store_true", default=False, help='genearte jobs only for missing chunks')
    add_chr2use(parser_impute4)
    parser_impute4.set_defaults(func=make_impute4)

    parser_impute5 = subparsers.add_parser("impute5", parents=[parent_parser], help='Scripts to perform imputation with impute5')
    add_slurm_arguments(parser_impute5, 'impt5_@', 'p697', 24, 8000, 1)
    parser_impute5.add_argument("--prefix", type=str, help='prefix of the input PLINK .bed/.bim/.fam file (use the same --prefix as in shapeit2 command, i.e. ".phased" will be added automatically)')
    parser_impute5.add_argument("--num-ichunks", type=int, help='number of chunks along individuals (must be pre-generated and stored in ichunkNNN.iid files)')
    parser_impute5.add_argument("--qctool", type=str, default="/cluster/projects/p697/projects/moba_qc_imputation/software/qctool_v2.0.8_rhel", help='path to the qctool executable')
    parser_impute5.add_argument("--input-map", type=str, default="/cluster/projects/p697/projects/moba_qc_imputation/resources/genetic_maps/shapeit4/chr@.b37.gmap.gz", help='input map, with @ indicating chromosome label')
    parser_impute5.add_argument("--out", type=str, default="impute5_chr@", help='name of the output script')
    parser_impute5.add_argument("--chunk-size-mb", type=int, default=3, help='chunk size (in MB)')
    parser_impute5.add_argument("--min-snps-per-chunk", type=int, default=1, help='minimum number of SNPs in chunk')
    parser_impute5.add_argument("--missing-only", action="store_true", default=False, help='genearte jobs only for missing chunks')
    add_chr2use(parser_impute5)
    parser_impute5.set_defaults(func=make_impute5)




    return parser.parse_args(args)

if __name__ == "__main__":
    args = list(sys.argv[1:])
    if len(args) <= 1: args.append('--help')   # by default argsparse doesn't call print_help(), so I explicitly  aded '--help' to the list of arguments.
    args = parse_args(args)
    if '--help' in args: exit()
   
    process_args(args)
    args.func(args)
    
