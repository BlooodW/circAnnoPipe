# circAnnoPipe
An integrated pipeline used for circRNA annotation, including the prediction of circRNA-miRNA interactions, circRNA-RBP interactions and abilities of translation.

##### PREREQUISITES ######
########################
1. R 4.4+

2. Ncbi-blast v2.2.31+ 

3. Unzipp the file with # tar -xzvf packs.tar.gz

3. Reference Genome: HG38.fa
    Please download the file from http://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz. 
    Uncompress hg38.fa.gz into HG38.fa (make sure to match the exact capitalization) and put it at /test/packs/beRBP/HG38/HG38.fa

4. Conservation Score File: hg38.phyloP100way.bw
	This file for conservation score is pretty big (~10G). Please download the file hg38.phyloP100way.bw at http://bioinfo.vanderbilt.edu/beRBP/download.html or http://hgdownload.cse.ucsc.edu/goldenpath/hg38/phyloP100way/hg38.phyloP100way.bw, and put it at /test/beRBP/lib/hg38.phyloP100way.bw.

########################
##### HOW TO RUN ######
########################
1. Setting Up the Environment
   Before executing the pipeline, install the required packages and configure the environment:
    If you do not have sudo privileges, run: /test/pre-run.sh
    If you have sudo privileges, run: /test/pre-run_sudo.sh

2. Running the Pipeline
    Once the environment is set up, execute the main script to run all necessary tools automatically: /test/run.sh

##########################################
################# OUTPUT #################
##########################################
All results and generated files will be stored in: /test/results
