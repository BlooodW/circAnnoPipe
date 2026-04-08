#!/bin/bash

LOG_FILE="install_log.txt"
echo "Installation Log - $(date)" > "$LOG_FILE"

log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# set direction
INSTALL_DIR="$HOME/local"
mkdir -p "$INSTALL_DIR"

cd packs

# ======================== RNAhybrid Installation ========================
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
    
    if command -v conda &> /dev/null; then
        log_message "Using conda environment to install dependencies..."
        conda create -y -n RNAhybrid_env make gcc wget
        log_message "Dependencies installed in conda environment 'RNAhybrid_env'."
    else
        log_message "Conda not found. Please ensure 'make', 'gcc', and 'wget' are installed."
    fi
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


RNAhybrid_configure_and_compile() {
    log_message "Configuring RNAhybrid..."
    ./configure --prefix="$INSTALL_DIR" || { log_message "Error: Configuration step failed."; exit 1; }
    log_message "Configuration completed, starting compilation..."
    make || { log_message "Error: Compilation failed."; exit 1; }
    log_message "Compilation completed, running checks..."
    make check || { log_message "Error: Check failed."; exit 1; }
    log_message "Check passed, installing RNAhybrid..."
    make install || { log_message "Error: Installation failed."; exit 1; }
    log_message "RNAhybrid installation completed."
    cd ../
}

# ======================== miRanda Installation ========================
extract_and_navigate_to_miranda() {
    log_message "Uncompressing miranda-3.3a-0.tar.bz2..."
    cd miranda
    tar -xjf miranda-3.3a-0.tar.bz2 || { log_message "Error: Uncompressing failed."; exit 1; }
    log_message "Uncompressing completed."
    cd ../
}

# ======================== TargetScan Installation ========================
install_TargetScan() {
  log_message "Installing TargetScan required dependencies..."

  source "$(conda info --base)/etc/profile.d/conda.sh" || {
    log_message "Error: cannot source conda.sh"
    exit 1
  }

  if conda env list | awk '{print $1}' | grep -qx "bio_env"; then
    log_message "Conda env exists: bio_env"
  else
    log_message "Creating conda env: bio_env"
    conda create -y -n bio_env -c conda-forge python=3.10 || {
      log_message "Error: Environment creation failed."
      exit 1
    }
  fi

  conda activate bio_env || {
    log_message "Error: conda activate failed."
    exit 1
  }

  log_message "Installing biopython..."
  conda install -y -c conda-forge biopython || {
    log_message "Error: biopython install failed."
    conda deactivate
    exit 1
  }

  log_message "Installing perl..."
  conda install -y -c conda-forge perl || {
    log_message "Error: perl install failed."
    conda deactivate
    exit 1
  }

  log_message "Installing perl-bioperl..."
  conda install -y -c conda-forge -c bioconda perl-bioperl || {
    log_message "Error: perl-bioperl install failed."
    conda deactivate
    exit 1
  }

  log_message "Installing perl-xml-parser..."
  export CONDA_SOLVER=libmamba
  conda install -y -c conda-forge conda-libmamba-solver >/dev/null 2>&1 || true
  conda config --set channel_priority strict >/dev/null 2>&1 || true
  conda install -y -c conda-forge expat perl-xml-parser || {
    log_message "Error: perl-xml-parser install failed."
    conda deactivate
    exit 1
  }

  log_message "Installing perl-xml-twig..."
  conda install -y -c conda-forge -c bioconda perl-xml-twig || {
    log_message "Error: perl-xml-twig install failed."
    conda deactivate
    exit 1
  }

  log_message "Installing perl-statistics-lite..."
  conda install -y -c conda-forge -c bioconda perl-statistics-lite || {
    log_message "Error: perl-statistics-lite install failed."
    conda deactivate
    exit 1
  }

  log_message "Installing cpanminus (optional)..."
  conda install -y -c conda-forge perl-app-cpanminus || {
    log_message "Warning: perl-app-cpanminus install failed (continuing)."
  }

  log_message "Verifying Perl modules..."
  perl -MXML::Parser -e '1' >/dev/null 2>&1 || { log_message "Error: XML::Parser not usable"; conda deactivate; exit 1; }
  perl -MXML::Twig -e '1'   >/dev/null 2>&1 || { log_message "Error: XML::Twig not usable"; conda deactivate; exit 1; }
  perl -MBio::Perl -e '1'   >/dev/null 2>&1 || { log_message "Error: Bio::Perl not usable"; conda deactivate; exit 1; }
  perl -MStatistics::Lite -e '1' >/dev/null 2>&1 || { log_message "Error: Statistics::Lite not usable"; conda deactivate; exit 1; }

  log_message "TargetScan dependency setup completed."
  conda deactivate
}


# ======================== beRBP Installation ========================
install_beRBP() {
    log_message "Installing beRBP..."
    cd beRBP || { log_message "Error: Unable to enter beRBP directory."; exit 1; }
    mkdir -p lib
    cd lib || { log_message "Error: Unable to create lib directory."; exit 1; }
    # wget https://bioinfo.vanderbilt.edu/beRBP/download/hg38.phyloP100way.bw
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
    ./configure --prefix="$INSTALL_DIR" && make && make check && make install || { log_message "Error: ViennaRNA installation failed."; exit 1; }
    cd ../
    log_message "ViennaRNA installed successfully."
}

install_bigWigToWig() {
    log_message "Installing bigWigToWig..."
    cd beRBP
    chmod +x bigWigToWig
    log_message "bigWigToWig installed successfully."
}

create_blastdb() {
    log_message "Creating BLAST database..."
    mkdir -p HG38
    cd HG38 || { log_message "Error: Unable to enter HG38 directory."; exit 1; }
    makeblastdb -dbtype nucl -in hg38.fa -out HG38
    makembindex -input HG38
    if [ $? -ne 0 ]; then
        log_message "Error: Failed to create BLAST database."
        exit 1
    fi
    log_message "BLAST database created successfully."
    cd ../../
}

# ======================== IRESfinder Installation ========================
install_IRESfinder() {
    log_message "Installing IRESfinder..."
    
    # check conda installation
    if ! command -v conda &> /dev/null; then
        log_message "Error: Conda is not installed. Please install Miniconda or Anaconda first."
        exit 1
    fi

    log_message "Creating conda environment for Python 2.7..."
    conda create -y -n py27_env python=2.7
    source activate py27_env

    log_message "Installing dependencies..."
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py
    python get-pip.py
    rm get-pip.py
    pip install numpy==1.16.6 scipy==1.2.3 scikit-learn==0.17 biopython==1.76

    log_message "Cloning IRESfinder repository..."
    git clone https://github.com/xiaofengsong/IRESfinder.git
    cd IRESfinder || { log_message "Error: Unable to enter IRESfinder directory."; exit 1; }

    # test
    log_message "Running IRESfinder test..."
    python IRESfinder.py -f examples/example_mode_1.fa -o example_mode_1.result -m 1
    python IRESfinder.py -f examples/example_mode_2.fa -o example_mode_2.result -m 2 -w 174 -s 50

    conda deactivate
    cd ../
    
    log_message "IRESfinder installation and test completed."
}


# ======================== ORFfinder Installation ========================
install_ORFfinder() {
    log_message "Installing ORFfinder..."

    chmod +x ORFfinder

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        log_message "Error: Unable to detect OS."
        exit 1
    fi

    # install libdw
    case "$OS" in
        ubuntu|debian) 
            log_message "Attempting to install libdw locally..."
            mkdir -p "$HOME/local"
            export PREFIX="$HOME/local"
            export PATH="$PREFIX/bin:$PATH"
            export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
            export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
            
            cd "$HOME/local" || exit 1
            wget http://ftp.debian.org/debian/pool/main/e/elfutils/elfutils_0.188.orig.tar.bz2
            tar -xjf elfutils_0.188.orig.tar.bz2
            cd elfutils-0.188 || exit 1
            ./configure --prefix="$PREFIX" --disable-nls
            make -j"$(nproc)"
            make install
            log_message "libdw installed locally."
            ;;
        centos|rhel|rocky|almalinux|fedora|arch) 
            log_message "Please install libdw manually for your system ($OS) as user."
            ;;
        *) log_message "Unsupported OS: $OS"; exit 1 ;;
    esac

    log_message "ORFfinder installation completed."
}

# ======================== main ========================
main() {
    #install_TargetScan
    if ! RNAhybrid_check_installed; then
        RNAhybrid_install_dependencies
        extract_rnahybrid
        enter_rnahybrid_dir
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

# execute main
main
