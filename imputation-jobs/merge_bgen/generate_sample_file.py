# script used to generate sample file
# this takes into account rename of sample IIDs

import pandas as pd
import numpy as np

# find IDs of samples passing post-imputation QC
df_qc = pd.read_csv('/cluster/projects/p697/genotype/MoBaPsychGen_v1/MoBaPsychGen_v1-ec-eur-batch-basic-qc.fam', delim_whitespace=True, header=None, names='FID ID p1 p2 sex pheno'.split())
df_qc[['ID']].to_csv('/cluster/projects/p697/projects/moba_qc_imputation/OF/MoBaPsychGen_v1_vcf/MoBaPsychGen_v1-ec-eur-batch-basic-qc.samples', index=False, header=None)

# find IDs that were changed after imputation
iid_changes = pd.read_csv('/cluster/projects/p697/genotype/MoBaPsychGen_v1/IID_Changes.txt',sep='\t')
iid_changes = iid_changes[iid_changes['Module_when_change_occured'] == 'Post-ImputationQC'].copy()
# and add a fake ID for Original_IID 9985526167_R02C01 which needs to be deleted; I'm replacing it with random GUID
iid_changes = pd.concat([iid_changes, pd.DataFrame({'Original_IID':['9985526167_R02C01'], 'Updated_IID':['deca6d43-d2d9-43e0-bc6a-cc5e5394b597']})]).reset_index(drop=True)

for fname in """OF/GSA_may2021/chr1.step10.imputed.info0p8.fam
                OF/Release3/chr1.imputed.info0p8.fam
                OF/Release4/chr1.imputed.info0p8.fam
                BA/release1_HCE/chr1.imputed.info0p8.fam
                BA/release1_OMNI/chr1.imputed.info0p8.fam
                BA/release1_GSA/chr1.imputed.info0p8.fam""".split():
    df=pd.read_csv('/cluster/projects/p697/projects/moba_qc_imputation/' + fname, delim_whitespace=True, header=None, names='FID ID p1 p2 sex pheno'.split())
    df=pd.merge(df[['ID', 'sex']], iid_changes[['Original_IID', 'Updated_IID']], left_on='ID', right_on='Original_IID', how='left')
    idx_changed = ~df['Updated_IID'].isnull()
    df.loc[idx_changed, 'ID'] = df.loc[idx_changed, 'Updated_IID']
    print(fname, len(df[idx_changed]), 'changed IIDs')
    pd.concat([pd.DataFrame({'ID':['0'], 'sex':['D']}), df[['ID', 'sex']]]).to_csv('/cluster/projects/p697/projects/moba_qc_imputation/OF/MoBaPsychGen_v1_vcf/' + fname.split('/')[1] + '.sample', sep='\t', index=False)

