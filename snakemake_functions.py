# Libraries
import os
import pandas as pd
import numpy as np

########################  Functions   ###############################
######################## Get sample names  ###############################
def list_samples(directory, patterns_in="None", patterns_out="None"):
    """
    This function returns all the unique sample names in the given directory

    Parameters
    ---------------------------
    directory: str
        This argument is the name of the directory to extract the names of the samples from
    
    patterns_in: list
        This list gives some filtering information on the files to use
    
    patterns_out: list 
        This list gives the patterns to not get in the files to use if any
    
    Returns
    ---------------------------
    SAMPLES: list
    The returned value is the list of all the samples extracted from the input directory
    """

    # Shows which patterns are to keep and which are to remove from the list of samples
    print(f"Patterns to keep in the filenames: {patterns_in}")
    print(f"Patterns to filter out in the filenames: {patterns_out}")

    # We make a list of the files in the raw data folder
    list_raw_data = pd.Series(os.listdir(directory))

    # We want to select all single occurences of the files in the input directory. Therefore, we add "R1" to the list of patterns to
    # consider to only take these files
    if patterns_in != "None":
        patterns_in.append("R1")
    else:
        patterns_in = ["R1"]
    
    # We make a list of all the single occurences of files that contain the patterns in the "patterns_in" list
    list_of_samples = list_raw_data[list_raw_data.apply(lambda filter: all(word in filter for word in patterns_in))].sort_values()

    # If the list "patterns_out" is not empty, we filter the list of file names ("list_of_samples") to remove those that contain the
    # patterns contained in "patterns_out"
    if patterns_out != "None":
        list_of_samples = list_of_samples[list_of_samples.apply(lambda filter: all(word not in filter for word in patterns_out))].sort_values()        
    
    # We then remove the end part of the file name (the extension) to only keep the sample name
    list_of_samples = list(list_of_samples.str.replace(".R1.fastq.gz", ""))
    return(list_of_samples)


######################## Name of the reference genome  ###############################
def get_reference_genome_name(ref_path):
    """
    This function returns the name of the reference genome according to the specified path to said genome

    Parameters:
    -----------------------------------
    ref_path: str
        The path to the reference genome
    
    Returns:
    ------------------------------------
    name_genome: str
    The name of the reference genome
    """
    # We take the path to the reference file and only take the last part (after the last "/")
    name_genome = ref_path.split("/")[-1]
    return(name_genome)

# Make a function that indexes the reference genome
def index_ref_genome(input_reference_genome, reference_genome):
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
    # The output path is the place where the reference genome will be saved. To get it, we use the reference_genome 
    # argument and just remove the last part of the name
    output_path = "/".join(reference_genome.split("/")[:-1]) + "/"

    # We use the function to get the reference genome name
    GENOME_NAME = get_reference_genome_name(input_reference_genome)

    # If the file with the ".amb" extension is not present in the same location as the reference genome, 
    # it has not been indexed yet, so we will do it
    if not os.path.isfile(output_path + GENOME_NAME + ".amb"):
        print(f"Indexing reference genome: {GENOME_NAME}")
    os.popen(
        f"""
            # If the folder where you need to place the reference genome is not yet create, 
            # we create the folder
            mkdir -p {output_path}

            # Here, we first check if the reference genome has already been indexed in the location where the 
            # reference genome is. If it has been indexed, we simply copy all the output files of the indexation,
            # but if it has not yet been done, we copy the reference genome and index it
            if [ ! -f "{output_path + get_reference_genome_name(input_reference_genome)}" ]; then
                # Here, we check if the reference genome has already been indexed in the storage location
                if [ -f "{input_reference_genome}.amb" ]; then
                    # If it has, we simply copy the files
                    cp {input_reference_genome}* {output_path}
                else
                    # If it has not, we copy the reference genome and index it
                    cp {input_reference_genome} {output_path}
                    bwa index {output_path}
                fi
            fi
        """
    )

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
    concat_dict = dict(map(lambda i,j: (i, j), names, lengths))

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
                    list_postions.append(key + ":" + str(int(i)+1) + "-" + str(int(value)))
                else:
                    list_postions.append(key + ":" + str(int(i)+1) + "-" + str(int(positions[count+1])))
        else:
            list_postions.append(key + ":1-" + str(int(value)))
    
    return(list_postions)
