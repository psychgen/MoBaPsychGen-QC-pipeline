import pandas as pd
import matplotlib.pyplot as plt
import os
import sys

freq_fname = sys.argv[1]
info_fname = sys.argv[2]
batch_label = sys.argv[3]
out_fname = sys.argv[4]

print(f"Processing batch {batch_label}.")
print(f"Taking MAF from {freq_fname}")
print(f"Taking INFO from {info_fname}")

frq = pd.read_csv(freq_fname, delim_whitespace=True)
info = pd.read_csv(info_fname, delim_whitespace=True)
df = frq.merge(info, left_on="SNP", right_on="rs_id")

fig, ax1 = plt.subplots(1, 1, figsize=(5,5), constrained_layout=True)
ax1.scatter(df.MAF, df["info"])
ax1.set_xlabel("MAF")
ax1.set_ylabel("INFO")
ax1.set_title(batch_label)

plt.savefig(out_fname, facecolor='w')
print(f"Saved to {out_fname}")
