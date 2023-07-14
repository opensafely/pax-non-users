################################################################################
#
# Proportion treated
# 
# The output of this script is:
# csv file ./output/descriptives/prop_trt(_red).csv
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
study_dates <-
  jsonlite::read_json(path = here::here("lib", "design", "study-dates.json")) %>%
  map(as.Date)

################################################################################
# 0.3 Import data
################################################################################
data <- read_rds(here("output", "data", "data_processed.rds"))

################################################################################
# 0.4 Data manipulation
################################################################################
seq_dates_start_interval <- 
  seq(study_dates$start_date, study_dates$end_date + 1, by = "1 month")
data <-
  data %>%
  mutate(period = cut(covid_test_positive_date, 
                      breaks = seq_dates_start_interval, 
                      include.lowest = TRUE,
                      right = FALSE,
                      labels = 1:12))
  
################################################################################
# 1.0 Proportion treated in 12 periods
################################################################################
total_n <- nrow(data)
# Proportion treated 
calc_prop_trt <- function(data, contraindicated) {
  if (contraindicated == TRUE){
    data <-
      data %>% filter(contraindicated == TRUE)
  }
  prop_trt <- data %>%
    group_by(period, treatment_strategy_cat, .drop = FALSE) %>%
    summarise(n = n(), .groups = "keep") %>%
    group_by(period) %>%
    mutate(n_total = sum(n),
           prop = n / n_total,
           n_rounded = n %>% plyr::round_any(rounding_threshold),
           n_total_rounded = n_total %>% plyr::round_any(rounding_threshold),
           prop_rounded = n_rounded / n_total_rounded,
           contraindicated = contraindicated)
}
redact_prop_trt <- function(prop_trt) {
  prop_trt_red <- 
    prop_trt %>%
    mutate(n_red = if_else(n > 0 & n <= redaction_threshold, "[REDACTED]", n_rounded %>% as.character()),
           n_total_red = if_else(n_total > 0 & n_total <= redaction_threshold, "[REDACTED]", n_total_rounded %>% as.character()),
           prop_red = if_else(n > 0 & n <= redaction_threshold, "[REDACTED]", prop_rounded %>% as.character())
    ) %>%
    select(period, treatment_strategy_cat, n_red, n_total_red, prop_red, contraindicated)
}
prop_trt <- 
  map_dfr(.x = c(TRUE, FALSE),
          .f = ~ calc_prop_trt(data, .x))
prop_trt_red <-
  prop_trt %>% redact_prop_trt()

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = prop_trt,
          path(output_dir, "prop_trt.csv"))
write_csv(x = prop_trt_red,
          path(output_dir, "prop_trt_red.csv"))
