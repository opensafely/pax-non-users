################################################################################
#
# Size sequential trials
# Number of patients in each trial in each period
# 
# The output of this script is:
# csv file ./output/seq_trials/descriptives/data_flow_seq_trials_*.csv
# where * is monthly or weekly (_red for redacted file)
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(tidyr)
library(fs)
library(here)
library(purrr)
source(here::here("lib", "design", "redaction.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "descriptives")
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
trials_monthly <- arrow::read_feather(here("output", "data", "data_seq_trials_monthly.feather"))
trials_weekly <- arrow::read_feather(here("output", "data", "data_seq_trials_weekly.feather"))

################################################################################
# 1.0 Number of unique patients included in each arm of trials
################################################################################
size_trials_monthly <-
  trials_monthly %>%
  group_by(period_month, trial, treatment_seq_baseline) %>%
  summarise(n = length(unique(patient_id)), .groups = "keep") %>%
  mutate(period_month = as.integer(period_month))
size_trials_weekly <-
  trials_weekly %>%
  group_by(period_week, trial, treatment_seq_baseline) %>%
  summarise(n = length(unique(patient_id)), .groups = "keep") %>%
  mutate(period_week = as.integer(period_week))
size_trials <- 
  list(monthly = size_trials_monthly,
       weekly = size_trials_weekly) %>%
  map(.f = ~ .x %>%
        pivot_wider(
          names_from = treatment_seq_baseline,
          values_from = n, 
          names_prefix = "n_") %>%
        relocate(n_1, .before = n_0) %>%
        mutate(across(c("n_0", "n_1"), .f = ~ if_else(is.na(.x), 0L, .x))) %>%
        rename(treated_baseline = n_1, untreated_baseline = n_0)
  )

################################################################################
# 2.0 Number of patients in untrt arm initiating treatment
################################################################################
n_init_trt_untrt_given_trial_period <- function(trials, period_name, period_no, trial_no){
  n_init_trt <- function(trials, period_name, period_no, trial_no, column_name){
    trials <-
      trials %>% mutate(period = .data[[period_name]])
    trials %>%
      group_by(patient_id) %>%
      filter(period == {{ period_no }} & trial == {{ trial_no }} &
               treatment_seq_baseline == 0 & 
               any(.data[[column_name]] == 1)) %>%
      pull(patient_id) %>% unique() %>% length() %>%
      as_tibble() %>%
      transmute({{ period_name }} := period_no, 
                trial = trial_no, 
                {{ column_name }} := value)
  }
  n_init_trt(trials, period_name, period_no, trial_no, "treatment_seq") %>%
    left_join(n_init_trt(trials, period_name, period_no, trial_no, "treatment_seq_sotmol"),
              by = c(all_of(period_name), "trial"))

}
n_init_trt_untrt_all_trials <- function(trials, period_name, period_no){
  map_dfr(.x = 0:4,
          .f = ~ n_init_trt_untrt_given_trial_period(trials, period_name, period_no, .x))
}
n_init_trt_in_untrt_arm_monthly <- 
  map_dfr(.x = 1:12,
          .f = ~ n_init_trt_untrt_all_trials(trials_monthly, "period_month", .x))
n_init_trt_in_untrt_arm_weekly <- 
  map_dfr(.x = 1:52,
          .f = ~ n_init_trt_untrt_all_trials(trials_weekly, "period_week", .x))
n_init_trt_untrt_arm <- 
  list(monthly = n_init_trt_in_untrt_arm_monthly,
       weekly = n_init_trt_in_untrt_arm_weekly)

################################################################################
# 3.0 Join two tables from step 1 and 2
################################################################################
data_flow <-
  map2(.x = size_trials,
       .y = n_init_trt_untrt_arm,
       .f = ~ .x %>% left_join(.y))
redact_data_flow <- function(data_flow){
  data_flow <-
    data_flow %>%
    mutate(
      across(starts_with("treat") | "untreated_baseline",
             ~ if_else(.x > 0 & .x <= redaction_threshold, 
                       "[REDACTED]", 
                       .x %>% plyr::round_any(rounding_threshold) %>% as.character()))
    )
}
data_flow_red <-
  map(.x = data_flow,
      .f = ~ redact_data_flow(.x))

################################################################################
# 4.0 Save output
################################################################################
iwalk(.x = data_flow,
      .f = ~ write_csv(
        .x,
        path(output_dir, paste0("data_flow_seq_trials_", .y, ".csv"))
      ))
iwalk(.x = data_flow_red,
      .f = ~ write_csv(
        .x,
        path(output_dir, paste0("data_flow_seq_trials_", .y, "_red.csv"))
      ))
