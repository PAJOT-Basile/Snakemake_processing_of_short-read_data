# Snakemake processing of short-read sequencing data from Littorina snails

This folder contains all the standalone scripts and parameters to run the snakemake on several samples using the protocol from [J. Reeve et al](https://www.protocols.io/private/C9EE16909F3011EE839C0A58A9FEAC02). 


The folder contains two sub-folders and three scripts.

## [Config_files](./config_files/) (directory)

This folder contains the file `config_params.yaml`. In this file are given several paths, such as the path to the raw data, the path to the temporary storage files for the snakemake, but also for the programs run in the workflow, the path to the input reference genome and the path to the final storage of the output files.

It also contains some parameters to detect the samples to use as input in the snakemake workflow, how to cut the reference chromosomes (if necessary) to parallelise some steps in the late parts of the workflow and some memory allocation parameters.

This file requires you to change the following paths:
```
# Raw data path: where to find the raw data ?
raw_data_path: "/shared/projects/pacobar/input/rawfile/"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Temporary outputs in scratch that are needed to run the analysis
outputs_files: "/shared/scratch/pacobar/bpajot/outputs/"
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# Where to put temporary files for programs such as samtools
temp_path: "/shared/scratch/pacobar/bpajot/outputs/tmp/"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Where to save the final output data
final_output: "/shared/projects/pacobar/finalresult/bpajot/outputs/"
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Where is the reference genome
input_reference_genome: "/shared/projects/pacobar/input/reference/Reference_Littorina_saxatilis_reshape.fa"
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
The part to change is the part underlined with arrows. (The arrow lines do not exist in the file, they are simply added here to show which parts to change in the `config_params.yaml` file).


## [Profile_config](./profile_config/) (directory)

This folder contains the file `config.yaml`. In this file, some directives are given to the cluster on how to execute jobs in the workflow, such as the memory to use, the partition, where to put the logs files, how many jobs can be ran, ...

This file requires you to change the following paths: 
```
cluster:
  mkdir -p /shared/projects/pacobar/finalresult/bpajot/logs/{rule}/error_files/ &&
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  mkdir -p /shared/projects/pacobar/finalresult/bpajot/logs/{rule}/logs/ &&
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  sbatch
    --partition={resources.partition}
    --cpus-per-task={threads}
    --mem={resources.mem_mb}
    --job-name={rule}-{wildcards}
    --output=/shared/projects/pacobar/finalresult/bpajot/logs/{rule}/logs/{rule}-{wildcards}-%j.out
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    --error=/shared/projects/pacobar/finalresult/bpajot/logs/{rule}/error_files/{rule}-{wildcards}-%j.err
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    --parsable
```
These paths are to create the log files. The part to change is the part underlined with arrows. (The arrow lines do not exist in the file, they are simply added here to show which parts to change in the `config.yaml` file).

## [launcher.sh](./launcher.sh) (script)

This script, as its name indicates it is used as a launcher to start running the snakemake. It simply loads the required modules for the analysis to start and creates an empty file used as input for the snakemake workflow.
This file has to be changed for the part that precieses the path to the temporary file:
```
# Where to put temporary files
TMPDIR="/shared/scratch/pacobar/bpajot/outputs/tmp/"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
The part to change is the part underlined with arrows. (The arrow lines do not exist in the file, they are simply added here to show which parts to change in the `launcher.sh` file).

## [snakemake_functions.py](./snakemake_functions.py) (script)

This script contains custom functions to select the samples to use from the raw data, index the reference genome if it is not done and create regions of given size in the chromosomes to be able to go faster in the late steps of the program. The functions written in a separate file and are loaded in the snakemake so as to have a better readability of the script.

## [snakefile.snk](./snakefile.snk) (script)

This script is the workflow. It is inspired from the pipeline develloped by [J. Reeve et al](https://www.protocols.io/private/C9EE16909F3011EE839C0A58A9FEAC02). It takes as input the configuration files (`config_files/config_params.yaml` and `profile_config_config.yaml`) and creates files for each step depicted in the workflow. Some files might be temporary files and disapear from one step to the next if their keeping is not judged necessary.

### Warning !!

The flexible allocated memory functions in the `snakefile.snk` was only tested using a maximum of 10 threads and files no bigger than 20G (false 15X). If you use different thread or input file size parameters, please beware as the cluster out of memory handler might cancel your jobs.

## How to run the script ?

1. First, you need to change the paths in the places that are indicated before in this file.
1. Second, you can place yourself in this terminal and type:
```
sbatch launcher.sh
```
