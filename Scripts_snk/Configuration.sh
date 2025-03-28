#!/bin/bash

#SBATCH --partition=fast
#SBATCH --job-name=Config_snakemake

# Description: This script takes a configuration file and a working directory and outputs configuration folders for the snakemake
# Usage: ./Configuration.sh -w working_dir -c config_file
# Input: working_dir = working directory from where the snakemake is run
#        config_file = configuration file containing the parameters to run the snakemake modified by the user
# Output: folders with configuration files used to run the snakemake (conda environment, cluster-user profile, variables)
# Date: 29 September 2024
# Author: Basile Pajot
#########################################################################################################################

# First, we import and parse the input arguments
while getopts h:c:w: opt; do
    case "${opt}" in
    [h?])
        echo "This script starts running the snakemake to process short-read data"
        echo ""
        echo "  Usage launcher.sh -f configuration_file.yaml -s snakefile.snk"
        echo ""
        echo "      Options:"
        echo "          -w        Working directory from where the snakemake is run"
        echo "          -c        Name of the snakemake configuration file modified by the user"
        echo "          -h        Displays this help message"
        exit 0
        ;;
    c)
        config_file="${OPTARG}"
        ;;
    w)
        HERE="${OPTARG}"
        ;;
    esac
done

echo "Preparing configuration file: ${config_file}"

# First, we add a line to the default resources so the snakemake can write in the chosen temporary folder
if [ ! -n "$(grep 'tmpdir' ${config_file})" ]; then
    __tmp_path__=$(grep "tmp_path" "${config_file}" | cut -d" " -f2)
    sed -i "/mem_mb=/a \ \ - tmpdir=${__tmp_path__}" "${config_file}"
fi

# First, we split the configuration file in seperate files
awk '/^name:/{close(file); file=$NF"_config.yaml"}; file!="" && !/^--/{print > (file)}' "${HERE}/${config_file}"

# Then, we remove the first line that is not needed in each file and move them to different locations
for FILE in $(ls "${HERE}"/*_config.yaml); do

    # First, we remove the first line of the file
    sed -i "1d" "${FILE}"

    # Then, we move the modified file to the new location
    ## To do so, we need the prefix of the file name (removing the "_config.yaml")
    PREFIX=$(echo "${FILE##*/}" | sed "s/_config.yaml//g")
    # Then, we select the name of the folder to be used
    if [[ "${PREFIX}" == "Profile"* ]]; then
        PREFIX="Cluster_profile"
        File_name="config.yaml"
    elif [[ "${PREFIX}" == "Variable"* ]]; then
        PREFIX="Configuration_files"
        File_name="${FILE##*/}"
        # We also add the working directory to the configuration file with the variables
        echo "########################  Other info  ###############################" >>"${FILE}"
        echo "# Working directory (where is the snakemake located?)" >>"${FILE}"
        echo "Working_directory: '${HERE}/'" >>"${FILE}"
    elif [[ "${PREFIX}" == "Environment"* ]]; then
        rm "${HERE}/Environments_config.yaml"
        continue
    fi
    # Then, we create the folders in which the configuration files will be stored
    mkdir -p "${HERE}/${PREFIX}"
    # And move the file to the new location
    mv "${FILE}" "${HERE}/${PREFIX}/${File_name}"
done

# Finally, in the end, we add a file to the "Configuration_files" folder to store the
# date of the last modification of the configuration file
stat -c %Y "${HERE}/${config_file}" >"${HERE}/Configuration_files/Date_modif_config.txt"
