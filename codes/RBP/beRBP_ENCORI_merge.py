import pandas as pd
import sys

def process_files(file1, file2, output_file):
    df1 = pd.read_csv(file1, sep='\t', skiprows=3, dtype=str)
    
    df1 = df1.iloc[:, [0, 3]]
    df1.columns = ['RBP', 'circRNA']
    
    df1 = df1.replace('-', '_', regex=True)
    
    df1 = df1.assign(circRNA=df1['circRNA'].str.split(',')).explode('circRNA')
    
    intermediate1 = file1.replace('.txt', '_intermediate.txt')
    df1.to_csv(intermediate1, sep='\t', index=False)
    print(f"df1 saved to {intermediate1}！")
    
    df2 = pd.read_csv(file2, sep='\t', dtype=str)
    df2 = df2.iloc[:, [0, 1]]
    df2.columns = ['circRNA', 'RBP']
    
    df2 = df2.replace('-', '_', regex=True)
    
    intermediate2 = file2.replace('.tsv', '_intermediate.txt')
    df2.to_csv(intermediate2, sep='\t', index=False)
    print(f"df2 saved to {intermediate2}！")
    
    merged_df = pd.merge(df1, df2, on=['RBP', 'circRNA'])
    
    merged_df.to_csv(output_file, sep='\t', index=False)
    print(f"merged result saved to {output_file}！")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("usage: python beRBP_ENCORI_merge.py <ENCORI file> <beRBP file> <output file>")
        sys.exit(1)
    
    encori_file = sys.argv[1]
    berbp_file = sys.argv[2]
    output_file = sys.argv[3]

    process_files(encori_file, berbp_file, output_file)

