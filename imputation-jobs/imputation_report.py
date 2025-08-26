import glob, os
import os.path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter

# Load HRC sites
hrc=pd.read_csv('/cluster/projects/p697/projects/moba_qc_imputation/resources/HRC/HRC.r1-1.GRCh37.wgs.mac5.sites.tab.gz', sep='\t')
hrc.rename(columns={'#CHROM':'CHR', 'ID':'SNP', 'AF':'HRC_AF', 'REF':'HRC_REF', 'ALT': 'HRC_ALT'}, inplace=True)
hrc['ID'] = hrc['CHR'].astype(str) + ':' + hrc['POS'].astype(str) + '_' + hrc['HRC_REF'] + '_' + hrc['HRC_ALT']

#cohort='GSA_M4_Final_checks'
#cohort='OMNI_M4_Final_checks'
#cohort='HCE_M4_Final_checks'
#cohort='GSA_M4_Final_checks_exclude1subject'
cohort='GSA_may2021'

#cohort = 'OMNI'
mask = '/cluster/p/p697/cluster/projects/moba_qc_imputation/OF/' + cohort + '/chr{}.step10.imputed.chunk{}.snp.stats'
info_merged = '/cluster/p/p697/cluster/projects/moba_qc_imputation/OF/' + cohort + '/chr{}.step10.imputed.snp.stats.gz'
figures_folder = '/cluster/p/p697/cluster/projects/moba_qc_imputation/OF/{cohort}/figures'.format(cohort=cohort) 
if not os.path.exists(figures_folder): print('create {} folder'.format(figures_folder)); os.mkdir(figures_folder)
    
figures_prefix = os.path.join(figures_folder, '{cohort}_'.format(cohort=cohort))
dfs = []
for chri in list(range(1, 23)):
    #for chri in [22]:
   
    fnames = [mask.format(chri, chunk) for chunk in range(1, 1000) if os.path.exists(mask.format(chri, chunk))]
    df=pd.concat([pd.read_csv(fname, delim_whitespace=True,comment='#') for fname in fnames])
    df['chromosome'] = chri
    df['ID'] = df['chromosome'].astype(str) + ':' + df['position'].astype(str) + '_' + df['alleleA'] + '_' + df['alleleB']

    df_plots=pd.merge(df, hrc[['ID', 'HRC_AF', 'HRC_REF', 'HRC_ALT']], how='left', on='ID')
    assert(df_plots['HRC_AF'].isnull().sum() == 0)

    # fix-fix - set imputation to 0 if allele frequency is 0.0 or 1.0
    df_plots.loc[~np.isfinite(df_plots['impute_info'].values) & ((df_plots['alleleB_frequency']==0) | (df_plots['alleleA_frequency']==0)),'impute_info']=0
    df_plots.to_csv(info_merged.format(chri), index=False, compression='gzip', sep='\t')

    dfs.append(df[['impute_info', 'alleleB_frequency']])    
    
    hrc_af = df_plots['HRC_AF'].values
    cohort_af = df_plots['alleleB_frequency'].values
    cohort_info = df_plots['impute_info'].values
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
df_plots.loc[~np.isfinite(df_plots['impute_info'].values) & ((df_plots['alleleB_frequency']==0) | (df_plots['alleleB_frequency']==1)),'impute_info']=0
cohort_af = df_plots['alleleB_frequency'].values
cohort_info = df_plots['impute_info'].values
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
