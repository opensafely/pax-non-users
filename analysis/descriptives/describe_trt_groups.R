################################################################################
#
# Treatment groups
# 
# The output of this script is:
# csv file ./output/descriptives/trt_groups(_red).csv
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
source(here::here("lib", "design", "redaction.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 0.3 Import data
################################################################################
data <- read_rds(here("output", "data", "data_processed_excl_contraindicated.rds"))


################################################################################
# 1.0 Proportion treated in 12 periods
################################################################################
total_n <- nrow(data)
# Proportion treated
trt_groups <- 
  data %>%
  group_by(treatment_strategy_cat_prim) %>%
  summarise(n = n()) %>%
  add_row(treatment_strategy_cat_prim = "Total", n = total_n)
trt_groups_red <-
  trt_groups %>%
  mutate(n = if_else(n > 0 & n <= redaction_threshold, "[REDACTED]", n %>% plyr::round_any(rounding_threshold) %>% as.character()))

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = trt_groups,
          path(output_dir, "trt_groups.csv"))
write_csv(x = trt_groups_red,
          path(output_dir, "trt_groups_red.csv"))
