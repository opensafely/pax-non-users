################################################################################
#
# INTENTION TO TREAT ANALYSIS - CUM INC CURVES
# 
# The output of this script is:
# csv file ./output/seq_trials/itt/itt_survcurves_*.csv and
# csv file ./output/seq_trials/itt/itt_diffcurve_*.csv and
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
source(here::here("analysis", "seq_trials", "functions", "create_survcurve.R"))
source(here::here("analysis", "seq_trials", "functions", "create_diffcurve.R"))
source(here::here("analysis", "seq_trials", "functions", "estimate_variance_cuminc.R"))
source(here::here("analysis", "seq_trials", "functions", "estimate_variance_riskdiff.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "itt", "curves")
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
fit <- readRDS(here("output", "seq_trials", "itt", glue("itt_fit_{model}.rds")))
vcov <- readRDS(here("output", "seq_trials", "itt", glue("itt_vcov_{model}.rds")))
trials <- arrow::read_feather(here("output", "data", "data_seq_trials_monthly.feather"))
data_trt1 <- trials %>% mutate(arm = factor(1, levels = c("0", "1")), w = 1)
data_trt0 <- trials %>% mutate(arm = factor(0, levels = c("0", "1")), w = 1)

################################################################################
# 1.0 Outcome model
################################################################################
survcurves <- 
  imap(.x = list("curve0" = data_trt0, "curve1" = data_trt1),
       .f = ~ create_survcurve(data_counterfact = .x,
                               plrmod = fit,
                               vcov = vcov,
                               cuminc_variance = cuminc_variance,
                               id = "patient_id",
                               trial = "trial",
                               time = "tend",
                               weights = "w") %>%
         mutate(arm = as.integer(stringr::str_extract(.y, "\\d+")),
                arm_descr = if_else(arm == 0, "Untreated", "Treated"),
                .before = 1)) %>% bind_rows()
diffcurve <-
  create_diffcurve(survcurve1 = survcurves %>% filter(arm == 1),
                   survcurve0 = survcurves %>% filter(arm == 0),
                   data_counterfact1 = data_trt1,
                   data_counterfact0 = data_trt0,
                   plrmod = fit,
                   vcov = vcov,
                   riskdiff_variance = riskdiff_variance,
                   id = "patient_id",
                   trial = "trial",
                   time = "tend",
                   weights = "w")

################################################################################
# 2.0 Save output
################################################################################
data.table::fwrite(
  survcurves,
  fs::path(output_dir, glue("itt_survcurves_{model}.csv"))
)
data.table::fwrite(
  diffcurve,
  fs::path(output_dir, glue("itt_diffcurve_{model}.csv"))
)

