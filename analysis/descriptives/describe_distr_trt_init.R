################################################################################
#
# Distribution of initiation of Paxlovid
# 
# The output of this script is:
# csv file ./output/descriptives/distr_pax_init(_red).csv
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
data <- read_rds(here("output", "data", "data_processed.rds"))

################################################################################
# 1.0 Distribution trt init
################################################################################
total_n <- nrow(data)
# Distributions
calc_distr_pax_trt <- function(data, contraindicated) {
  if (contraindicated == TRUE){
    data <-
      data %>% filter(contraindicated == TRUE)
  }
  distr_pax_trt <- data %>%
    filter(any_treatment_strategy_cat == "Paxlovid") %>%
    group_by(tb_postest_treat) %>%
    tally() %>%
    mutate(tb_postest_treat = if_else(tb_postest_treat >= 7, "7 or more", tb_postest_treat %>% as.character())) %>%
    group_by(tb_postest_treat) %>%
    summarise(n = sum(n), .groups = "keep") %>%
    mutate(contraindicated = contraindicated)
}
distr_pax_trt <- 
  map_dfr(.x = c(TRUE, FALSE),
          .f = ~ calc_distr_pax_trt(data, .x))
distr_pax_trt_red <- 
  distr_pax_trt %>%
  mutate(n = case_when(n > 0 & n <= redaction_threshold ~ "[REDACTED]",
                       TRUE ~ n %>% 
                         plyr::round_any(rounding_threshold) %>%
                         as.character()))

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = distr_pax_trt,
          path(output_dir, "distr_pax_init.csv"))
write_csv(x = distr_pax_trt_red,
          path(output_dir, "distr_pax_init_red.csv"))
