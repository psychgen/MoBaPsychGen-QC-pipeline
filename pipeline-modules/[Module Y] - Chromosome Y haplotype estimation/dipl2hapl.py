import argparse

def main(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith('#'):
                outfile.write(line)  # Copy all header lines unchanged
            else:
                parts = line.split()
                format_index = parts[8].split(':').index('GT')  # Find the genotype field
                new_genotypes = []
                for genotype_info in parts[9:]:
                    genotype_parts = genotype_info.split(':')
                    gt = genotype_parts[format_index]
                    if '/' in gt:  # Assuming genotype is like 0/0, 1/1, etc.
                        new_gt = gt.split('/')[0]  # Take only one allele
                        genotype_parts[format_index] = new_gt
                    new_genotypes.append(':'.join(genotype_parts))
                parts[9:] = new_genotypes
                outfile.write('\t'.join(parts) + '\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Convert diploid genotypes in a VCF to haploid for Y chromosome analysis.")
    parser.add_argument("input_file", type=str, help="Path to the input VCF file with diploid genotypes.")
    parser.add_argument("output_file", type=str, help="Path to the output VCF file with corrected haploid genotypes.")
    args = parser.parse_args()
    
    main(args.input_file, args.output_file)

