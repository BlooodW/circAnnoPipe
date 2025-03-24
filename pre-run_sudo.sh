#!/bin/bash

# 设置日志文件
LOG_FILE="install_log.txt"
echo "Installation Log - $(date)" > "$LOG_FILE"

# 记录日志的函数
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# 检查是否有 sudo 权限
check_sudo() {
    log_message "Checking for sudo privileges..."
    if ! sudo -v; then
        log_message "Error: This user does not have sudo privileges. Please run the script with a user that has sudo privileges."
        exit 1
    fi
}

cd packs

# ======================== RNAhybrid 安装 ========================
RNAhybrid_check_installed() {
    log_message "Checking if RNAhybrid is already installed..."
    if which RNAhybrid &> /dev/null; then
        log_message "RNAhybrid is already installed at $(which RNAhybrid). Skipping RNAhybrid installation."
        extract_and_navigate_to_miranda
        return 0
    fi
    log_message "RNAhybrid not found in PATH. Proceeding with installation..."
    return 1
}

RNAhybrid_install_dependencies() {
    log_message "Installing required dependencies..."
    sudo apt-get update
    sudo apt-get install -y build-essential wget
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to install dependencies."
        exit 1
    fi
    log_message "Dependencies installed successfully."
}

extract_rnahybrid() {
    log_message "Extracting RNAhybrid installation package..."
    tar -zxvf RNAhybrid-2.1.2.tar.gz || { log_message "Error: Extraction failed."; exit 1; }
    log_message "Extraction completed."
}

enter_rnahybrid_dir() {
    log_message "Entering RNAhybrid directory..."
    cd RNAhybrid-2.1.2 || { log_message "Error: Unable to enter RNAhybrid directory."; exit 1; }
}

clean_previous_build() {
    log_message "Cleaning previous build (if any)..."
    make clean || { log_message "Error: Failed to clean previous build."; exit 1; }
    log_message "Cleaned previous build successfully."
}

RNAhybrid_configure_and_compile() {
    log_message "Configuring RNAhybrid..."
    ./configure || { log_message "Error: Configuration step failed."; exit 1; }
    log_message "Configuration completed, starting compilation..."
    make || { log_message "Error: Compilation failed."; exit 1; }
    log_message "Compilation completed, running checks..."
    make check || { log_message "Error: Check failed."; exit 1; }
    log_message "Check passed, installing RNAhybrid..."
    sudo make install || { log_message "Error: Installation failed."; exit 1; }
    log_message "RNAhybrid installation completed."
}

# ======================== miRanda 安装 ========================
extract_and_navigate_to_miranda() {
    log_message "Uncompressing miranda-3.3a-0.tar.bz2..."
    cd miranda
    tar -xjf miranda-3.3a-0.tar.bz2 || { log_message "Error: Uncompressing failed."; exit 1; }
    log_message "Uncompressing completed."
    cd ../
}

# ======================== beRBP 及依赖安装 ========================
install_beRBP() {
    # wget https://bioinfo.vanderbilt.edu/beRBP/download/beRBP.tgz
    # if [ $? -ne 0 ]; then
    #    log_message "Error: Failed to download beRBP package."
    #    exit 1
    # fi
    # tar -xzvf beRBP.tgz
    # if [ $? -ne 0 ]; then
    #    log_message "Error: Extraction failed."
    #    exit 1
    #fi
    log_message "Installing beRBP..."
    cd beRBP || { log_message "Error: Unable to enter beRBP directory."; exit 1; }
    mkdir -p lib
    cd lib || { log_message "Error: Unable to create lib directory."; exit 1; }
    wget https://bioinfo.vanderbilt.edu/beRBP/download/hg38.phyloP100way.bw
    log_message "beRBP installation completed."
    cd ../../
}

install_randomForest() {
    log_message "Installing randomForest in R..."
    R -e "install.packages('randomForest')" || { log_message "Error: Failed to install randomForest."; exit 1; }
    log_message "randomForest package installed successfully."
}

install_ViennaRNA() {
    log_message "Installing ViennaRNA..."
    tar -xzvf ViennaRNA-2.7.0.tar.gz || { log_message "Error: Extraction failed."; exit 1; }
    cd ViennaRNA-2.7.0 || { log_message "Error: Unable to enter ViennaRNA directory."; exit 1; }
    ./configure && make && make check && sudo make install || { log_message "Error: ViennaRNA installation failed."; exit 1; }
    cd ../
    log_message "ViennaRNA installed successfully."
}

install_bigWigToWig() {
    log_message "Installing bigWigToWig..."
    cd beRBP
    # wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToWig -O bigWigToWig
    chmod +x bigWigToWig
    log_message "bigWigToWig installed successfully."
}

create_blastdb() {
    log_message "Creating BLAST database..."
    mkdir -p HG38
    cd HG38 || { log_message "Error: Unable to enter HG38 directory."; exit 1; }
    # wget http://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
    # gunzip hg38.fa.gz || { log_message "Error: Uncompressing hg38.fa.gz failed."; exit 1; }
    makeblastdb -dbtype nucl -in hg38.fa -out HG38
    makembindex -input HG38
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to create BLAST database."
        exit 1
    fi
    log_message "BLAST database created successfully."
    cd ../../
}

# ======================== IRESfinder 安装 ========================
install_IRESfinder() {
    log_message "Installing IRESfinder..."
    sudo apt-get install -y python2.7 python2.7-dev python-pip
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
    python2.7 get-pip.py
    rm get-pip.py
    virtualenv py27_env
    source py27_env/bin/activate
    pip install numpy==1.16.6 scipy==1.2.3 scikit-learn==0.17 biopython==1.76
    git clone https://github.com/xiaofengsong/IRESfinder.git
    cd IRESfinder || { log_message "Error: Unable to enter IRESfinder directory."; exit 1; }
    python IRESfinder.py -f examples/example_mode_1.fa -o example_mode_1.result -m 1
    python IRESfinder.py -f examples/example_mode_2.fa -o example_mode_2.result -m 2 -w 174 -s 50
    deactivate
    cd ../
    log_message "IRESfinder installation and test completed."
}

# ======================== ORFfinder 安装 ========================
install_ORFfinder() {
    chmod +x ORFfinder
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        log_message "Error: Unable to detect OS."
        exit 1
    fi
    case "$OS" in
        ubuntu|debian) sudo apt update && sudo apt install -y libdw-dev ;;
        centos|rhel|rocky|almalinux) sudo yum install -y elfutils-devel || sudo dnf install -y elfutils-devel ;;
        fedora) sudo dnf install -y elfutils-devel ;;
        arch) sudo pacman -Syu --noconfirm elfutils ;;
        *) log_message "Unsupported OS: $OS"; exit 1 ;;
    esac
    log_message "ORFfinder installation completed."
}

# ======================== 主函数 ========================
main() {
    check_sudo
    if ! RNAhybrid_check_installed; then
        RNAhybrid_install_dependencies
        extract_rnahybrid
        enter_rnahybrid_dir
        clean_previous_build
        RNAhybrid_configure_and_compile
    fi
    extract_and_navigate_to_miranda
    install_beRBP
    install_randomForest
    install_ViennaRNA
    install_bigWigToWig
    create_blastdb
    install_IRESfinder
    install_ORFfinder
}

# 执行主函数
main



