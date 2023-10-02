################################################################################
#
# Select data to optimise code speed (not having script rely on data_process)
# 
# The output of this script is:
# feather file ./output/data/data_processed_excl_contraindicated.feather
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(here)
library(arrow)

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "data")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import data
################################################################################
file_name <- "data_processed_excl_contraindicated"
data <- 
  read_rds(here("output", "data", paste0(file_name, ".rds"))) 

################################################################################
# 2.0 Save output
################################################################################.
write_feather(data, fs::path(output_dir, paste0(file_name, ".feather")))
