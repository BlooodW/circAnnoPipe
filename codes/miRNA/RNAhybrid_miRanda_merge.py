import os
from collections import defaultdict

def parse_miranda(file_path):
    data = defaultdict(list)
    with open(file_path, 'r') as f:
        next(f)
        for line in f:
            line = line.strip()
            if not line:
                continue
                
            parts = line.split('\t')
            if len(parts) < 5:
                continue
                
            mirna = parts[0].replace('-', '_').strip()
            target = parts[1].replace('-', '_').strip()
            position = parts[2].strip()
            score = parts[3].strip()
            mfe = parts[4].strip()
            
            if position != 'NA' and position != '':
                data[(target, mirna, position)].append((score, mfe))
                
    return data

from collections import defaultdict

def parse_rnahybrid(file_path):
    data = defaultdict(list)
    with open(file_path, 'r') as f:
        next(f)
        for line in f:
            line = line.strip()
            if not line or len(line.split('\t')) != 5:
                continue
            target, mirna, mfe, pval, position = line.split('\t')
            try:
                if float(pval.strip()) >= 0.05:
                    continue
            except ValueError:
                continue

            target = target.replace('-', '_').strip()
            mirna = mirna.replace('-', '_').strip()
            start_pos = position.split()[0]
            data[(target, mirna, start_pos)].append((mfe.strip(), pval.strip()))
    return data


def parse_targetscan(file_path):
    data = defaultdict(list)
    with open(file_path, 'r') as f:
        next(f)
        for line in f:
            fields = line.strip().split('\t')
            if len(fields) < 13:
                continue
            target = fields[0].replace('-', '_').strip()
            mirna_fam = fields[1].replace('-', '_').strip()
            start = fields[5].strip()  # UTR_start
            site_type = fields[8].strip()
            group_type = fields[10].strip()
            data[(target, mirna_fam, start)].append((site_type, group_type))
    return data

def merge_all(miranda_path, rnahybrid_path, targetscan_path, output_path):
    miranda_data = parse_miranda(miranda_path)
    rnahybrid_data = parse_rnahybrid(rnahybrid_path)
    targetscan_data = parse_targetscan(targetscan_path)

    all_keys = set(miranda_data.keys()) | set(rnahybrid_data.keys()) | set(targetscan_data.keys())
    
    pair_positions = defaultdict(set)
    for key in all_keys:
        target, mirna, pos = key
        pair_positions[(target, mirna)].add(pos)
    
    sorted_pairs = sorted(pair_positions.keys())
    pair_position_counts = {}
    for pair in sorted_pairs:
        pair_position_counts[pair] = len(pair_positions[pair])

    with open(output_path, 'w') as out:
        out.write("circRNA\tmiRNA\tPositionNum\tPosition\t"
                  "miRanda_Score\tmiRanda_MFE\t"
                  "RNAhybrid_MFE\tRNAhybrid_Pvalue\t"
                  "TargetScan_SiteType\tTargetScan_GroupType\n")
        
        printed_pairs = set()
        
        for key in sorted(all_keys, key=lambda k: (k[0], k[1], k[2])):  # 按circRNA, miRNA, position排序
            target, mirna, pos = key
            pair = (target, mirna)
            
            position_num = pair_position_counts[pair]
            
            if pair not in printed_pairs:
                out_target = target
                out_mirna = mirna
                out_position_num = str(position_num) 
                printed_pairs.add(pair)
            else:
                out_target = "" 
                out_mirna = ""  
                out_position_num = ""  

            miranda_entries = miranda_data.get(key, [])
            miranda_score = ','.join([s for s, _ in miranda_entries]) if miranda_entries else 'NA'
            miranda_mfe = ','.join([m for _, m in miranda_entries]) if miranda_entries else 'NA'

            rnahybrid_entries = rnahybrid_data.get(key, [])
            rna_mfe = ','.join([m for m, _ in rnahybrid_entries]) if rnahybrid_entries else 'NA'
            rna_pval = ','.join([p for _, p in rnahybrid_entries]) if rnahybrid_entries else 'NA'

            ts_entries = targetscan_data.get(key, [])
            ts_sitetype = ','.join([s for s, _ in ts_entries]) if ts_entries else 'NA'
            ts_grouptype = ','.join([g for _, g in ts_entries]) if ts_entries else 'NA'

            out.write(f"{out_target}\t{out_mirna}\t{out_position_num}\t{pos}\t"
                      f"{miranda_score}\t{miranda_mfe}\t"
                      f"{rna_mfe}\t{rna_pval}\t"
                      f"{ts_sitetype}\t{ts_grouptype}\n")


if __name__ == "__main__":
    home = os.getcwd()
    miranda_path = os.path.join(home, "results/miRNA", "miRanda_parsed.txt")
    rnahybrid_path = os.path.join(home, "results/miRNA", "hybrid_parsed.txt")
    targetscan_path = os.path.join(home, "results/miRNA/targetscan", "raw_output.txt")
    output_path = os.path.join(home, "results/miRNA", "miRNA_target_result_positionwise_union.txt")

    merge_all(miranda_path, rnahybrid_path, targetscan_path, output_path)
