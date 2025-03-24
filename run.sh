#!/bin/bash

# 设置日志文件
LOG_FILE="run_log.txt"
echo "Running Log - $(date)" > "$LOG_FILE"

# 记录日志的函数
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# 设置运行目录为当前工作目录
RUN_DIR="$PWD/local"
mkdir -p "$RUN_DIR"

# 设置结果输出目录
OUTPUT_DIR="$PWD/results"

# 检查并创建目录（如果不存在的话）
mkdir -p "$OUTPUT_DIR/miRNA"
mkdir -p "$OUTPUT_DIR/RBP"
mkdir -p "$OUTPUT_DIR/ORF"

# 让用户输入 query 和 target 的 FASTA 文件路径
read -p "请输入 circRNA 序列文件路径 (target)：" TARGET_FILE
read -p "请输入 microRNA 序列文件路径 (query)：" QUERY_FILE

# 检查输入文件是否存在
if [[ ! -f "$QUERY_FILE" || ! -f "$TARGET_FILE" ]]; then
    log_message "错误: 输入文件不存在！"
    exit 1
fi

# ======================== RNAhybrid 运行 ========================
run_RNAhybrid() {
    log_message "运行 RNAhybrid..."
    RNAhybrid -t "$TARGET_FILE" -q "$QUERY_FILE" -s 3utr_human > "$PWD/results/miRNA/hybrid.txt"
    
    if [[ $? -eq 0 ]]; then
        log_message "RNAhybrid 运行完成，结果保存在 results/miRNA/hybrid.txt"
    else
        log_message "错误: RNAhybrid 运行失败！"
        exit 1
    fi

    python3 "$PWD/codes/miRNA/extract_RNAhybridRes.py"
}

# ======================== miRanda 运行 ========================
run_miRanda() {
    log_message "运行 miRanda..."
    "$PWD/packs/miranda/bin/miranda" "$QUERY_FILE" "$TARGET_FILE"  > "$PWD/results/miRNA/miRanda.txt"
    
    if [[ $? -eq 0 ]]; then
        log_message "miRanda 运行完成，结果保存在 results/miRNA/miRanda.txt"
    else
        log_message "错误: miRanda 运行失败！"
        exit 1
    fi

    python3 "$PWD/codes/miRNA/extract_miRandaRes.py"
}

# ======================== miRNA-circRNA 结果整合 ========================
RNAhybrid_miRanda_merge() {
    log_message "合并 RNAhybrid 和 miRanda 结果..."
    python3 "$PWD/codes/miRNA/RNAhybrid_miRanda_merge.py"
    
    if [[ $? -eq 0 ]]; then
        log_message "结果整合完成"
    else
        log_message "错误: 结果整合失败！"
        exit 1
    fi
}


# ======================== beRBP 运行 ========================
run_beRBP() {
    # 复制目标文件
    cp "$TARGET_FILE" "$PWD/packs/beRBP/work/temp/001.fasta"

    # 切换到 beRBP 代码目录
    cd "$PWD/packs/beRBP/code/" || { echo "Error: Failed to enter directory $PWD/beRBP/code/"; return 1; }

    # 确保 core_csrv.sh 存在
    if [[ ! -f core_csrv.sh ]]; then
        echo "Error: core_csrv.sh not found!"
        return 1
    fi

    # 备份 core_csrv.sh 以防修改出错
    cp core_csrv.sh core_csrv.sh.bak

    # 修改 core_csrv.sh 的 blastn 语句
    python core_csrv_mod.py
    
    cd ../work

    mkdir -p temp

    # 运行 general
    ../code/general_sPWM.sh 001 "all" "all" > temp/001.log &

    # 等待任务完成
    wait

    # 移动
    if [[ -f 001/resultMatrix.tsv ]]; then
        cp 001/resultMatrix.tsv ../../../results/RBP/beRBP.tsv
        echo "Moved resultMatrix.tsv to /results/RBP/beRBP.tsv"
    else
        echo "Error: resultMatrix.tsv not found!"
        return 1
    fi

    echo "run_beRBP completed successfully."

    cd ../../../
}

# ======================== ENCORI 运行 ========================
run_ENCORI() {
    mkdir -p "$PWD/results/RBP"
    echo "Downloading ENCORI RBP-Target data for circRNAs..."
    curl 'https://rnasysu.com/encori/api/RBPTarget/?assembly=hg38&geneType=circRNA&RBP=all&clipExpNum=5&pancancerNum=0&target=all&cellType=HeLa' \
        -o "$PWD/results/RBP/ENCORI_hg38_RBPTarget_all_circRNA_HeLa.txt"
    echo "Download completed. Data saved to $PWD/results/RBP/ENCORI_hg38_RBPTarget_all_circRNA_HeLa.txt"
}

# ======================== RBP-circRNA 结果整合 ========================
beRBP_ENCORI_merge() {

    # 定义输入文件路径
    ENC_FILE="$PWD/results/RBP/ENCORI_hg38_RBPTarget_all_circRNA_HeLa.txt"
    RBP_FILE="$PWD/results/RBP/beRBP.tsv"
    OUTPUT_FILE="$PWD/results/RBP/merged_output.txt"

    # 执行 Python 合并脚本
    python "$PWD/codes/RBP/beRBP_ENCORI_merge.py" "$ENC_FILE" "$RBP_FILE" "$OUTPUT_FILE"

    # 检查是否成功生成合并文件
    if [[ -f "$OUTPUT_FILE" ]]; then
        echo "Merge completed successfully. Output saved to $OUTPUT_FILE"
    else
        echo "Error: Merge output file not created!"
        return 1
    fi
}


# ======================== IRESfinder 运行 ========================
run_IRESfinder() {
    log_message "IRESfinder 运行中..."

    # 检查 IRESfinder.py 第 47 行的缩进
    log_message "Checking indentation of line 47 in IRESfinder.py..."
    IRES_PY="$PWD/packs/IRESfinder/IRESfinder.py"

    # 读取第 47 行的前缀字符
    LINE_47=$(sed -n '47p' "$IRES_PY")
    PREFIX=$(echo "$LINE_47" | sed -E 's/[^ ].*//') 

    SPACE_COUNT=$(echo -n "$PREFIX" | wc -c)

    if [[ "$SPACE_COUNT" -ne 8 ]]; then
        log_message "Fixing indentation on line 47..."
        sed -i '47s/^[ \t]*/        /' "$IRES_PY"
    fi

    # 激活 Python 2.7 conda 环境
    log_message "Activating Python 2.7 environment..."
    source activate py27_env || { log_message "Error: Conda environment activation failed."; exit 1; }

    # 运行 IRESfinder
    python "$IRES_PY" -f "$TARGET_FILE" -o "$PWD/results/ORF/IRESfinder_mode_1.result" -m 1
    python "$IRES_PY" -f "$TARGET_FILE" -o "$PWD/results/ORF/IRESfinder_mode_2.result" -m 2 -w 174 -s 50

    # 检查运行是否成功
    if [[ $? -eq 0 ]]; then
        log_message "IRESfinder 运行完成"
    else
        log_message "错误: IRESfinder 运行失败！"
        exit 1
    fi

    # 退出 conda 环境
    log_message "Deactivating conda environment..."
    conda deactivate
}

# ======================== ORFfinder 运行 ========================
run_ORFfinder() {
    log_message "ORFfinder 运行中..."
    $PWD/packs/ORFfinder -in "$TARGET_FILE" -out "$PWD/results/ORF/ORFfinder.fa"
    
    if [[ $? -eq 0 ]]; then
        log_message "ORFfinder 运行完成"
    else
        log_message "错误: ORFfinder 运行失败！"
        exit 1
    fi
}

# ======================== 主函数 ========================
main() {
    run_RNAhybrid
    run_miRanda
    RNAhybrid_miRanda_merge
    run_beRBP
    run_ENCORI
    beRBP_ENCORI_merge
    run_IRESfinder
    run_ORFfinder
}

# 执行主函数
main
