import sys

def convert_miRNA_format(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith('>'):
                parts = line[1:].strip().split(' ')
                name = parts[0]
                miRBase_id = "9606"
            else:
                mature_sequence = line.strip()
                seed_sequence = mature_sequence[1:8]
                outfile.write(f"{name}\t{seed_sequence}\t{miRBase_id}\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_miRNA_format.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert_miRNA_format(input_file, output_file)
