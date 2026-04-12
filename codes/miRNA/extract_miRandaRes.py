import re
import os

home_dir = os.getcwd()

input_file = os.path.join(home_dir, "results/miRNA", "miRanda.txt")
output_file = os.path.join(home_dir, "results/miRNA", "miRanda_parsed.txt")

def parse_miranda_results(file_path, output_path):
    """Extracting miRNA, target, Score, MFE and Position Information"""
    
    hit_pattern = re.compile(r">>(\S+)\s+(\S+)\s+([\d.]+)\s+([-.\d]+).*") 
    details_pattern = re.compile(r">(\S+)\s+(\S+)\s+([\d.]+)\s+([-.\d]+)\s+([\d\s]+)")

    results = set() 

    with open(file_path, 'r') as file:
        lines = file.readlines()

    for line in lines:
        # matching "Scores for this hit" 
        if details_match := details_pattern.search(line):
            miRNA, target, score, mfe, positions = details_match.groups()
            results.add((miRNA, target, score, mfe, positions))

        # matching "Score for this Scan" 部分
        elif hit_match := hit_pattern.search(line):
            miRNA, target, score, mfe = hit_match.groups()[:4]
            positions = "N/A"
            results.add((miRNA, target, score, mfe, positions))

    with open(output_path, 'w') as outfile:
        outfile.write("miRNA\ttarget\tmiRanda_Score\tmiRanda_MFE\tmiRanda_Position\n")
        for result in results:
            outfile.write(f"{result[0]}\t{result[1]}\t{result[2]}\t{result[3]}\t{result[4]}\n")

    print(f"提取完成，结果已保存到 {output_path}")

# 运行解析函数
parse_miranda_results(input_file, output_file)


