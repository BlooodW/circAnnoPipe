#!/bin/bash

LOG_FILE="run_log.txt"
echo "Running Log - $(date)" > "$LOG_FILE"

log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# set direction
RUN_DIR="$PWD/local"
mkdir -p "$RUN_DIR"

OUTPUT_DIR="$PWD/results"

mkdir -p "$OUTPUT_DIR/miRNA"
mkdir -p "$OUTPUT_DIR/RBP"
mkdir -p "$OUTPUT_DIR/ORF"

read -p "please enter circRNA sequence file path (query) ：" TARGET_FILE
read -p "Please enter the microRNA sequence file path (query)：" QUERY_FILE

if [[ ! -f "$QUERY_FILE" || ! -f "$TARGET_FILE" ]]; then
    log_message "ERROR: File doesn't exist！"
    exit 1
fi



# ======================== RNAhybrid Run ========================
run_RNAhybrid() {
    log_message "running RNAhybrid..."
    RNAhybrid -t "$TARGET_FILE" -q "$QUERY_FILE" -s 3utr_human > "$PWD/results/miRNA/hybrid.txt"
    
    if [[ $? -eq 0 ]]; then
        log_message "RNAhybrid running completed，saved to results/miRNA/hybrid.txt"
    else
        log_message "ERROR: RNAhybrid failed！"
        exit 1
    fi

    python3 "$PWD/codes/miRNA/extract_RNAhybridRes.py"
}

# ======================== miRanda Run ========================
run_miRanda() {
    log_message "running miRanda..."
    "$PWD/packs/miranda/bin/miranda" "$QUERY_FILE" "$TARGET_FILE"  > "$PWD/results/miRNA/miRanda.txt"
    
    if [[ $? -eq 0 ]]; then
        log_message "miRanda completed，saved to results/miRNA/miRanda.txt"
    else
        log_message "ERROR: miRanda failed！"
        exit 1
    fi

    python3 "$PWD/codes/miRNA/extract_miRandaRes.py"
}


# ======================== TargetScan Run ========================
run_TargetScan() {
    log_message "running TargetScan..."
    conda activate bio_env
    mkdir $PWD/results/miRNA/targetscan/
    python $PWD/codes/targetscan/generate_miR_family_info.py "$QUERY_FILE" -o $PWD/results/miRNA/targetscan/miR_Family_info.txt
    python $PWD/codes/targetscan/generate_circRNA_input.py "$TARGET_FILE" -o $PWD/results/miRNA/targetscan/circRNA_input.txt

    
    perl $PWD/packs/targetscan/targetscan_70.pl \
        $PWD/results/miRNA/targetscan/miR_Family_info.txt \
        $PWD/results/miRNA/targetscan/circRNA_input.txt \
        $PWD/results/miRNA/targetscan/raw_output.txt
    
    conda deactivate
    cd ../../../

    if [[ $? -eq 0 ]]; then
        log_message "TargetScan running completed."
    else
        log_message "ERROR: TargetScan failed！"
        exit 1
    fi

}

# ======================== miRNA-circRNA Result Integration ========================
RNAhybrid_miRanda_merge() {
    log_message "merging RNAhybrid 和 miRanda results..."
    python3 "$PWD/codes/miRNA/miRNA_num.py"
    
    if [[ $? -eq 0 ]]; then
        log_message "Merge completed"
    else
        log_message "ERROR: merge failed！"
        exit 1
    fi
}

# ======================== beRBP Run ========================
run_beRBP() {
    cp "$TARGET_FILE" "$PWD/packs/beRBP/work/temp/001.fasta"

    cd "$PWD/packs/beRBP/code/" || { echo "Error: Failed to enter directory $PWD/beRBP/code/"; return 1; }

    if [[ ! -f core_csrv.sh ]]; then
        echo "Error: core_csrv.sh not found!"
        return 1
    fi

    cp core_csrv.sh core_csrv.sh.bak

    python core_csrv_mod.py
    
    cd ../work

    mkdir -p temp

    ../code/general_sPWM.sh 001 "all" "all" > temp/001.log &

    wait

    if [[ -f 001/resultMatrix.tsv ]]; then
        cp 001/resultMatrix.tsv ../../../results/RBP/beRBP.tsv
        echo "Moved resultMatrix.tsv to /results/RBP/beRBP.tsv"
    else
        echo "ERROR: resultMatrix.tsv not found!"
        return 1
    fi

    echo "run_beRBP completed successfully."

    cd ../../../
}

# ======================== ENCORI Run ========================
run_ENCORI() {
    mkdir -p "$PWD/results/RBP"
    echo "Downloading ENCORI RBP-Target data for circRNAs..."
    curl 'https://rnasysu.com/encori/api/RBPTarget/?assembly=hg38&geneType=circRNA&RBP=all&clipExpNum=5&pancancerNum=0&target=all&cellType=HeLa' \
        -o "$PWD/results/RBP/ENCORI_hg38_RBPTarget_all_circRNA_HeLa.txt"
    echo "Download completed. Data saved to $PWD/results/RBP/ENCORI_hg38_RBPTarget_all_circRNA_HeLa.txt"
}

# ======================== RBP-circRNA Results Integration ========================
beRBP_ENCORI_merge() {

    ENC_FILE="$PWD/results/RBP/ENCORI_hg38_RBPTarget_all_circRNA_HeLa.txt"
    RBP_FILE="$PWD/results/RBP/beRBP.tsv"
    OUTPUT_FILE="$PWD/results/RBP/merged_output.txt"

    python "$PWD/codes/RBP/beRBP_ENCORI_merge.py" "$ENC_FILE" "$RBP_FILE" "$OUTPUT_FILE"

    if [[ -f "$OUTPUT_FILE" ]]; then
        echo "Merge completed successfully. Output saved to $OUTPUT_FILE"
    else
        echo "Error: Merge output file not created!"
        return 1
    fi
}


# ======================== IRESfinder Run ========================
run_IRESfinder() {
    log_message "IRESfinder running..."

    log_message "Checking indentation of line 47 in IRESfinder.py..."
    IRES_PY="$PWD/packs/IRESfinder/IRESfinder.py"

    LINE_47=$(sed -n '47p' "$IRES_PY")
    PREFIX=$(echo "$LINE_47" | sed -E 's/[^ ].*//') 

    SPACE_COUNT=$(echo -n "$PREFIX" | wc -c)

    if [[ "$SPACE_COUNT" -ne 8 ]]; then
        log_message "Fixing indentation on line 47..."
        sed -i '47s/^[ \t]*/        /' "$IRES_PY"
    fi

    log_message "Activating Python 2.7 environment..."
    source activate py27_env || { log_message "Error: Conda environment activation failed."; exit 1; }

    python "$IRES_PY" -f "$TARGET_FILE" -o "$PWD/results/ORF/IRESfinder_mode_1.result" -m 1
    python "$IRES_PY" -f "$TARGET_FILE" -o "$PWD/results/ORF/IRESfinder_mode_2.result" -m 2 -w 174 -s 50

    if [[ $? -eq 0 ]]; then
        log_message "IRESfinder completed"
    else
        log_message "ERROR: IRESfinder failed！"
        exit 1
    fi

    log_message "Deactivating conda environment..."
    conda deactivate
}

# ======================== ORFfinder Run ========================
run_ORFfinder() {
    log_message "ORFfinder running..."
    $PWD/packs/ORFfinder -in "$TARGET_FILE" -out "$PWD/results/ORF/ORFfinder.fa"
    
    if [[ $? -eq 0 ]]; then
        log_message "ORFfinder completed"
    else
        log_message "ERROR: ORFfinder failed！"
        exit 1
    fi
}

# ======================== main ========================
main() {
    run_RNAhybrid
    run_miRanda
    run_TargetScan
    RNAhybrid_miRanda_merge
    run_beRBP
    run_ENCORI
    beRBP_ENCORI_merge
    run_IRESfinder
    run_ORFfinder
}

# execute main
main
