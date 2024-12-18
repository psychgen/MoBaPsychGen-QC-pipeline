import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import os
import sys
from matplotlib.ticker import PercentFormatter

chr2use_arg = sys.argv[1]

if chr2use_arg is not None:
    chr2use = []
    for a in chr2use_arg.split(","):
        if "-" in a:
            start, end = [int(x) for x in a.split("-")]
            chr2use += [str(x) for x in range(start, end+1)]
        elif a.strip() == '25':
            chr2use += ['25.par1', '25.par2']
        else:
            chr2use.append(a.strip())
    chr2use_arg = chr2use

# Load HRC sites /cluster/projects/p697/projects/moba_qc_imputation/resources/HRC
#'/ess/p697/cluster/projects/moba_qc_imputation/resources/HRC/HRC.r1-1.GRCh37.wgs.mac5.sites.tab.gz'
hrc=pd.read_csv('/ess/p697/data/durable/projects/moba_qc_imputation/TF/chrY/reference/sites/EUR24.gnomad.genomes.v3.1.2.sites.chrY.tab.gz', sep='\t')
hrc.rename(columns={'#CHROM':'CHR', 'ID':'SNP', 'AF':'HRC_AF', 'REF':'HRC_REF', 'ALT': 'HRC_ALT'}, inplace=True)
hrc['ID'] = hrc['CHR'].astype(str) + ':' + hrc['POS'].astype(str) + '_' + hrc['HRC_REF'] + '_' + hrc['HRC_ALT']

cohort=''
folder = os.getcwd()
mask = folder + cohort + '/chr{}.imputed.chunk{}.snp.stats'
info_merged = folder + cohort + '/chr{}.imputed.snp.stats.gz'
figures_folder = folder + cohort + '/figures' 
if not os.path.exists(figures_folder): print('create {} folder'.format(figures_folder)); os.mkdir(figures_folder)

figures_prefix = os.path.join(figures_folder, '{cohort}_'.format(cohort=cohort))
dfs = []
for chri in chr2use_arg:
    #for chri in [22]:
   
    fnames = [mask.format(chri, chunk) for chunk in range(1, 1000) if os.path.exists(mask.format(chri, chunk))]
    df=pd.concat([pd.read_csv(fname, delim_whitespace=True,comment='#') for fname in fnames])
    df['chromosome'] = chri
    df['ID'] = df['chromosome'].astype(str) + ':' + df['position'].astype(str) + '_' + df['alleleA'] + '_' + df['alleleB']
    df['ID'] = df['ID'].str.replace('25.par1','X')
    df['ID'] = df['ID'].str.replace('25.par2','X')
    df['ID'] = df['ID'].str.replace('Y','24')
    df_plots=pd.merge(df, hrc[['ID', 'HRC_AF', 'HRC_REF', 'HRC_ALT']], how='left', on='ID')
    # assert(df_plots['HRC_AF'].isnull().sum() == 0)
    df_plots = df_plots.loc[~df_plots['HRC_AF'].isnull()]
    # fix-fix - set imputation to 0 if allele frequency is 0.0 or 1.0
    df_plots.loc[~np.isfinite(df_plots['info'].values) & ((df_plots['alleleB_frequency']==0) | (df_plots['alleleA_frequency']==0)),'info']=0
    df_plots.to_csv(info_merged.format(chri), index=False, compression='gzip', sep='\t')

    dfs.append(df[['info', 'alleleB_frequency']])
    
    hrc_af = df_plots['HRC_AF'].values
    cohort_af = df_plots['alleleB_frequency'].values
    cohort_info = df_plots['info'].values
    cohort_bp = df_plots['position'].values
    vals, edges=np.histogram(cohort_af, range=[0, 1])
    freq_table = pd.DataFrame([('{:.1f}-{:.1f}'.format(l, r), v, '{:.2f}'.format(100*v/sum(vals))) 
                               for l, r, v in zip(edges[:-1], edges[1:], vals)] + 
                              [('Total', sum(vals), '{:.2f}'.format(100*sum(vals)/len(cohort_af)))], 
                              columns=['Alt Allele Frq','Count','%'])
    vals, edges=np.histogram(cohort_info, range=[0, 1])
    info_table = pd.DataFrame([('{:.1f}-{:.1f}'.format(l, r), v, '{:.2f}'.format(100*v/sum(vals))) 
                               for l, r, v in zip(edges[:-1], edges[1:], vals)] + 
                              [('Total', sum(vals), '{:.2f}'.format(100*sum(vals)/len(cohort_info)))], 
                              columns=['INFO score','Count','%'])

    def do_figures(rows, cols, subplot_indices):
        plt.subplot(rows, cols,subplot_indices[0])
        plt.plot(hrc_af, cohort_af,'.',markersize=2)
        plt.title('Plot of the Alt Allele frequency in cohort vs HRC')
        plt.xlabel('HRC allele frequency')
        plt.ylabel('{} allele frequency'.format(cohort))
        plt.locator_params(axis='x', nbins=11)
        plt.locator_params(axis='y', nbins=11)

        plt.subplot(rows, cols,subplot_indices[1])
        plt.plot(cohort_af, cohort_info,'.',markersize=2)
        plt.title('Plot of the Alt Allele frequency vs INFO score')
        plt.xlabel('{} allele frequency'.format(cohort))
        plt.ylabel('{} info score'.format(cohort))
        plt.locator_params(axis='x', nbins=11)
        plt.locator_params(axis='y', nbins=11)

        plt.subplot(rows, cols, subplot_indices[2])
        plt.hist(cohort_af, weights=np.ones(len(cohort_af)) / len(cohort_af))
        plt.gca().yaxis.set_major_formatter(PercentFormatter(1))
        plt.title('Bar chart displaying variants binned by alternate allele frequency')
        plt.xlabel('Percentage')
        plt.ylabel('{} allele frequency'.format(cohort))
        plt.locator_params(axis='x', nbins=11)

        ax=plt.subplot(rows, cols, subplot_indices[3])
        the_table=ax.table(cellText=freq_table.values, colLabels=freq_table.columns, loc='center') #, fontsize=50)
        ax.axis('off')
        ax.axis('tight')
        the_table.scale(1, 3)
        the_table.set_fontsize(18)
        plt.title('Variants binned by alternate allele frequency')

        plt.subplot(rows, cols, subplot_indices[4])
        plt.hist(cohort_info, weights=np.ones(len(cohort_info)) / len(cohort_info))
        plt.gca().yaxis.set_major_formatter(PercentFormatter(1))
        plt.title('Bar chart displaying variants binned by imputation INFO score')
        plt.xlabel('Percentage')
        plt.ylabel('{} INFO score'.format(cohort))
        plt.locator_params(axis='x', nbins=11)

        ax=plt.subplot(rows, cols, subplot_indices[5])
        the_table=ax.table(cellText=info_table.values, colLabels=info_table.columns, loc='center') #, fontsize=50)
        ax.axis('off')
        ax.axis('tight')
        the_table.scale(1, 3)
        the_table.set_fontsize(18)
        plt.title('Variants binned by imputation INFO score')

        plt.subplot(rows, cols, subplot_indices[6])
        plt.plot(cohort_bp, cohort_af, '.',markersize=2)
        plt.title('Manhattan plot of the INFO score across the chromosome')
        plt.xlabel('Chromosome {}'.format(chri))
        plt.ylabel('INFO score')

        plt.subplot(rows, cols, subplot_indices[7])
        plt.plot(cohort_bp, range(1, len(cohort_bp)+1), '.',markersize=2)
        plt.title('To check for consistent ascending Chr/Pos ordering')
        plt.xlabel('Position on chromosome {}'.format(chri))
        plt.ylabel('Line number')

    plt.figure(figsize=(20, 40))
    do_figures(4, 2, [1,2,3,4,5,6,7,8])
    plt.savefig('{}chr{}.png'.format(figures_prefix, chri), dpi=300)

    plt.figure(figsize=(40, 20))
    do_figures(2, 4, [1,5,2,6,3,7,4,8])
    plt.savefig('{}chr{}_flip.png'.format(figures_prefix, chri), dpi=300)

# Genome-wide
plt.figure(figsize=(20, 10))
df_plots=pd.concat(dfs)
df_plots.loc[~np.isfinite(df_plots['info'].values) & ((df_plots['alleleB_frequency']==0) | (df_plots['alleleB_frequency']==1)),'info']=0
cohort_af = df_plots['alleleB_frequency'].values
cohort_info = df_plots['info'].values
vals, edges=np.histogram(cohort_af, range=[0, 1])
freq_table = pd.DataFrame([('{:.1f}-{:.1f}'.format(l, r), v, '{:.2f}'.format(100*v/sum(vals))) 
                           for l, r, v in zip(edges[:-1], edges[1:], vals)] + 
                          [('Total', sum(vals), '{:.2f}'.format(100*sum(vals)/len(cohort_af)))], 
                          columns=['Alt Allele Frq','Count','%'])
vals, edges=np.histogram(cohort_info, range=[0, 1])
info_table = pd.DataFrame([('{:.1f}-{:.1f}'.format(l, r), v, '{:.2f}'.format(100*v/sum(vals))) 
                           for l, r, v in zip(edges[:-1], edges[1:], vals)] + 
                          [('Total', sum(vals), '{:.2f}'.format(100*sum(vals)/len(cohort_info)))], 
                          columns=['INFO score','Count','%'])
ax=plt.subplot(1, 2, 1)
the_table=ax.table(cellText=freq_table.values, colLabels=freq_table.columns, loc='center') #, fontsize=50)
ax.axis('off')
ax.axis('tight')
the_table.scale(1, 3)
the_table.set_fontsize(18)
plt.title('Variants binned by alternate allele frequency')

ax=plt.subplot(1, 2, 2)
the_table=ax.table(cellText=info_table.values, colLabels=info_table.columns, loc='center') #, fontsize=50)
ax.axis('off')
ax.axis('tight')
the_table.scale(1, 3)
the_table.set_fontsize(18)
plt.title('Variants binned by imputation INFO score')
plt.suptitle('Genome-wide')
plt.savefig('{}chrALL.png'.format(figures_prefix), dpi=300)
