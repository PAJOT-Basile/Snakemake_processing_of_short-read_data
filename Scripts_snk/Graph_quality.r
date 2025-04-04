# Description: This script takes a path to input tables and outputs a quality plot of a VCF file
# Usage: Rscript Graph_quality.r -i input_path -o output_path
# Input: input_path = path to a directory that contains the quality tables of the VCF file 
# Output: output_path = path and name of the output graph
# Modules required: pacman, tidyverse, ggpubr, argparse
# Date: 29 September 2024
# Author: Basile Pajot
#########################################################################################################################
# Add a miror to download the libraries if needed
utils::setRepositories(ind = 0, addURLs = c(CRAN = "https://cran.irsn.fr/"))
# Install libraries if needed and load them
libraries <- c("tidyverse", "ggpubr", "argparse")
if (!require("pacman")) install.packages("pacman")
for (lib in libraries){
  pacman::p_load(lib, character.only = TRUE)
}

# Take inputs from the snakemake program
parser <- ArgumentParser(description = "This program is used to create a table of sites to keep on the filtration on Strand Bias")

# Add the arguments that are used
parser$add_argument("--input", "-i", help = "The input folder (where to find the folders containing all the stats outputs)")
parser$add_argument("--output", "-o", help = "The path and name to give to the output file. A png extension will be added")

xargs <- parser$parse_args()

input_path <- xargs$input
output_path <- xargs$output

##################################### Importing data  ##################################
print("Importing data:")
# Looking at the alternative allele frequency (AF)
AF <- read.table(
    paste0(input_path, "/vcfstats.AF.txt"),
    col.names = c("CHROM", "POS", "AF")
) %>%
    mutate(AF = AF %>% as.numeric)

print("    - Done loading alternative allele frequency")

# Looking at the total depth per site (DP)
DP <- read.table(
    paste0(input_path, "/vcfstats.DP.txt"),
    header=TRUE
) %>%
    mutate(DP = MEAN_DEPTH %>% as.numeric) %>%
    select(-MEAN_DEPTH)

print("    - Done loading depth per site")

# Looking at the Phred-scaled variant quality score (QUAL)
QUAL <- read.table(
    paste0(input_path, "/vcfstats.QUAL.txt"),
    col.names = c("CHROM", "POS", "QUAL")
) %>%
    mutate(QUAL = QUAL %>% as.numeric)

print("    - Done loading Phred-scaled variant quality score")

# Looking at the strand bias (SP)
SP <- read.table(
    paste0(input_path, "/vcfstats.SP.txt"),
    col.names = c("CHROM", "POS", "SP")
) %>%
    mutate(SP = SP %>% as.numeric)

print("    - Done loading strand bias")

# Looking at the missing data (MISS)
MISS <- read.table(
    paste0(input_path, "/vcfstats.lmiss"),
    sep = "\t",
    header = TRUE
) %>%
    mutate(N_MISS = N_MISS %>% as.numeric)

print("    - Done loading missing data")

##################################### Plot the graphs  ##################################
print("Plotting:")
AFg <- AF %>% 
  ggplot(aes(AF)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Frequency of alternative allele (AF)",
       y = "Density")
print("    - Done plotting alternative allele frequency")

DPg <- DP %>% 
  ggplot(aes(DP)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Mean read depth per site (DP)",
       y = "Density")
print("    - Done plotting depth per site")

QUALg <- QUAL %>% 
  ggplot(aes(QUAL)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Phred scaled variant quality score (QUAL)",
       y = "Density")
print("    - Done plotting Phred-scaled variant quality score")

SPg <- SP %>% 
  ggplot(aes(SP)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Phred-scaled probability of strand bias (SP)",
       y = "Density")
print("    - Done plotting strand bias")

MISSg <- MISS %>% 
    ggplot(aes(N_MISS)) +
    geom_density(color="red") +
    theme_classic() +
    labs(x = "Missing data (MISS)",
         y = "Density")
print("    - Done plotting missing data")    

plot_raw <- ggarrange(AFg, DPg, QUALg, SPg, MISSg, ncol=2, nrow=3)

print("Done plotting")
##################################### Save the plot  ##################################
ggsave(plot = plot_raw, output_path, height = 20, width = 20)
print("Saved")
