import os
import pandas as pd
import numpy as np

folder = os.getcwd()

steps_first_last = ['.step0', '.step10']
steps_first_last_full = ['{}/chr@{}.bim'.format(folder, step) for step in steps_first_last]
steps_first_last = ['before_qc', 'after_qc']

steps = ['.step0', '.step1a', '.step1b', '.step1c', '.step2', '.step3', '.step4', '.step5', '.step6', '.step7', '.step8', '.step9', '.step10']
steps_full = ['{}/chr@{}.bim'.format(folder, step) for step in steps]

steps_diffs = [(a,b) for a, b in zip(steps[:-1], steps[1:])]
steps_full_diffs = [(a,b) for a, b in zip(steps_full[:-1], steps_full[1:])]

snplist = ['chr@.step1b.snplist.txt']

files = 'Position Chromosome ID Exclude Strand-Flip Force-Allele1'.split()
files_full =  ['{}/{}-chr@.step4-HRC.txt'.format(folder, file) for file in files]


'''
# Step 1a (exclude duplicated), 1b (exclude indels and non-ACTG alleles), 1c (exclude ambiguous SNPs)
# Step 2. Zero out Mendelian errors
# Step 3. Missingness and HWE 
# Step 5. Oxford perl script --exclude 
# Step 6. Oxford perl script --update-chr
# Step 7. Oxford perl script --update-map
# Step 8. Oxford perl script --flip strand
# Step 9. Oxford perl script --a2-allele
# Step 10. Oxford perl script --update-name
'''

# number of lines
def wc(fname):
    return int(os.popen('cat {} | wc -l'.format(fname)).read().strip())

# removed, added, changed
def diff(fname1, fname2):
    diffs = ['diff {} {} -y | grep "<" | wc -l', 'diff {} {} -y | grep ">" | wc -l', 'diff {} {} -y | grep "|" | wc -l']
    return tuple([int(os.popen(diff.format(fname1, fname2)).read().strip()) for diff in diffs])

records = []
for chri in [str(i) for i in ([*range(1, 24)]+[25])]:
    for step, step_full in zip(steps_first_last, steps_first_last_full):
        n = wc(step_full.replace('@', chri))
        records.append((chri, '{}.bim'.format(step), n))
    for file, file_full in zip(files, files_full):
        n = wc(file_full.replace('@', chri))
        records.append((chri, '{}'.format(file), n))
    for (stepA, stepB), (stepA_full, stepB_full) in zip(steps_diffs, steps_full_diffs):
        n1, n2, n3 = diff(stepA_full.replace('@', chri), stepB_full.replace('@', chri))
        records.append((chri, '{}->{} removed'.format(stepA, stepB), n1))
        #records.append((chri, '{}->{} added'.format(stepA, stepB), n2))
        records.append((chri, '{}->{} changed'.format(stepA, stepB), n3))

df=pd.DataFrame(records, columns='CHR WHAT SNPs'.split())
df['CHR']=df['CHR'].astype(int)
df_pivot=pd.pivot_table(df, values='SNPs', index=['WHAT'], columns=['CHR'], aggfunc=np.sum)
new_index=[('before_qc.bim', '00 before_qc'),
('->.step1a removed', '01 exclude duplicated'),
('.step1a->.step1b removed', '02 exclude indels and non-ACTG'),
('.step1b->.step1c removed', '03 exclude ambiguous'),
('.step2->.step3 removed', '03.5 Exclude due to HWE and missingness'),#
('.step3->.step4 changed', '04 Compute allele frequencies'),#
('Exclude', '04 Oxford Exclude (list)'),
('.step4->.step5 removed', '05 Oxford Exclude (actually removed)'),
('.step4->.step5 changed', '05.5 Allele swap'), #
('Chromosome', '06 Oxford update-chr (list)'),
('Position', '07 Oxford update-map (list)'),
('.step6->.step7 changed', '08 Oxford update-map (actual changed)'),
('.step6->.step7 removed', '09 Oxford update-map (actual removed)'),
('Strand-Flip', '10 Oxford Strand-Flip (list)'),
('.step7->.step8 changed', '11 Oxford Strand-Flip (actual changes)'),
('Force-Allele1', '12 Oxford Force-Allele1 (list)'),
('.step8->.step9 changed', '13 Oxford Force-Allele1 (actual changes)'),
('ID', '14 Oxford update-name (list)'),
('.step9->.step10 changed', '15 Oxford update-name (actual changes)'),
('after_qc.bim', '16 after_qc')]
new_index= dict(new_index)

df_pivot['ALL']=df_pivot.values.sum(1)
df_pivot = df_pivot[df_pivot['ALL'] != 0]
df_pivot['explanation'] = [new_index[i] for i in df_pivot.index]

df_pivot.sort_values('explanation', )
df_pivot.loc['Total removed',:] = df_pivot.loc[[i for i in df_pivot.index if 'removed' in i]].sum()
df_pivot.loc['Total removed', 'explanation'] = 'Total removed'
try:
    df_pivot.to_excel(folder + '/PRE_PHASING_QC.report.xlsx')
    print('\nPre phasing QC report saved to ' + folder + '/PRE_PHASING_QC.report.xlsx')
except ModuleNotFoundError:
    df_pivot.to_csv(folder + '/PRE_PHASING_QC.report.csv')
    print('\nPre phasing QC report saved to ' + folder + '/PRE_PHASING_QC.report.csv')
