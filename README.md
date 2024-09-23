# Snakemake processing of short-read sequencing data from *Littorina* snails

This folder contains all the standalone scripts and parameters to run the snakemake on several samples using the protocol from [J. Reeve et *al*., (2023)](https://www.protocols.io/private/C9EE16909F3011EE839C0A58A9FEAC02). 


The folder contains two sub_folders, two scripts and one example of a configuration file. We also added a zipped file to download the scripts more easily.



## [launcher.sh](./launcher.sh) (script)

This script, as its name indicates it is used as a launcher to start running the snakemake. It is used to call the scripts needed before running the snakemake, preparing the environment for it. It takes as input the configuration file (`configuration_file.yaml`) and the snakefile (`Processing_of_short-read_data.snk`). It allows to run all the scripts to prepare the environment to start running the snakemake.


## [Processing_short-read_data.snk](./Processing_short-read_data.snk) (script)

This script is the workflow. It uses the steps from the pipeline developed by [J. Reeve et *al*, (2023)](https://www.protocols.io/private/C9EE16909F3011EE839C0A58A9FEAC02). It creates files for each step depicted in the workflow. Some files might be temporary files and disapear from one step to the next if their keeping is not judged necessary. You can change which files are necessary and which are not in this file.

### Warning !!

The flexible allocated memory functions in the `Processing_short-read_data.snk` were only tested using a maximum of 10 threads and files no bigger than 24G (~ 12X). If you use different thread parameters or different input file size, please beware as the cluster out of memory handler might cancel your jobs. You can change the memory allocations in this file in the `get_mem_step_nb` functions.

## [Scripts_snk](./Scripts_snk/) (directory)

This folder contains the scripts and functions that are used as accessories in the launcher and the snakemake during their execution.
There are three files in this folder containing the scripts for these functions.

### [Configuration.sh](./Scripts_snk/Configuration.sh) (script)

This script allows to parse the configuration file into separate configuration files that are used to run the snakemake and prepare the conda environment to use.

### [snakemake_functions.py](./Scripts_snk/snakemake_functions.py) (script)

This script contains custom functions that allow to run the snakemake and parallelise it at best.

### [Graph_quanlity.r](./Scripts_snk/Graph_quality.r) (script)

This is an R script that allows to plot the quality of the VCF file after a filtration process. 

## configuration_file.yaml (configuration)

This file contains all the configurations you need to change to adapt the workflow to your data. __Please go through this file and change the paths and parameters to match your directories/clusters parameters!__
This file is structured in a particular way. It is separated into two parts with the use of:
```
---------------------------------------------------------
-----------------------  Profile  -----------------------
---------------------------------------------------------
name: Profile
```
These flags (with the "-") are used to parse this file so please keep them. In addition, the `name` tag is reserved to name the configuration files that are used by the snakemake. The three ones here are the only necessary ones. Of course, if you want to add some configuration files in the snakemake, you are welcome to add some flags in the `configuration_file.yaml` with a new `name` tag, or in the existing ones.

:warning: :warning: There are some paths that are required to be changed in the "Variables" and the "Profile" flags. __Please change them before running the snakemake.__ :warning: :warning:

## How to run the script ?

1. First, you need to download the files separatedly or the zipped files.
1. Unzip the file by typing:
```
tar -zxf snakemake_package.tar.gz
```
1. Change the paths in the places that are indicated before in the `README.md` file.
1. Finally, you can place yourself in this terminal and type:
```
sbatch launcher.sh -f configuration_file.yaml -s Processing_short-read_data.snk
```
