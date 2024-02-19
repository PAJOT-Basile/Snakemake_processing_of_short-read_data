#!/bin/bash

#SBATCH --partition=long
#SBATCH --job-name=Snakemake
#SBATCH --cpus-per-task 8

# Load the necessary modules
module load snakemake/7.25.0 fastqc/0.12.1 multiqc/1.13 fastp/0.23.1 samtools/1.15.1 bwa/0.7.17 bcftools/1.16 vcftools/0.1.16 multiqc/1.13 bcftools/0.1.16 

# Remove locking files
rm -rf .snakemake/incomplete/* .snakemake/locks/* .snakemake/tmp.*

# If it is the first time you run the snakemake, you will need an input file to start it. It is created here
if [[ ! -f "./input_file.txt" ]]; then
    touch ./input_file.txt
fi

# Where to put temporary files
TMPDIR="/shared/scratch/pacobar/bpajot/outputs/tmp/"
TMP="${TMPDIR}"
TEMP="${TMPDIR}"
mkdir -p "${TMPDIR}"
export TMPDIR TMP TEMP

# Run the snakemake file
snakemake -s snakefile.snk --profile profile_config --configfile config_files/config_params.yaml 
