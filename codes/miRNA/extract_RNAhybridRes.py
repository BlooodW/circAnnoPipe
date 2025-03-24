import re
import os

# 获取 HOME 目录路径
home_dir = os.getcwd()

input_file = os.path.join(home_dir, "results/miRNA", "hybrid.txt")
output_file = os.path.join(home_dir, "results/miRNA", "hybrid_parsed.txt")

def parse_rnahybrid_results(file_path, output_path):
    # 定义正则表达式来匹配所需信息
    target_pattern = re.compile(r"target:\s*([^\s]+)")
    mirna_pattern = re.compile(r"miRNA\s*:\s*([^\s]+)")
    mfe_pattern = re.compile(r"mfe:\s*([-0-9.]+)\s*kcal/mol")
    pvalue_pattern = re.compile(r"p-value\s*:\s*([0-9.]+)")
    position_pattern = re.compile(r"position\s*([0-9]+)")

    results = set()  # 使用集合去重

    with open(file_path, 'r') as file:
        lines = file.readlines()

    # 用于存储当前块的信息
    target = None
    mirna = None
    mfe = None
    pvalue = None
    position = None

    # 遍历文件内容，提取所需信息
    for line in lines:
        target_match = target_pattern.search(line)
        mirna_match = mirna_pattern.search(line)
        mfe_match = mfe_pattern.search(line)
        pvalue_match = pvalue_pattern.search(line)
        position_match = position_pattern.search(line)

        if target_match:
            target = target_match.group(1)
        if mirna_match:
            mirna = mirna_match.group(1)
        if mfe_match:
            mfe = mfe_match.group(1)
        if pvalue_match:
            pvalue = pvalue_match.group(1)
        if position_match:
            position = position_match.group(1)

        # 当所有信息都获取到时，存储并重置变量
        if target and mirna and mfe and pvalue and position:
            results.add((target, mirna, mfe, pvalue, position))
            target, mirna, mfe, pvalue, position = None, None, None, None, None

    # 将结果保存到新的文件中
    with open(output_path, 'w') as outfile:
        outfile.write("target\tmiRNA\tRNAhybrid_MFE\tRNAhybrid_Pvalue\tRNAhybrid_Position\n")
        for result in results:
            outfile.write(f"{result[0]}\t{result[1]}\t{result[2]}\t{result[3]}\t{result[4]}\n")

    print(f"提取完成，结果已保存到 {output_path}")

parse_rnahybrid_results(input_file, output_file)

