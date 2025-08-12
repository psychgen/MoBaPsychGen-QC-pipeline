# To runs this script:
# 1. copy it here: /cluster/projects/p697/projects/moba_qc_imputation/resources/HRC
# 2. manually create folders 'hapsamplelegend' and 'vcf' and 'm3vcf'
# 3. run 'python make_hrc_format_conversion_scripts.py' 
# 4. run 'cat bcftools_sbatch.sh | bash'
# 5. wait for submitted SLURM jobs to finish - then HRC panel is converted to other needed data formats.

#module load CMake/3.15.3-GCCcore-8.3.0
#module load Python/3.7.4-GCCcore-8.3.0
#source /cluster/projects/p697/ofrei/py3/bin/activate

files = '''
_egaz00001239271_hrc.r1-1.ega.grch37.chr4.haplotypes
_egaz00001239270_hrc.r1-1.ega.grch37.chr3.haplotypes
_egaz00001239269_hrc.r1-1.ega.grch37.chr2.haplotypes
_egaz00001239268_hrc.r1-1.ega.grch37.chr1.haplotypes.noibd
_egaz00001239292_hrc.r1-1.ega.grch37.chrx_par2.haplotypes
_egaz00001239291_hrc.r1-1.ega.grch37.chrx_nonpar.haplotypes
_egaz00001239290_hrc.r1-1.ega.grch37.chrx_par1.haplotypes
_egaz00001239289_hrc.r1-1.ega.grch37.chr22.haplotypes
_egaz00001239288_hrc.r1-1.ega.grch37.chr21.haplotypes
_egaz00001239287_hrc.r1-1.ega.grch37.chr20.haplotypes
_egaz00001239286_hrc.r1-1.ega.grch37.chr19.haplotypes
_egaz00001239285_hrc.r1-1.ega.grch37.chr18.haplotypes
_egaz00001239284_hrc.r1-1.ega.grch37.chr17.haplotypes
_egaz00001239283_hrc.r1-1.ega.grch37.chr16.haplotypes
_egaz00001239282_hrc.r1-1.ega.grch37.chr15.haplotypes
_egaz00001239281_hrc.r1-1.ega.grch37.chr14.haplotypes
_egaz00001239280_hrc.r1-1.ega.grch37.chr13.haplotypes
_egaz00001239279_hrc.r1-1.ega.grch37.chr12.haplotypes
_egaz00001239278_hrc.r1-1.ega.grch37.chr11.haplotypes
_egaz00001239277_hrc.r1-1.ega.grch37.chr10.haplotypes
_egaz00001239276_hrc.r1-1.ega.grch37.chr9.haplotypes
_egaz00001239275_hrc.r1-1.ega.grch37.chr8.haplotypes
_egaz00001239274_hrc.r1-1.ega.grch37.chr7.haplotypes
_egaz00001239273_hrc.r1-1.ega.grch37.chr6.haplotypes
_egaz00001239272_hrc.r1-1.ega.grch37.chr5.haplotypes
'''.split()

template = '''#!/bin/bash
#SBATCH --job-name=bcftools
#SBATCH --account=p697_tsd
##SBATCH --account=p697_norment_dev
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=8000M
#SBATCH --cpus-per-task=2

source /cluster/bin/jobsetup
set -o errexit

module load BCFtools/1.9-foss-2018b

export MINIMAC3=/cluster/projects/p697/projects/moba_qc_imputation/software/Minimac3Executable/bin/Minimac3-omp
export imp5Converter=/cluster/projects/p697/projects/moba_qc_imputation/software/imp5Converter_1.1.5_static

cd /cluster/projects/p697/projects/moba_qc_imputation/resources/HRC
bcftools convert {f}.bcf.gz --haplegendsample haplegendsample/{f} --vcf-ids   # for shapeit2, impute2, impute4
bcftools convert {f}.bcf.gz -o vcf/{f}.vcf --vcf-ids && bgzip vcf/{f}.vcf     # for beagle
bcftools index -t vcf/{f}.vcf.gz
$MINIMAC3 --refHaps vcf/{f}.vcf.gz --processReference --prefix m3vcf/{f} --cpus 1   # for minimac4
$imp5Converter --h vcf/{f}.vcf.gz --r {chrlabel} --o imp5/{f}.imp5                 # for impute5
'''


fbatch = open('bcftools_sbatch.sh', 'w')
for file in files:
    chrlabel = file.split('.')[4]
    f = open("bcftools_script_{}.sh".format(chrlabel), "w")
    f.write(template.format(f=file,chrlabel=chrlabel.replace('chr', ''))
    f.close()
    fbatch.write('sbatch bcftools_script_{}.sh\n'.format(chrlabel))
fbatch.close()
