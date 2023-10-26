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
source(here::here("analysis", "seq_trials", "functions", "add_ipacw.R"))

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

################################################################################
# 1.0 IPACW
trials_ipacw_added <-
  add_ipacw(trials = trials, covars = covars)

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
