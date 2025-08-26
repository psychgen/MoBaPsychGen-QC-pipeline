import os.path
import pandas as pd
import numpy as np
import sys

def unique_id(chri, bp, a1, a2):
    return '{}:{}_{}_{}'.format(chri, bp, a1 if (a1<a2) else a2, a2 if (a1<a2) else a1)

if __name__ == '__main__':
    chri = sys.argv[1]    # 21
    if int(chri)==0:
        info = pd.concat([pd.read_csv('chr{}.imputed.bim.info'.format(chri), header=None, sep='\t', names='CHR SNP GP BP A1 A2 ID INFO'.split()) for chri in range(1, 23)])
        bim = pd.read_csv('imputed.info0p8.maf0p01.bim', header=None, sep='\t', names='CHR SNP GP BP A1 A2'.split())
        bim=pd.merge(bim, info[['SNP', 'INFO']], on='SNP', how='left')
        bim.to_csv('imputed.info0p8.maf0p01.bim.info',sep='\t', index=False, header=False)
        sys.exit()
    prefix = sys.argv[2]  # chr21.step10 or chr21.step10.train

    mask = '{}.imputed.chunk{}.snp.stats'
    info_merged = '{}.imputed.snp.stats.gz'
    bim_fname = '{}.imputed.bim'.format(prefix)
    hrc_sites = '/cluster/projects/p697/projects/moba_qc_imputation/resources/HRC/HRC.r1-1.GRCh37.wgs.mac5.sites.tab.gz'


    # Load info scores (QC tool output), and merge it across chunks for a given chromosome
    fnames = [mask.format(prefix, chunk) for chunk in range(1, 1000) if os.path.exists(mask.format(prefix, chunk))]
    print('reading {} files from {}...'.format(len(fnames), mask.format(prefix, "*")))
    df=pd.concat([pd.read_csv(fname, delim_whitespace=True, comment='#') for fname in fnames])
    df['chromosome'] = chri
    df['ID'] = [unique_id(chri, bp, a1, a2) for chri, bp, a1, a2 in df[['chromosome', 'position', 'alleleA', 'alleleB']].values]

    # Load HRC sites
    print('reading {}...'.format(hrc_sites))
    hrc=pd.read_csv(hrc_sites, sep='\t')
    hrc.rename(columns={'#CHROM':'CHR', 'ID':'SNP', 'AF':'HRC_AF', 'REF':'HRC_REF', 'ALT': 'HRC_ALT'}, inplace=True)
    hrc['ID'] = [unique_id(chri, bp, a1, a2) for chri, bp, a1, a2 in hrc[['CHR', 'POS', 'HRC_REF', 'HRC_ALT']].values]

    print('merging HRC_AF, HRC_REF and HRC_ALT with info scores...')
    df_info=pd.merge(df, hrc[['ID', 'HRC_AF', 'HRC_REF', 'HRC_ALT']], how='left', on='ID')
    assert(df_info['HRC_AF'].isnull().sum() == 0)

    # fix-fix - set imputation to 0 if allele frequency is 0.0 or 1.0
    bad_idx = ~np.isfinite(df_info['impute_info'].values) & ((df_info['alleleB_frequency']==0) | (df_info['alleleA_frequency']==0))
    print('setting info score of {} SNPs to 0 (due to MAF=0)'.format(np.sum(bad_idx)))
    df_info.loc[bad_idx,'impute_info']=0

    print('saving the result to {}...'.format(info_merged.format(prefix)))
    df_info.to_csv(info_merged.format(prefix), index=False, compression='gzip', sep='\t')

    print('reading {}...'.format(bim_fname))
    bim=pd.read_csv(bim_fname, sep='\t', header=None, names='CHR SNP GP BP A1 A2'.split())

    assert(len(df_info) == len(bim))
    print('both files have {} snps'.format(len(bim)))

    print('generate unique SNP ID and merging...')
    bim['ID'] = [unique_id(chri, bp, a1, a2) for chri, bp, a1, a2 in bim[['CHR', 'BP', 'A1', 'A2']].values]

    assert(bim['SNP'].duplicated().sum() == 0)
    assert(bim['ID'].duplicated().sum() == 0)
    assert(df_info['ID'].duplicated().sum() == 0)

    bim=pd.merge(bim, df_info[['ID', 'impute_info']], on='ID', how='left')

    print('saving {}...'.format(bim_fname+'.info'))
    bim.to_csv(bim_fname+'.info', index=False, sep='\t', header=False, float_format='%g')
    print('saving {}...'.format(bim_fname+'.info0p8.snps'))
    bim[bim['impute_info']>=0.8][['SNP']].to_csv(bim_fname+'.info0p8.snps', index=False, header=False)
