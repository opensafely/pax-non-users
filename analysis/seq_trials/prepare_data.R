################################################################################
#
# Data wrangling seq trials
# 
# The output of this script is:
# csv file ./output/data/data_seq_trial.rds
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
source(here::here("analysis", "seq_trials", "functions", "simplify_data.R"))
source(here::here("analysis", "seq_trials", "functions", "survsplit_data.R"))
source(here::here("analysis", "seq_trials", "functions", "add_period_cuts.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "data")
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
data <- read_rds(here("output", "data", "data_processed_excl_contraindicated.rds"))

################################################################################
# 0.4 Data manipulation
################################################################################
data_splitted <-
  data %>%
  simplify_data()
data_splitted$fup_seq %>% table() %>% print()
data_splitted %>% filter(fup_seq == 0) %>% select(status_seq) %>% print() #debugging

data_splitted <-
  data %>%
  simplify_data() %>%
  survsplit_data() %>%
  add_period_cuts(study_dates = study_dates)
# make dummy data better
if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")){
  data_splitted <-
    data_splitted %>%
    group_by(patient_id) %>%
    mutate(period_month = runif(1, 0, 12) %>% ceiling(),
           period_week = runif(1, 0, 52) %>% ceiling()) %>%
    ungroup()
  # in dummy data, everyone has pos test on same day (start of study period)
  data_splitted <-
    data_splitted %>%
    select(patient_id, tstart, tend, period_month, period_week, status_seq, starts_with("treatment_seq"))
}

################################################################################
# 1.0 Construct trials (monthly and weekly)
################################################################################
construct_seq_trials_in_given_period <- function(data_period, treat_window){
  trial_seq <- 0:(treat_window - 1)
  construct_trial_no <- function(data_period, trial_no){
    trial <-
      data_period %>%
      filter(tstart >= trial_no) %>%
      mutate(trial = trial_no) %>%
      group_by(patient_id) %>%
      mutate(rownum = row_number(),
             treatment_seq_baseline = first(treatment_seq),
             treatment_seq_lag1_baseline = first(treatment_seq_lag1),
             tstart = tstart - trial_no,
             tend = tend - trial_no) %>%
      filter(treatment_seq_lag1_baseline == 0) %>% #restrict to those not previously treated at the start of the trial
      filter(first(status_seq) == 0,
             first(treatment_seq_sotmol) == 0) %>% # restrict to those not experiencing an outcome in first interval of trial &
      # restrict to those not treated with sot/mol in the first interval
      # note that individuals censored (dereg/non covid death) in a given interval, are not filtered out; we just want to make sure no-one
      # experiences the outcome (covid_hosp_death) in the first interval
      ungroup()
  }
  trials <-
    map_dfr(.x = trial_seq,
            .f = ~ construct_trial_no(data_period, .x))
}
trials_monthly <-
  map_dfr(
    .x = 1:12,
    .f = ~
      construct_seq_trials_in_given_period(
        data_splitted %>% filter(period_month == .x),
        5)
    )
trials_weekly <-
  map_dfr(
    .x = 1:52,
    .f = ~
      construct_seq_trials_in_given_period(
        data_splitted %>% filter(period_week == .x),
        5)
    )

################################################################################
# 2.0 Save output
################################################################################.
iwalk(.x = list(trials_monthly = trials_monthly,
                trials_weekly = trials_weekly),
      .f = ~
        arrow::write_feather(
          .x,
          fs::path(output_dir,
                   paste0("data_seq_", .y, ".feather"))
        ))
