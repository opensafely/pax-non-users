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
data_table_full <- 
  data %>%
  select(treatment_strategy_cat_prim, all_of(covars))
data_table <-
  data_table_full %>%
  filter(treatment_strategy_cat_prim %in% c("Paxlovid", "Untreated"))
data_table_trt_untrt <- 
  data %>%
  select(treatment_strategy_cat_prim, all_of(covars)) %>%
  mutate(treatment_strategy_cat_prim =
           if_else(treatment_strategy_cat_prim == "Paxlovid", "Paxlovid", "Not treated with Paxlovid"))
# Generate full and stratified table
# exclude mol/sot treated
pop_levels <- c("All", "Paxlovid", "Untreated")
table1 <- generate_table1(data_table, pop_levels)
# all levels
pop_levels_full <- c("All", "Paxlovid", "Sotrovimab", "Molnupiravir", "Untreated")
table1_full <- generate_table1(data_table_full, pop_levels_full)
# paxlovid / paxlovid untreated
pop_levels_trt_untrt = c("All", "Paxlovid", "Not treated with Paxlovid")
# Generate table - full and stratified populations
table1_trt_untrt <- generate_table1(data_table_trt_untrt, pop_levels_trt_untrt)

################################################################################
# 2 Save table
################################################################################
write_csv(table1$table1,
          fs::path(output_dir, "table1.csv"))
write_csv(table1$table1_red,
          fs::path(output_dir, "table1_red.csv"))
write_csv(table1$table1_red_unf,
          fs::path(output_dir, "table1_red_unf.csv"))
write_csv(table1_full$table1,
          fs::path(output_dir, "table1_full.csv"))
write_csv(table1_full$table1_red,
          fs::path(output_dir, "table1_full_red.csv"))
write_csv(table1_full$table1_red_unf,
          fs::path(output_dir, "table1_full_red_unf.csv"))
write_csv(table1_trt_untrt$table1,
          fs::path(output_dir, "table1_trt_untrt.csv"))
write_csv(table1_trt_untrt$table1_red,
          fs::path(output_dir, "table1_trt_untrt_red.csv"))
write_csv(table1_trt_untrt$table1_red_unf,
          fs::path(output_dir, "table1_trt_untrt_red_unf.csv"))
