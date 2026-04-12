import re
import os

home_dir = os.getcwd()

input_file = os.path.join(home_dir, "results/miRNA", "hybrid.txt")
output_file = os.path.join(home_dir, "results/miRNA", "hybrid_parsed.txt")

def parse_rnahybrid_results(file_path, output_path):
    target_pattern = re.compile(r"target:\s*([^\s]+)")
    mirna_pattern = re.compile(r"miRNA\s*:\s*([^\s]+)")
    mfe_pattern = re.compile(r"mfe:\s*([-0-9.]+)\s*kcal/mol")
    pvalue_pattern = re.compile(r"p-value\s*:\s*([0-9.]+)")
    position_pattern = re.compile(r"position\s*([0-9]+)")

    results = set() 

    with open(file_path, 'r') as file:
        lines = file.readlines()

    target = None
    mirna = None
    mfe = None
    pvalue = None
    position = None

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

        if target and mirna and mfe and pvalue and position:
            results.add((target, mirna, mfe, pvalue, position))
            target, mirna, mfe, pvalue, position = None, None, None, None, None

    with open(output_path, 'w') as outfile:
        outfile.write("target\tmiRNA\tRNAhybrid_MFE\tRNAhybrid_Pvalue\tRNAhybrid_Position\n")
        for result in results:
            outfile.write(f"{result[0]}\t{result[1]}\t{result[2]}\t{result[3]}\t{result[4]}\n")

    print(f"提取完成，结果已保存到 {output_path}")

parse_rnahybrid_results(input_file, output_file)

