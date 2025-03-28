#!/bin/bash

#SBATCH --partition=long
#SBATCH --job-name=Short_read_snakemake
#SBATCH --cpus-per-task=8
#SBATCH --mem=10G

# Description: This script prepares the environment and runs the snakemake workflow
# Usage: sbatch launcher.sh -f config_file -s Snakefile
# Input: config_file = configuration file containing the parameters to run the snakemake modified by the user
#        Snakefile = Name of the snakefile that contains the workflow
# Date: 29 September 2024
# Author: Basile Pajot
#########################################################################################################################
# First, we import and parse the input arguments
while getopts h:f:s: opt; do
    case "${opt}" in
    [h?])
        echo "This script starts running the snakemake to process short-read data"
        echo ""
        echo "  Usage launcher.sh -f configuration_file.yaml -s snakefile.snk"
        echo ""
        echo "      Options:"
        echo "          -f        Name of the configuration file using the same format as the ones specified in the examples on"
        echo "                    https://github.com/PAJOT-Basile/Snakemake_processing_of_short-read_data"
        echo "          -s        Name of the snakefile to run the snakemake"
        echo "          -h        Displays this help message"
        exit 0
        ;;
    f)
        config_file="${OPTARG}"
        ;;
    s)
        SNAKEFILE="${OPTARG}"
        ;;
    esac
done
# And we check that we have the right inputs
if [ -z "${config_file}" ] || [ -z "${SNAKEFILE}" ]; then
    echo "################################################################################"
    echo "Error in arguments, the -f  and -s arguments are mandatory."
    echo "Please type ./launcher.sh -h to get the help"
    exit 0
fi

# Then, we can start executing the script. The first step is to localise the directory in which the scripts
# are localised
HERE="$(pwd)"

# Then, we separate the input configuration file into two independent configuration files that will be used to execute the snakefile
# If it is the first time you run the snakemake or the configuration file has been modified, it will restart this step
RUN="False"
if [ ! -d "${HERE}/Configuration_files" ]; then
    RUN="True"
elif [[ "$(cat ${HERE}/Configuration_files/Date_modif_config.txt)" != "$(stat -c %Y ${HERE}/${config_file})" ]]; then
    RUN="True"
fi
# Then, we run the script that allows to separate the configuration file in two to prepare the run for the snakemake
if [[ "${RUN}" = "True" ]]; then
    printf "\rPreparing configuration file: ${config_file} ..."
    "${HERE}/Scripts_snk/Configuration.sh" -w "${HERE}" -c "${config_file}"
    printf "\rPreparing configuration file: ${config_file} ...              DONE\n"
fi

# Check if the environment files are already created and if not, create them
if [[ ! -d "${HERE}/Configuration_files/envs/" ]]; then
    printf "\rCreating environments ..."
    "${HERE}/Scripts_snk/Create_envs.sh" -f "${config_file}" -s "${SNAKEFILE}" -c "${HERE}/Configuration_files/envs/"
    "${HERE}/Scripts_snk/Create_envs.sh" -f "${config_file}" -s "${HERE}/Scripts_snk/Index_ref_genome.snk" -c "${HERE}/Configuration_files/envs/"
    printf "\rCreating environment ...         DONE\n"
fi

# Where to put temporary files
TMPDIR="$(grep "tmp_path" ${HERE}/${config_file} | cut -f2 -d'"')"
TMP="${TMPDIR}"
TEMP="${TMPDIR}"
mkdir -p "${TMPDIR}"
export TMPDIR TMP TEMP

module load snakemake/7.25.0
# Run the snakemake to index the reference genome
printf "\rIndexing reference genome"
snakemake -s "${HERE}/Scripts_snk/Index_ref_genome.snk" --profile "${HERE}/Cluster_profile" --configfile "${HERE}/Configuration_files/Variables_config.yaml" --quiet all
printf "\rIndexing reference genome ...     DONE\n"

echo "Starting Snakemake execution"
# Run the snakemake file
snakemake -s "${HERE}/${SNAKEFILE}" --profile "${HERE}/Cluster_profile" --configfile "${HERE}/Configuration_files/Variables_config.yaml"

module unload snakemake/7.25.0
echo "Snakemake execution ...            DONE"
