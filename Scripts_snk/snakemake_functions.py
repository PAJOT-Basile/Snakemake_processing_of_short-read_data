# Description: This script contains functions that are loaded when the snakemake is initiated
# Modules required: numpy
# Date: 23 September 2024
# Author: Basile Pajot
#########################################################################################################################
#
# # Libraries
import os
import numpy as np

########################  Functions   ###############################
# Make a function that indexes the reference genome


def index_ref_genome(input_reference_genome, reference_genome, conda_environment):
    """
    This function indexes the reference genome to be used later in the workflow if it is not already done

    Parameters:
    ------------------------------------
    input_reference_genome: str
        This is the path to the input reference genome, whether it has been indexed already or not.
        It is the absolute path to the genome in fa format.

    reference_genome: str
        This is the path to the output reference genome that will be used for our analysis.

    Returns:
    ------------------------------------
    None: This function copies and/or indexes the genome so outputs are visible in the arborescence, but not in the console.
    """
    print("Indexing reference genome")
    # The output path is the place where the reference genome will be saved. To get it, we use the reference_genome
    # argument and just remove the last part of the name
    output_path = "/".join(reference_genome.split("/")[:-1]) + "/"

    # We use the function to get the reference genome name
    genome_name = input_reference_genome.split("/")[-1]

    # If the file with the ".amb" extension is not present in the same location as the reference genome,
    # it has not been indexed yet, so we will do it
    if not os.path.isfile(output_path + genome_name + ".amb"):
        os.popen(
            f"""
                # If the folder where you need to place the reference genome is not yet create,
                # we create the folder
                mkdir -p {output_path}

                # Here, we first check if the reference genome has already been indexed in the location where the
                # reference genome is. If it has been indexed, we simply copy all the output files of the indexation,
                # but if it has not yet been done, we copy the reference genome and index it
                if [ ! -f "{reference_genome}.amb" ] || [ ! -f "{reference_genome}.fai" ]; then
                    cp {input_reference_genome}* {output_path}
                    # Here, we check if the reference genome has already been indexed in the storage location
                    if [ ! -f "{input_reference_genome}.amb" ]; then
                        # If it has, we simply copy the files
                        conda run -p {conda_environment} --live-stream bwa index {output_path}{genome_name}
                        bwa index {output_path}{genome_name}
                        echo "toto"
                    fi
                    if [ ! -f "{input_reference_genome}.fai" ]; then
                        # If it has, we simply copy the files
                        conda run -p {conda_environment} --live-stream samtools faidx {output_path}{genome_name}
                        samtools faidx {output_path}{genome_name}
                        echo "titou"
                    fi
                fi
            """
        )
        os.wait()


######################## Cut chromosomes  ###############################
# Make a function to separate the chromosomes into breaks of a chosen length


def get_chromosome_positions_breaks(path, bin_size=1e6):
    """
    This function is used to cut every chromosome in the reference file index and separates it into bins of chosen width

    Parameters
    -----------------------------------
    path: str
        This is the path to the reference genome file (the fasta file). It requires that we have run the
        indexation of the reference genome beforehand.

    bin_size: int (default=1e6)
        This is the size of the bins to use to cut the chromosomes in samples of this length
        This parameter is optional and the default value is of 1e6


    Returns
    -------------------------------------
    list_positions: list of strings
    The returned values are the names of the chromosome and the bins in said chromosomes. For
    example, for a chromosome of size 2e6, it returns the following list: ['Chrom_name:1e6', 'Chrom_name:2e6']
    """
    # First convert the bin size into a number
    bin_size = float(bin_size)

    # Initialise the list to add all the lines from the annotated reference genome file
    data = []
    with open(path + ".ann", "r") as line:
        data = line.readlines()

    # We remove the first line of the file given it does not provide any useful information here
    data.pop(0)

    # We separate the lines containing the length of the chromosomes (odd lines) from the names of the
    # chromosomes (pair lines)
    data_pair = [0] * int(len(data)/2)
    data_odd = [0] * int(len(data)/2)
    for count, i in enumerate(data):
        if count % 2 != 0:
            data_odd[int(count/2)] = i.strip("\n")
        else:
            data_pair[int(count/2)] = i.strip("\n")

    # We extract the lengths of the chromosomes from the odd lines
    lengths = []
    for count, i in enumerate(data_odd):
        lengths.append(i.split(" ")[1])
    # We transform the lengths list into a list of integers to use as numbers
    lengths = list(map(int, lengths))

    # We extract the names of the chromosomes from the even lines
    names = []
    for count, i in enumerate(data_pair):
        names.append(i.split(" ")[1])

    # We concatenate the two lists into a dictionnary
    concat_dict = dict(map(lambda i, j: (i, j), names, lengths))

    # We make a list of the names of the chromosomes with positions added to it
    list_postions = []
    # On itère sur les noms de chromosomes et le longueurs de chromosomes
    for key, value in concat_dict.items():
        # If the chromosome is longer than the chosen bin width, we cut it into the required number of bins using
        # the bin width we want to use
        if value > bin_size:
            positions = np.arange(start=0, stop=value, step=bin_size)
            # Once the chromosome is cut into different samples, we iterate over the samples to add them to the
            # list of positions
            for count, i in enumerate(positions):
                # For the last sample, if the number of nucleotides is bigger than the length of the chromosome,
                # we add the remaining number of values
                if count == len(positions)-1:
                    list_postions.append(
                        key + ":" + str(int(i)+1) + "-" + str(int(value)))
                else:
                    list_postions.append(
                        key + ":" + str(int(i)+1) + "-" + str(int(positions[count+1])))
        else:
            list_postions.append(key + ":1-" + str(int(value)))

    return (list_postions)

######################## Define inputs  ###############################


def input_fastqc(step, raw_data_path, outputs_files):
    """
    This function is used to give different inputs for the fastqc step (if it is on the raw data or on the fastp data).

    Parameters:
    ------------------------------------
    step: str
        This is a short string ("Raw" or "Fastp") to know at what moment of the analysis we are. If the fastp
        analysis was not completed yet, it will have the "Raw" value and the fastqc analysis will be run on 
        the raw data. If the fastp analysis is complete, step will take the value "Fastp" and the fastqc analysis
        will be run on the fastp data.

    raw_data_path: str
        This is the path to the raw data of the analysis.

    outputs_files: str
        This is the path to the data where the outputs are kept, including the Fastp output to use as input
        in the fastqc analysis.

    Returns:
    ------------------------------------
    Path (str): This is the path to use as input for the fastqc analysis, whether it is on the raw data or after
    the fastp trimming process.
    """
    if step == "1_Raw":
        return (raw_data_path)
    elif step == "2_Fastp":
        return (outputs_files + "01_Fastp/")


def input_stats(step, outputs_files, final_output):
    """
    This function is used to give different inputs for counting snps on the successfully filtered vcfs.

    Parameters:
    ------------------------------------
    step: str
        This is a short string (one of "Full_VCF", "Mac_data", "Removed_indels" or "Missing_data") to know at what 
        moment of the analysis we are. It will change with different vcf filtration steps.

    outputs_files: str
        This is the path to where the outputs are kept, including the temporary outputs that are used as input
        for several steps of the filtration process of vcfs

    final_output: str
        This is the path to where the permanent outputs are kept, including the Full VCF file that is used to do the filtration steps

    Returns:
    ------------------------------------
    Path (str): This is the path to use as input for the snp count.
    """
    if step == "1_Full_VCF":
        return (final_output + "08_Full_VCF/")

######################## Fast functions  ###############################


def this_step(step):
    """
    This function is done to simplify the printing of the steps we are on for
    rules that are used several times.

    Parameters:
    ------------------------------------
    step: str
        This is a short string (one of "Full_VCF", "Mac_data", "Removed_indels" or "Missing_data") to know at what 
        moment of the analysis we are. It will change with different vcf filtration steps.

    Returns
    ------------------------------------
    : str
        Short string to print in the messages and the names of the rules
    """
    return (step.split('_')[1])


def flatten(list_to_flatten):
    """
    This function is done to unlist nested lists

    Parameters:
    ------------------------------------
    list_to_flatten: list
        This is a list that contains lists (nested list)

    Returns:
    ------------------------------------
    : list
        List that contains all that was contained in the nested lists, but in an un-nested list
    """
    return [item for sublist in list_to_flatten for item in sublist]
