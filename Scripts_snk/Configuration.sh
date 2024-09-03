#!/bin/bash

#SBATCH --partition=fast
#SBATCH --job-name=Config_snakemake

HERE="${1}"
config_file="${2}"

echo "Preparing configuration file: ${config_file}"

# First, we split the configuration file in seperate files
awk '/name:/{close(file); file=$NF"_config.yaml"}; file!="" && !/^--/{print > (file)}' "${HERE}/${config_file}"

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
        PREFIX="Configuration_files/envs"
        File_name="Environment.yaml"
    fi
    # Then, we create the folders in which the configuration files will be stored
    mkdir -p "${HERE}/${PREFIX}"
    # And move the file to the new location
    mv "${FILE}" "${HERE}/${PREFIX}/${File_name}"
done

# Finally, in the end, we add a file to the "Configuration_files" folder to store the
# date of the last modification of the configuration file
stat -c %Y "${HERE}/${config_file}" >"${HERE}/Configuration_files/Date_modif_config.txt"
