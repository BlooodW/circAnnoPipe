import os
from collections import defaultdict

def norm_id(x: str) -> str:
    return x.strip().replace("-", "_")


    mp = {}
    if not map_path or (not os.path.exists(map_path)):
        return mp
    with open(map_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            ts_id = norm_id(parts[0])
            circ_id = norm_id(parts[1])
            mp[ts_id] = circ_id
    return mp

def parse_miranda(file_path):
    pair_pos = defaultdict(set)
    with open(file_path, 'r') as f:
        next(f, None) 
        for line in f:
            parts = line.rstrip("\n").split('\t')
            if len(parts) < 3:
                continue
            mirna = norm_id(parts[0])
            target = norm_id(parts[1])
            position = parts[2].strip()
            if position and position != "NA":
                pair_pos[(target, mirna)].add(position)
    return pair_pos

def parse_rnahybrid(file_path):
    pair_pos = defaultdict(set)
    with open(file_path, 'r') as f:
        next(f, None)
        for line in f:
            parts = line.rstrip("\n").split('\t')
            if len(parts) != 5:
                continue
            target, mirna, _, pval, position = parts

            try:
                if float(pval.strip()) >= 0.05:
                    continue
            except ValueError:
                continue

            target = norm_id(target)
            mirna = norm_id(mirna)

            start_pos = position.split()[0].strip()
            if start_pos and start_pos != "NA":
                pair_pos[(target, mirna)].add(start_pos)
    return pair_pos

def parse_targetscan(file_path, id_map=None):
    id_map = id_map or {}
    pair_pos = defaultdict(set)

    with open(file_path, 'r') as f:
        next(f, None)
        for line in f:
            fields = line.rstrip("\n").split('\t')
            if len(fields) < 6:
                continue

            raw_target = norm_id(fields[0])
            mirna_fam = norm_id(fields[1])
            start = fields[5].strip()

            target = id_map.get(raw_target, raw_target)

            if start and start != "NA":
                pair_pos[(target, mirna_fam)].add(start)

    return pair_pos

def merge_and_count(miranda_path, rnahybrid_path, targetscan_path, output_path,
                    targetscan_id_map_path=None, keep_single_tool=False):
    miranda = parse_miranda(miranda_path)
    rnahybrid = parse_rnahybrid(rnahybrid_path)

    ts_map = load_targetscan_id_map(targetscan_id_map_path)
    targetscan = parse_targetscan(targetscan_path, id_map=ts_map)

    all_pairs = set(miranda.keys()) | set(rnahybrid.keys()) | set(targetscan.keys())

    inter_m_r = set(miranda.keys()) & set(rnahybrid.keys())
    inter_m_t = set(miranda.keys()) & set(targetscan.keys())
    inter_r_t = set(rnahybrid.keys()) & set(targetscan.keys())
    inter_all = set(miranda.keys()) & set(rnahybrid.keys()) & set(targetscan.keys())

    print(f"[DIAG] miRanda pairs:   {len(miranda)}")
    print(f"[DIAG] RNAhybrid pairs:{len(rnahybrid)}")
    print(f"[DIAG] TargetScan pairs:{len(targetscan)}  (map used: {len(ts_map)} entries)")
    print(f"[DIAG] overlap miRanda∩RNAhybrid: {len(inter_m_r)}")
    print(f"[DIAG] overlap miRanda∩TargetScan: {len(inter_m_t)}")
    print(f"[DIAG] overlap RNAhybrid∩TargetScan:{len(inter_r_t)}")
    print(f"[DIAG] overlap all 3:              {len(inter_all)}")

    with open(output_path, 'w') as out:
        out.write("circRNA\tmiRNA\tnum_miRanda\tnum_RNAhybrid\tnum_TargetScan\n")
        for pair in sorted(all_pairs):
            m_count = len(miranda.get(pair, set()))
            r_count = len(rnahybrid.get(pair, set()))
            t_count = len(targetscan.get(pair, set()))

            if not keep_single_tool:
                nonzero = sum([m_count > 0, r_count > 0, t_count > 0])
                if nonzero <= 1:
                    continue

            target, mirna = pair
            out.write(f"{target}\t{mirna}\t{m_count}\t{r_count}\t{t_count}\n")

    print(f"Done. Wrote: {output_path}")

if __name__ == "__main__":
    home = os.getcwd()
    miranda_path = os.path.join(home, "results/miRNA", "miRanda_parsed.txt")
    rnahybrid_path = os.path.join(home, "results/miRNA", "hybrid_parsed.txt")
    targetscan_path = os.path.join(home, "results/miRNA/targetscan", "raw_output.txt")
    output_path = os.path.join(home, "results/miRNA", "miRNA_target_summary_by_tools.txt")


    targetscan_id_map_path = os.path.join(home, "results/miRNA/targetscan", "targetscan_id_map.tsv")

    merge_and_count(
        miranda_path,
        rnahybrid_path,
        targetscan_path,
        output_path,
        targetscan_id_map_path=targetscan_id_map_path,
        keep_single_tool=False
    )

