import sys

def convert_miRNA_format(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith('>'):
                # 提取 miRNA 名称、miRBase ID 和物种信息
                parts = line[1:].strip().split(' ')
                name = parts[0]
                miRBase_id = "9606"
            else:
                # 提取成熟序列
                mature_sequence = line.strip()
                # 提取种子序列（第 2-8 位）
                seed_sequence = mature_sequence[1:8]
                # 写入输出文件
                outfile.write(f"{name}\t{seed_sequence}\t{miRBase_id}\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_miRNA_format.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert_miRNA_format(input_file, output_file)