import sys

def convert_to_format1(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if line.startswith('>'):
                # 提取 miRNA 名称、ID 和物种信息
                parts = line[1:].strip().split(' ')
                name = parts[0]
                miRNA_id = parts[1]
                miRBase_id = parts[2]
                species = parts[3]  # 这里直接取物种信息
            else:
                # 提取序列
                sequence = line.strip()
                # 写入输出文件
                outfile.write(f"{name}\t{miRNA_id}\t{miRBase_id}\t{sequence}\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_to_format1.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert_to_format1(input_file, output_file)