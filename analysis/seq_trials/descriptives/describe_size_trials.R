################################################################################
#
# Size sequential trials
# Number of patients in each trial in each period
# 
# The output of this script is:
# csv file ./output/seq_trials/descriptives/data_flow_seq_trials_*.csv
# where * is monthly, bimonthly or weekly (_red for redacted file)
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
library(optparse)
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
if(length(args)==0){
  # use for interactive testing
  period <- "month"
  period_colname <- paste0("period_", period)
} else {
  
  option_list <- list(
    make_option("--period", type = "character", default = "month",
                help = "Subsets of data used, options are 'month', '2month', '3month' and 'week' [default %default]. ",
                metavar = "period")
  )
  
  opt_parser <- OptionParser(usage = "prepare_data:[version] [options]", option_list = option_list)
  opt <- parse_args(opt_parser)
  
  period <- opt$period
  period_colname <- paste0("period_", period)
}
study_dates <-
  jsonlite::read_json(path = here::here("lib", "design", "study-dates.json")) %>%
  map(as.Date)

################################################################################
# 0.3 Import data
################################################################################
data <- 
  read_rds(here("output", "data", "data_processed_excl_contraindicated.rds")) %>%
  mutate(period = .data[[period_colname]])
file_name <- paste0("data_seq_trials_", period, "ly.feather")
trials <- arrow::read_feather(here::here("output", "data", file_name))

################################################################################
# 1.0 Sense check size of trials based on data
################################################################################
sense_check_size_trials <-
  data %>%
  group_by(period) %>%
  summarise(n_total = n(),
            n_pax = sum(treatment_strategy_cat_prim == "Paxlovid"),
            n_sotmol = sum(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir")),
            n_notrt = sum(treatment_strategy_cat_prim == "Untreated"),
            n_sotmol0 = sum(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 0),
            n_sotmol1 = sum(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 1),
            n_sotmol2 = sum(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 2),
            n_sotmol3 = sum(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 3),
            n_sotmol4 = sum(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 4),
            n_event0 = sum(status_primary == "covid_hosp_death" & fu_primary == 0), # should be 0
            n_event1 = sum(status_primary == "covid_hosp_death" & fu_primary == 1 & !(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 0)),
            n_event2 = sum(status_primary == "covid_hosp_death" & fu_primary == 2 & !(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 1)),
            n_event3 = sum(status_primary == "covid_hosp_death" & fu_primary == 3 & !(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 2)),
            n_event4 = sum(status_primary == "covid_hosp_death" & fu_primary == 4 & !(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 3)),
            n_event5 = sum(status_primary == "covid_hosp_death" & fu_primary == 5 & !(treatment_strategy_cat_prim %in% c("Sotrovimab", "Molnupiravir") & tb_postest_treat == 4)), # 5 as in fifth trial (=trial 4) people experiencing outcome at end of interval are excluded
            n_censor0 = sum(status_primary != "covid_hosp_death" & fu_primary == 0),
            n_censor1 =  sum(status_primary!= "covid_hosp_death" & fu_primary == 1),
            n_censor2 =  sum(status_primary != "covid_hosp_death" & fu_primary == 2),
            n_censor3 = sum(status_primary != "covid_hosp_death" & fu_primary == 3),
            n_censor4 = sum(status_primary != "covid_hosp_death" & fu_primary == 4),
            )

################################################################################
# 2.0 Number of unique patients included in each arm of trials
################################################################################
size_trials <-
  trials %>%
  group_by(period, trial, arm) %>%
  summarise(n = length(unique(patient_id)), .groups = "keep") %>%
  mutate(period = as.integer(period)) %>%
  pivot_wider(
    names_from = arm,
    values_from = n, 
    names_prefix = "n_") %>%
  relocate(n_1, .before = n_0) %>%
  mutate(across(c("n_0", "n_1"), .f = ~ if_else(is.na(.x), 0L, .x))) %>%
  rename(treated_baseline = n_1, untreated_baseline = n_0)

################################################################################
# 3.0 Number of patients in untrt arm initiating treatment
################################################################################
n_init_trt_untrt_given_trial_period <- function(trials, period_no, trial_no){
  n_init_trt <- function(trials, period_no, trial_no, column_name){
    trials %>%
      group_by(patient_id) %>%
      filter(period == {{ period_no }} & trial == {{ trial_no }} &
               arm == 0 & 
               any(.data[[column_name]] == 1)) %>%
      pull(patient_id) %>% unique() %>% length() %>%
      as_tibble() %>%
      transmute(period = period_no, 
                trial = trial_no, 
                {{ column_name }} := value)
  }
  n_init_trt(trials, period_no, trial_no, "treatment_seq") %>%
    left_join(n_init_trt(trials, period_no, trial_no, "treatment_seq_sotmol"),
              by = c("period", "trial"))

}
n_init_trt_untrt_all_trials <- function(trials, period_no){
  map_dfr(.x = 0L:4L,
          .f = ~ n_init_trt_untrt_given_trial_period(trials, period_no, .x))
}
cuts <- trials %>% pull(period) %>% unique() %>% sort() %>% as.integer()
n_init_trt_in_untrt_arm <- 
  map_dfr(.x = cuts,
          .f = ~ n_init_trt_untrt_all_trials(trials, .x))

################################################################################
# 4.0 Join two tables from step 1 and 2
################################################################################
data_flow <-
  size_trials %>%
  left_join(n_init_trt_in_untrt_arm,
            by = c("period", "trial"))
data_flow_red <-
  data_flow %>%
  mutate(
    across(starts_with("treat") | "untreated_baseline",
           ~ if_else(.x > 0 & .x <= redaction_threshold, 
                     "[REDACTED]", 
                     .x %>% plyr::round_any(rounding_threshold) %>% as.character()))
  )

################################################################################
# 5.0 Save output
################################################################################
write_csv(sense_check_size_trials,
          fs::path(output_dir, "sense_check_for_data_flow.csv"))
file_name <- paste0("data_flow_seq_trials_", period, "ly.csv")
file_name_red <- paste0("data_flow_seq_trials_", period, "ly_red.csv")
write_csv(data_flow,
          fs::path(output_dir, file_name))
write_csv(data_flow_red,
          fs::path(output_dir, file_name_red))
