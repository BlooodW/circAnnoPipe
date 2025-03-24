import os

def merge_files_union(RNAhybrid_extracted_path, miRanda_extracted_path, output_path):
    # 读取 RNAhybrid_extracted（包含 target, miRNA, RNAhybrid_MFE, RNAhybrid_Pvalue, RNAhybrid_Position）
    RNAhybrid_data = {}  # {(target, miRNA): (RNAhybrid_MFE, RNAhybrid_Pvalue, RNAhybrid_Position)}
    with open(RNAhybrid_extracted_path, 'r') as RNAhybrid_file:
        next(RNAhybrid_file)  # 跳过表头
        for line in RNAhybrid_file:
            line = line.strip()
            if not line or len(line.split('\t')) != 5:
                continue
            target, mirna, mfe, pvalue, position = line.split('\t')
            # 替换 "-" 为 "_"
            target = target.replace('-', '_')
            mirna = mirna.replace('-', '_')
            RNAhybrid_data[(target.strip(), mirna.strip())] = (mfe.strip(), pvalue.strip(), position.strip())

    # 读取 miRanda_extracted（包含 miRNA, target, miRanda_Score, miRanda_MFE, miRanda_Position）
    miRanda_data = {}  # {(target, miRNA): (miRanda_Score, miRanda_MFE, miRanda_Position)}
    with open(miRanda_extracted_path, 'r') as miRanda_file:
        next(miRanda_file)  # 跳过表头
        for line in miRanda_file:
            line = line.strip()
            if not line or len(line.split('\t')) != 5:
                continue
            mirna, target, score, mfe, position = line.split('\t')
            # 去掉 miRNA 前面的 ">" 符号，并替换 "-" 为 "_"
            mirna = mirna.lstrip('>').replace('-', '_')
            target = target.replace('-', '_')
            miRanda_data[(target.strip(), mirna.strip())] = (score.strip(), mfe.strip(), position.strip())

    # 生成合并结果
    merged_results = {}
    
    # 先合并 RNAhybrid 数据
    for (target, mirna), (mfe, pvalue, position) in RNAhybrid_data.items():
        merged_results[(target, mirna)] = {
            'miRNA': mirna,
            'target': target,
            'miRanda_Score': 'NA', 
            'miRanda_MFE': 'NA', 
            'miRanda_Position': 'NA',
            'RNAhybrid_MFE': mfe,
            'RNAhybrid_Pvalue': pvalue,
            'RNAhybrid_Position': position
        }

    # 合并 miRanda 数据，覆盖已有值
    for (target, mirna), (score, mfe, position) in miRanda_data.items():
        if (target, mirna) in merged_results:
            result = merged_results[(target, mirna)]
            result['miRanda_Score'] = score if score != 'NA' else result['miRanda_Score']
            result['miRanda_MFE'] = mfe if mfe != 'NA' else result['miRanda_MFE']
            result['miRanda_Position'] = position if position != 'NA' else result['miRanda_Position']
        else:
            # 新建条目
            merged_results[(target, mirna)] = {
                'miRNA': mirna,
                'target': target,
                'miRanda_Score': score,
                'miRanda_MFE': mfe,
                'miRanda_Position': position,
                'RNAhybrid_MFE': 'NA',
                'RNAhybrid_Pvalue': 'NA',
                'RNAhybrid_Position': 'NA'
            }

    # 按 RNAhybrid_Pvalue 排序（NA 视为最大值）
    merged_results = sorted(merged_results.values(), key=lambda x: (float(x['RNAhybrid_Pvalue']) if x['RNAhybrid_Pvalue'] != "NA" else float('inf')))

    # 输出到文件
    with open(output_path, 'w') as output_file:
        output_file.write("miRNA\ttarget\tmiRanda_Score\tmiRanda_MFE\tmiRanda_Position\tRNAhybrid_MFE\tRNAhybrid_Pvalue\tRNAhybrid_Position\n")
        for result in merged_results:
            output_file.write(f"{result['miRNA']}\t{result['target']}\t{result['miRanda_Score']}\t{result['miRanda_MFE']}\t{result['miRanda_Position']}\t{result['RNAhybrid_MFE']}\t{result['RNAhybrid_Pvalue']}\t{result['RNAhybrid_Position']}\n")

    print(f"合并完成，结果已保存到 {output_path}")

# 文件路径
home_dir = os.getcwd()
RNAhybrid_extracted_path = os.path.join(home_dir, "results/miRNA", "hybrid_parsed.txt")
miRanda_extracted_path = os.path.join(home_dir, "results/miRNA", "miRanda_parsed.txt")
output_path = os.path.join(home_dir, "results/miRNA", "miRNA_target_result_sorted_union.txt")

# 执行合并
merge_files_union(RNAhybrid_extracted_path, miRanda_extracted_path, output_path)


