################################################################################
#
# INTENTION TO TREAT ANALYSIS
# 
# 
# The output of this script is:
# csv file ./output/seq_trials/itt/itt_fit_*.csv
# where * is simple or interaction_*
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
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
library(parglm)
library(glue)
source(here::here("lib", "design", "formula_outcome_model.R"))
source(here::here("analysis", "seq_trials", "functions", "glance_plr.R"))
source(here::here("analysis", "seq_trials", "functions", "tidy_plr.R"))
source(here::here("analysis", "seq_trials", "functions", "plr_process.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "itt")
fs::dir_create(output_dir)
log_dir <- here::here("output", "seq_trials", "itt", "log")
fs::dir_create(log_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)
if(length(args)==0){
  # use for interactive testing
  model <- "simple"
  period <- "month"
} else {
  
  option_list <- list(
    make_option("--model", type = "character", default = "simple",
                help = "Outcome model fitted. Choice between simple (main effects arm, period and trial), interaction_period (introducing interaction between arm and period), interaction_trial (introducing interaction between arm and trial), interaction_all (introducing interaction between arm and period; arm and trial), crude, crude_period and crude_trial [default %simple]. ",
                metavar = "model"),
    make_option("--period", type = "character", default = "month",
                help = "Subsets of data used, options are 'month', '2month', '3month', 'week' and 'year' [default %default]. ",
                metavar = "period")
  )
  
  opt_parser <- OptionParser(usage = "prepare_data:[version] [options]", option_list = option_list)
  opt <- parse_args(opt_parser)
  
  model <- opt$model
  period <- opt$period
}
## create special log file ----
cat(glue("## script info for the itt analysis, using period: {period}; model: {model} ##"), 
    "  \n", 
    file = fs::path(log_dir, glue("itt_log_{period}_{model}.txt")), append = FALSE)
## function to pass additional log text
logoutput <- function(...){
  cat(..., file = fs::path(log_dir, glue("itt_log_{period}_{model}.txt")), sep = "\n  ", append = TRUE)
}

################################################################################
# 0.3 Import data
################################################################################
file_name <- paste0("data_seq_trials_", period, "ly.feather")
trials <- arrow::read_feather(here("output", "data", file_name))

################################################################################
# 1.0 Outcome model
################################################################################
fetch_formula <- function(f, model, period){
  if (period != "year"){
    if (model == "simple"){
      f <- update(. ~ period + trial, f)
    } else if (model == "interaction_period"){
      f <- update(. ~ period + trial + arm:period, f)
    } else if (model == "interaction_trial"){
      f <- update(. ~ period + trial + arm:trial, f)
    } else if (model == "interaction_all"){
      f <- update(. ~ period + trial + arm:period + arm:trial, f)
    } else if (model == "crude"){
      f <- status_seq ~ arm + ns(tend, 4)
    } else if (model == "crude_period"){
      f <- status_seq ~ arm + ns(tend, 4) + period
    } else if (model == "crude_trial"){
      f <- status_seq ~ arm + ns(tend, 4) + trial
    }
  } else if (period == "year"){
    if (model == "simple"){
      f <- update(. ~ trial, f)
    } else if (model == "interaction_trial"){
      f <- update(. ~ trial + arm:trial, f)
    } else if (model == "crude"){
      f <- status_seq ~ arm + ns(tend, 4)
    } else if (model == "crude_trial"){
      f <- status_seq ~ arm + ns(tend, 4) + trial
    }
  }
  f
}
print("Construct formula")
f <- fetch_formula(f, model, period)
print(f)
# Settings for parglm fitting
parglm_control <-
  parglm.control(maxit = 40,
                 nthreads = 4)
print("Fit outcome model")
tic()
om_fit <-
  parglm(f, 
         family = binomial(link = "logit"),
         data = trials,
         control = parglm_control,
         na.action = "na.fail",
         model = FALSE)
om_fit$data <- NULL
toc()
print("Process outcome model")
tic()
om_processed <-
  plr_process(
    plrmod = om_fit,
    model = model,
    cluster = ~ patient_id:tend + patient_id:trial,
    glance_plr,
    tidy_plr
  )
toc()

################################################################################
# 2.0 Save output
################################################################################
print("Write output")
tic()
saveRDS(
  om_fit,
  fs::path(output_dir, paste0("itt_fit_", period, "_", model, ".rds"))
)
saveRDS(
  om_processed$vcov,
  fs::path(output_dir, paste0("itt_vcov_", period, "_", model, ".rds"))
)
data.table::fwrite(
  om_processed$tidy,
  fs::path(output_dir, paste0("itt_fit_", period, "_", model, ".csv"))
)
data.table::fwrite(
  om_processed$glance,
  fs::path(output_dir, paste0("itt_glance_", period, "_", model, ".csv"))
)
toc()
