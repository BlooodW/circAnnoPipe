import re
import os

# 获取当前目录路径
home_dir = os.getcwd()

# 输入/输出文件路径
input_file = os.path.join(home_dir, "results/miRNA", "miRanda.txt")
output_file = os.path.join(home_dir, "results/miRNA", "miRanda_parsed.txt")

def parse_miranda_results(file_path, output_path):
    """解析 miRanda 结果文件，提取 miRNA、target、Score、MFE 和 Position 信息"""
    
    hit_pattern = re.compile(r">>(\S+)\s+(\S+)\s+([\d.]+)\s+([-.\d]+).*")  # 解析 Score for this Scan
    details_pattern = re.compile(r">(\S+)\s+(\S+)\s+([\d.]+)\s+([-.\d]+)\s+([\d\s]+)")  # 解析 Scores for this hit

    results = set()  # 使用集合去重

    with open(file_path, 'r') as file:
        lines = file.readlines()

    for line in lines:
        # 匹配 "Scores for this hit" 部分
        if details_match := details_pattern.search(line):
            miRNA, target, score, mfe, positions = details_match.groups()
            results.add((miRNA, target, score, mfe, positions))

        # 匹配 "Score for this Scan" 部分
        elif hit_match := hit_pattern.search(line):
            miRNA, target, score, mfe = hit_match.groups()[:4]
            positions = "N/A"  # 该部分无具体匹配位置信息
            results.add((miRNA, target, score, mfe, positions))

    # 写入解析结果
    with open(output_path, 'w') as outfile:
        outfile.write("miRNA\ttarget\tmiRanda_Score\tmiRanda_MFE\tmiRanda_Position\n")
        for result in results:
            outfile.write(f"{result[0]}\t{result[1]}\t{result[2]}\t{result[3]}\t{result[4]}\n")

    print(f"提取完成，结果已保存到 {output_path}")

# 运行解析函数
parse_miranda_results(input_file, output_file)


