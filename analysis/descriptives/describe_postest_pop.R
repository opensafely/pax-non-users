################################################################################
#
# Positive tested population over time (periods of 12 months)
# 
# The output of this script is:
# csv file ./output/descriptives/postest_pop(_red).csv
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
source(here::here("lib", "design", "covars_table.R"))
source(here::here("lib", "design", "redaction.R"))
source(here::here("analysis", "descriptives", "functions", "generate_table1.R"))

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
generate_table1_in_period <- function(data_table, period, pop_levels) {
  data_table <-
    data_table %>%
    filter(period == period) %>%
    select(-period)
  # Generate table - full and stratified populations
  table1 <- generate_table1(data_table, pop_levels)$table1
  table1 <- table1 %>% mutate(period = period)
}
data_table <- 
  data %>%
  select(treatment_strategy_cat_prim, all_of(covars), period)
periods <- 1:12
pop_levels = c("All", "Molnupiravir", "Sotrovimab", "Paxlovid", "Untreated")
# change data if run using dummy data
if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")){
  periods = 1 # in dummy data, everyone has pos test on same day (start of study period)
}
table1_periods <- map_dfr(
  .x = periods,
  .f = ~ generate_table1_in_period(data_table, .x, pop_levels)
)
table1_periods_red <-
  table1_periods %>% 
  mutate(across(all_of(pop_levels),
                ~ if_else(.x > 0 & .x <= redaction_threshold, 
                          "[REDACTED]",  
                           .x %>% plyr::round_any(rounding_threshold) %>% as.character())))

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = table1_periods,
          path(output_dir, "postest_pop.csv"))
write_csv(x = table1_periods_red,
          path(output_dir, "postest_pop_red.csv"))
