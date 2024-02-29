# Import libraries
require("tidyverse")
require("ggpubr")
library(tidyverse)
library(ggpubr)
require("argparse")
library(argparse)


# Take inputs from the snakemake program
parser <- ArgumentParser(description = "This program is used to create a table of sites to keep on the filtration on Strand Bias")

# Add the arguments that are used
parser$add_argument("--input", "-i", help= "The input folder (where to find the folders containing all the stats outputs)")
parser$add_argument("--output", "-o", help= "The path and name to give to the output file. A png extension will be added")

xargs <- parser$parse_args()

input_path <- xargs$input
output_path <- xargs$output

##################################### Importing data  ##################################
# Looking at the alternative allele frequency (AF)
AF <- read.table(
    paste0(input_path, "Stats/vcfstats.AF.txt"),
    col.names = c("CHROM", "POS", "AF")
) %>%
    mutate(AF = AF %>% as.numeric)

# Looking at the total depth per site (DP)
DP <- read.table(
    paste0(input_path, "Stats/vcfstats.DP.txt"),
    header=TRUE
) %>%
    mutate(DP = MEAN_DEPTH %>% as.numeric) %>%
    select(-MEAN_DEPTH)

# Looking at the Phred-scaled variant quality score (QUAL)
QUAL <- read.table(
    paste0(input_path, "Stats/vcfstats.QUAL.txt"),
    col.names = c("CHROM", "POS", "QUAL")
) %>%
    mutate(QUAL = QUAL %>% as.numeric)

# Looking at the strand bias (SP)
SP <- read.table(
    paste0(input_path, "Stats/vcfstats.SP.txt"),
    col.names = c("CHROM", "POS", "SP")
) %>%
    mutate(SP = SP %>% as.numeric)

# Looking at the missing data (MISS)
MISS <- read.table(
    paste0(input_path, "Stats/vcfstats.lmiss"),
    sep = "\t",
    header = TRUE
) %>%
    mutate(N_MISS = N_MISS %>% as.numeric)

##################################### Plot the graphs  ##################################
AFg <- AF %>% 
  ggplot(aes(AF)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Frequency of alternative allele (AF)",
       y = "Density")

DPg <- DP %>% 
  ggplot(aes(DP)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Mean read depth per site (DP)",
       y = "Density")

QUALg <- QUAL %>% 
  ggplot(aes(QUAL)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Phred scaled variant quality score (QUAL)",
       y = "Density")

SPg <- SP %>% 
  ggplot(aes(SP)) +
  geom_density(color="red") +
  theme_classic() +
  labs(x = "Phred-scaled probability of strand bias (SP)",
       y = "Density")

MISSg <- MISS %>% 
    ggplot(aes(N_MISS)) +
    geom_density(color="red") +
    theme_classic() +
    labs(x = "Missing data (MISS)",
         y = "Density")

plot_raw <- ggarrange(AFg, DPg, QUALg, SPg, MISSg,
          ncol=2, nrow=3)
plot_raw <- annotate_figure(plot_raw, top=text_grob("Quality check on raw data set", face="bold", size=14))


##################################### Save the plot  ##################################
ggsave(plot=plot_raw, paste0(output_path, ".png"), height=20, width=20)
