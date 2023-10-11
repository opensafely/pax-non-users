################################################################################
#
# PER PROTOCOL ANALYSIS
# 
# 
# The output of this script is:
# csv file ./output/seq_trials/pp/data_flow_seq_trials_*.csv
# where * is monthly or weekly (_red for redacted file)
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(magrittr)
library(dplyr)
library(tidyr)
library(fs)
library(here)
library(purrr)
library(splines)
library(broom)
library(sandwich)
library(lmtest)
library(data.table)
library(optparse)
library(tictoc)
source(here::here("lib", "design", "covars_seq_trials.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "pp")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  model <- "simple"
} else {
  
  option_list <- list(
    make_option("--model", type = "character", default = "simple",
                help = "Outcome model fitted. Choice between simple (main effects arm, period and trial), interaction_period (introducing interaction between arm and period), interaction_trial (introducing interaction between arm and trial), interaction_all (introducing interaction between arm and period; arm and trial) [default %simple]. ",
                metavar = "model")
  )
  
  opt_parser <- OptionParser(usage = "prepare_data:[version] [options]", option_list = option_list)
  opt <- parse_args(opt_parser)
  
  model <- opt$model
}

################################################################################
# 0.3 Import data
################################################################################
trials <- arrow::read_feather(here("output", "data", "data_seq_trials_monthly.feather"))
trials %<>%
  mutate(trial = factor(trial, levels = 0:4),
         period = factor(period, levels = 1:12))

################################################################################
# 1.0 IPACW
################################################################################
trials_arm0_treatmentwindow <-
  trials %>%
  filter(arm == 0, tend <=4)  %>%
  group_by(patient_id, trial) %>%
  mutate(treatment_seq_lead1 = lead(treatment_seq, n = 1L, default = 1L), 
         treatment_seq_next_equal_to_arm = if_else(treatment_seq_lead1 == arm, 1L, 0L)) %>%
  ungroup()
fit_num <- glm(treatment_seq_next_equal_to_arm ~ factor(tend),
               family = binomial(link = "logit"),
               data = trials_arm0_treatmentwindow)
formula_denom <- 
  paste0("treatment_seq_next_equal_to_arm ~ ",
         paste0(c("factor(tend) + period + trial", covars), 
                collapse = " + ")) %>%  
  as.formula()
fit_denom <- glm(formula_denom,
                 family = binomial(link = "logit"),
                 data = trials_arm0_treatmentwindow)
trials_arm0_treatmentwindow <-
  trials_arm0_treatmentwindow %>%
  mutate(ipacw_num = predict(fit_num, type = "response", newdata = .),
         ipacw_denom = predict(fit_denom, type = "response", newdata = .)) %>%
  select(patient_id, tstart, tend, trial, ipacw_num, ipacw_denom, treatment_seq_lead1, treatment_seq_next_equal_to_arm)

trials <-
  trials %>%
  left_join(trials_arm0_treatmentwindow,
            by = c("patient_id", "tstart", "tend", "trial")) %>%
  mutate(
    ipacw = case_when(arm == 1 ~ 1,
                      arm == 0 & tend > 4 ~ 1,
                      arm == 0 & tend <= 4 ~ ipacw_num / ipacw_denom)) %>%
  group_by(patient_id, trial) %>%
  mutate(
    ipacw_lag1 = lag(ipacw, n = 1L, default = 1),
    ipacw_cum = cumprod(ipacw_lag1)) %>%
  ungroup()

################################################################################
# 1.0 Outcome model
################################################################################
if (model == "simple"){
  f <- 
    paste0("status_seq ~ ",
           paste0(c("arm + ns(tend, 4) + period + trial", covars),
                  collapse = " + ")) %>%  
    as.formula()
} else if (model == "interaction_period"){
  f <-
    paste0("status_seq ~ ",
           paste0(c("arm + ns(tend, 4) + period + trial + arm:period", covars),
                  collapse = " + ")) %>%  
    as.formula()
} else if (model == "interaction_trial"){
  f <-
    paste0("status_seq ~ ",
           paste0(c("arm + ns(tend, 4) + period + trial + arm:trial", covars),
                  collapse = " + ")) %>%  
    as.formula()
} else if (model == "interaction_all"){
  f <-
    paste0("status_seq ~ ",
           paste0(c("arm + ns(tend, 4) + period + trial + arm:period + arm:trial", covars),
                  collapse = " + ")) %>%  
    as.formula()
}
print("Fit outcome model")
tic()
om_fit <-
  glm(f, 
      family = binomial(link = "logit"),
      data = trials_monthly)
toc()
print("Estimate robust standard errors")
tic()
om_fit_robust <-
  coeftest(om_fit,
           vcovHC)
toc()
print("Tidy output")
tic()
om_fit_robust_tidy <- 
  om_fit_robust %>%
  tidy(conf.int = TRUE) %>%
  mutate(OR = exp(estimate),
         OR_lci = exp(conf.low),
         OR_hci = exp(conf.high))
toc()

################################################################################
# 2.0 Save output
################################################################################
print("Write output")
tic()
saveRDS(
  om_fit,
  fs::path(output_dir, paste0("itt_fit_", model, ".rds"))
)
data.table::fwrite(
  om_fit_robust_tidy,
  fs::path(output_dir, paste0("itt_fit_", model, ".csv"))
)
toc()
