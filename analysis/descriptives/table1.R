################################################################################
#
# Table 1
# 
#
# The output of this script is:
# -./output/tables/table1.csv
#
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library('tidyverse')
library('here')
library('glue')
library('gt')
library('gtsummary')
library('fs')
library('optparse')
# Import custom user functions
source(here::here("lib", "design", "covars_table.R"))
source(here::here("analysis", "descriptives", "functions", "generate_table1.R"))

################################################################################
# 0.1 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 0.2 Create directories for output
################################################################################
output_dir <- here::here("output", "tables")
fs::dir_create(output_dir)

################################################################################
# 0.3 Import data
################################################################################
data <- read_rds(here("output", "data", "data_processed_excl_contraindicated.rds"))

################################################################################
# 1 Make table 1
################################################################################
# Format data
data_table <- 
  data %>%
  select(treatment_strategy_cat_prim, all_of(covars))
# Generate full and stratified table
pop_levels = c("All", "Molnupiravir", "Sotrovimab", "Paxlovid", "Untreated")
# Generate table - full and stratified populations
table1 <- generate_table1(data_table, pop_levels)

################################################################################
# 2 Save table
################################################################################
write_csv(table1$table1,
          fs::path(output_dir, "table1.csv"))
write_csv(table1$table1_red,
          fs::path(output_dir, "table1_red.csv"))
