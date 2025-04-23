#!/bin/bash

#SBATCH --partition=fast
#SBATCH --job-name=Config_snakemake

# Description: This script takes a configuration file, a snakefile and a path to the conda environments (yaml files).
# Usage: ./Configuration.sh -f config_file -s snakefile -c path_to_environment
# Input: config_file = configuration file containing the parameters to run the snakemake modified by the user
#        snakefile = path to the snakefile from which to extract the name of the environment and the programs to
#                     add in each environment
#        path_to_environment = path to where the conda environments will be stored
# Output: folders with configuration files used to run the snakemake (conda environment, cluster-user profile, variables)
# Date: 29 September 2024
# Author: Basile Pajot
#########################################################################################################################

# First, we import and parse the input arguments
while getopts hf:s:c: opt; do
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
      echo "          -c        Folder in which to create the environment files"
      echo "          -h        Displays this help message"
      exit 0
      ;;
   f)
      config_file="${OPTARG}"
      ;;
   s)
      SNAKEFILE="${OPTARG}"
      ;;
   c)
      CONFIG_PATH="${OPTARG}"
      ;;
   esac
done

# First, we extract the R and python packages
## To do so, we cut the input file to know where the R and Python packages are stored
line_number_r_packages=$(grep -n "R and R packages" "${config_file}" | cut -d":" -f1)
line_number_python_packages=$(grep -n "Python and Python packages" "${config_file}" | cut -d":" -f1)
# And then, we extract the list of all the R and python packages to be used
if [[ "${line_number_r_packages}" -gt "${line_number_python_packages}" ]]; then
   r_packages=$(awk '/R and R packages/,/\n/' "${config_file}" | grep -v "#")
   python_packages=$(awk '/Python and Python packages/,/R and R packages/' "${config_file}" | grep -v "#")
else
   r_packages=$(awk '/R and R packages/,/Python and Python packages/' "${config_file}" | grep -v "#")
   python_packages=$(awk '/Python and Python packages/,/\n/' "${config_file}" | grep -v "#")
fi

# Get bcftools if it is in the configuration file
bcftools_line=$(grep "bcftools" "${config_file}")
# Create some variables to be used in the for loop
rule="False"
in_shell="False"
# Make a list of the dependencies
dependencies=$(awk '/dependencies:/,/\n/' "${config_file}")
# And prepare a prefix to be used when creating a new environment file
prefix_config_file=$(awk '/name: Environment/,/dependencies/' "${config_file}" | grep -v "#")

# Then, we iterate over the line in the snakefile to identify the shell commands in the rules
cat "${SNAKEFILE}" | while read line; do
   # While iterating over the lines in the file, the first line of the rule is the rule name which are all starting with the same prefix
   if [[ "${line}" == *"rule N"* ]] || [[ "${line}" == *"rule:"* ]]; then
      # If we detect this prefix, the following lines that will be read are the ones in the rule.
      rule="True"
      # We extract the rule name to be used to identify the environments.
      if [[ "${line}" != *"rule:"* ]]; then
         rule_name=$(echo "${line}" | sed 's/[^N]*\(N[^ .]*\)/\1\n/g; s/://g')
      fi
   fi
   if [[ "${rule}" == "True" ]]; then
      if [[ "${line}" == *"name:"* ]]; then
         rule_name=$(echo "${line}" | awk '{print $2}' | perl -pe "s/\.\{step.split\('_'\)\[0\]}//g; s/_on_\{this_step\(step\)\}//g; s/^f//g" | sed 's/"//g')
      fi
      # Once we are in the rule, we are looking for the shell script delimitated by '"""'
      if [[ "${line}" == *'"""'* ]] && [[ "${in_shell}" == "False" ]]; then
         # Once we identify the delimiter, we are in the rule
         in_shell="True"
      elif [[ "${line}" == *'"""'* ]] && [[ "${in_shell}" == "True" ]]; then
         # And if we are in the rule and identify the delimiter again, we are getting out of the shell script
         in_shell="False"
         rule="False"
      elif [[ "${in_shell}" == "True" ]]; then
         # And while we are in the shell script, we need to find which program each shell script calls, so we iterate over the possible ones
         echo "${dependencies}" | while read program; do
            # We remove the format from the yaml file to keep only the name of the progam
            simplified_line=$(echo ${program//- /} | sed 's/ = //g; s/[0-9]//g; s/\.//g')
            if [[ "${simplified_line}" == "r" ]]; then
               # We reparate the case with R which is a little bit different (we call RScript rather than R in the shell scripts)
               simplified_line="Rscript"
            fi
            if [[ "${simplified_line}" == "tabix" ]] && [[ "${line}" == *"bgzip"* ]]; then
               if [ ! -f "${CONFIG_PATH}/${rule_name}.yaml" ]; then
                  # And if the file does not exist, we add the header to the environement file
                  mkdir -p "${CONFIG_PATH}/"
                  echo -e "${prefix_config_file}" | sed "s/name: Environments/name: '${rule_name}'/g" >"${CONFIG_PATH}/${rule_name}.yaml"
               else
                  __already_in__=$(grep "${simplified_line}" "${CONFIG_PATH}/${rule_name}.yaml")
                  if [ ! -z "${__already_in__:+x}" ]; then
                     continue
                  else
                     echo -e "  ${program}" >>"${CONFIG_PATH}/${rule_name}.yaml"
                  fi
               fi
            fi
            if [[ "${line}" == *"${simplified_line}"* ]]; then
               # If we find a match between the dependencies and the used programs in the shell script, we add this dependency to the environment yaml file
               if [ ! -f "${CONFIG_PATH}/${rule_name}.yaml" ]; then
                  # And if the file does not exist, we add the header to the environement file
                  mkdir -p "${CONFIG_PATH}/"
                  echo -e "${prefix_config_file}" | sed "s/name: Environments/name: '${rule_name}'/g" >"${CONFIG_PATH}/${rule_name}.yaml"
               fi
               # And if we use R or python, we add the list of packages to the environment file
               # TODO: find a way to add only the necessary R and python packages
               if [[ "${simplified_line}" == "Rscript" ]]; then
                  __r_version__=$(grep "r = " "${config_file}" | awk '{print $4}')
                  __already_in__=$(grep "r = ${__r_version__}" "${CONFIG_PATH}/${rule_name}.yaml")
                  if [ ! -z "${__already_in__:+x}" ]; then
                     continue
                  else
                     echo -e "${r_packages}" >>"${CONFIG_PATH}/${rule_name}.yaml"
                  fi
               elif [[ "${simplified_line}" == "python" ]]; then
                  __already_in__=$(grep "${simplified_line}" "${CONFIG_PATH}/${rule_name}.yaml")
                  if [ ! -z "${__already_in__:+x}" ]; then
                     continue
                  else
                     echo -e "${python_packages}" >>"${CONFIG_PATH}/${rule_name}.yaml"
                  fi
               else
                  __already_in__=$(grep "${program//-/}" "${CONFIG_PATH}/${rule_name}.yaml")
                  if [ ! -z "${__already_in__:+x}" ]; then
                     continue
                  else
                     echo -e "  ${program}" >>"${CONFIG_PATH}/${rule_name}.yaml"
                  fi
               fi
            fi
         done
         if [[ "${line}" == *"bgzip"* ]]; then
            echo -e "${bcftools_line}" >>"${CONFIG_PATH}/${rule_name}.yaml"
         fi
      fi
   fi
done
