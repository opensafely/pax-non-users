################################################################################
#
# INTENTION TO TREAT ANALYSIS
# 
# 
# The output of this script is:
# csv file ./output/seq_trials/itt/data_flow_seq_trials_*.csv
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
library(splines)
library(broom)
source(here::here("lib", "design", "covars_seq_trials.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "itt")
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
#trials_weekly <- arrow::read_feather(here("output", "data", "data_seq_trials_weekly.feather"))

################################################################################
# 1.0 Outcome model
################################################################################
f_simple <- 
  paste0("status_seq ~ ",
         paste0(c("treatment_seq_baseline + ns(tend, 4) + period_month + trial", covars),
                collapse = " + ")) %>%  
  as.formula()  
f_interaction_period <- 
  paste0("status_seq ~ ",
         paste0(c("treatment_seq_baseline + ns(tend, 4) + period_month + trial + treatment_seq * period_month", covars),
                collapse = " + ")) %>%  
  as.formula()  
f_interaction_trial <- 
  paste0("status_seq ~ ",
         paste0(c("treatment_seq_baseline + ns(tend, 4) + period_month + trial + treatment_seq * trial", covars),
                collapse = " + ")) %>%  
  as.formula()
f_interaction_all <- 
  paste0("status_seq ~ ",
         paste0(c("treatment_seq_baseline + ns(tend, 4) + period_month + trial + treatment_seq * period_month + treatment_seq * trial", covars),
                collapse = " + ")) %>%  
  as.formula()
formulas <-
  list(f_simple,
       f_interaction_period,
       f_interaction_trial,
       f_interaction_all)
om_fit <-
  map(.x = formulas,
      .f = ~ glm(.x, 
                 family = binomial(link = "logit"),
                 data = trials_monthly))
names(om_fit) <- c("simple", "interaction_period", "interaction_trial", "interaction_all") 
om_fit_tidy <-
  map(.x = om_fit,
      .f = ~ .x %>% tidy())

################################################################################
# 2.0 Save output
################################################################################
iwalk(.x = om_fit,
      .f = ~ saveRDS(
        .x,
        path(output_dir, paste0("itt_fit_", .y, ".rds"))
      ))
iwalk(.x = om_fit_tidy,
      .f = ~ write_csv(
        .x,
        path(output_dir, paste0("itt_fit_", .y, ".csv"))
      ))
