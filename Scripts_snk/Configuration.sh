#!/bin/bash

#SBATCH --partition=fast
#SBATCH --job-name=Config_snakemake

HERE=${1}
config_file=${2}

# First, we split the configuration file in seperate files
awk '/name:/{close(file); file=$NF"_config.yaml"}; file!="" && !/^--/{print > (file)}' ${HERE}/configuration_file.yaml

# Then, we remove the first line that is not needed in each file and move them to different locations
for FILE in $(ls ${HERE}/*_config.yaml); do

    # First, we remove the first line of the file
    sed -i "1d" ${FILE}

    # Then, we move the modified file to the new location
    ## To do so, we need the prefix of the file name (removing the "_config.yaml")
    PREFIX=$(echo "${FILE##*/}" | cut -d"_" -f1)
    # Then, we select the name of the folder to be used
    if [[ ${PREFIX} == "Profile"* ]]; then
        PREFIX="Cluster_profile"
        File_name="config.yaml"
    elif [[ ${PREFIX} == "Variable"* ]]; then
        PREFIX="Configuration_files"
        File_name="${FILE##*/}"
    fi
    # Then, we create the folders in which the configuration files will be stored
    mkdir -p ${HERE}/${PREFIX}
    # And move the file to the new location
    mv ${FILE} ${HERE}/${PREFIX}/"${File_name}"
done

# Finally, in the end, we add a file to the "Configuration_files" folder to store the
# date of the last modification of the configuration file
stat -c %Y ${HERE}/${config_file} > ${HERE}/Configuration_files/Date_modif_config.txt
