import pandas as pd
import sys

def process_files(file1, file2, output_file):
    # 读取第一个文件，跳过前三行
    df1 = pd.read_csv(file1, sep='\t', skiprows=3, dtype=str)
    
    # 只保留第一列（RBP）和第四列（circRNA ID）
    df1 = df1.iloc[:, [0, 3]]
    df1.columns = ['RBP', 'circRNA']
    
    # 替换所有的 "-" 为 "_"
    df1 = df1.replace('-', '_', regex=True)
    
    # 将circRNA列中的逗号分隔值拆分成多行
    df1 = df1.assign(circRNA=df1['circRNA'].str.split(',')).explode('circRNA')
    
    # 保存 df1 的中间结果
    intermediate1 = file1.replace('.txt', '_intermediate.txt')
    df1.to_csv(intermediate1, sep='\t', index=False)
    print(f"df1 中间结果已保存至 {intermediate1}！")
    
    # 读取第二个文件，只保留第一列（seqID）和第二列（RBP）
    df2 = pd.read_csv(file2, sep='\t', dtype=str)
    df2 = df2.iloc[:, [0, 1]]
    df2.columns = ['circRNA', 'RBP']
    
    # 替换所有的 "-" 为 "_"
    df2 = df2.replace('-', '_', regex=True)
    
    # 保存 df2 的中间结果
    intermediate2 = file2.replace('.tsv', '_intermediate.txt')
    df2.to_csv(intermediate2, sep='\t', index=False)
    print(f"df2 中间结果已保存至 {intermediate2}！")
    
    # 进行匹配，保留相同的行
    merged_df = pd.merge(df1, df2, on=['RBP', 'circRNA'])
    
    # 保存结果到新文件
    merged_df.to_csv(output_file, sep='\t', index=False)
    print(f"合并结果已保存至 {output_file}！")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("用法: python beRBP_ENCORI_merge.py <ENCORI文件> <beRBP文件> <输出文件>")
        sys.exit(1)
    
    encori_file = sys.argv[1]
    berbp_file = sys.argv[2]
    output_file = sys.argv[3]

    process_files(encori_file, berbp_file, output_file)

