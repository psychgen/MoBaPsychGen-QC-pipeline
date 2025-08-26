import sys
import pandas as pd
import numpy as np

if __name__ == '__main__':
    chri = sys.argv[1]
    bim = pd.read_csv(sys.stdin, delim_whitespace=True, header=None, names='CHR SNP BP A1 A2'.split())
    bim['CHR'] = '25' if chri in ['25.par1', '25.par2'] else chri
    idx = bim['SNP'].duplicated(keep=False)
    print(f'rename {sum(idx)} SNPs', file=sys.stderr)
    bim.loc[idx, 'SNP'] = [f'{chri}:{bp}_{a1}_{a2}' for chri,bp,a1,a2, in zip(bim.loc[idx, 'CHR'].values, bim.loc[idx, 'BP'].values, bim.loc[idx, 'A1'].values,  bim.loc[idx, 'A2'].values)]
    assert(np.all(~bim['SNP'].duplicated(keep=False)))
    
    # https://stackoverflow.com/questions/15793886/how-to-avoid-a-broken-pipe-error-when-printing-a-large-amount-of-formatted-data
    try:
        bim.to_csv(sys.stdout, sep='\t', index=False, header=None)
    except IOError:
        # stdout is closed, no point in continuing
        # Attempt to close them explicitly to prevent cleanup problems:
        try:
            sys.stdout.close()
        except IOError:
            pass
