################################################################################
#
# Data wrangling seq trials
# 
# The output of this script is:
# feather file ./output/data/data_seq_trials_*.feather
# where * \in (monthly, bimonthly, weekly)
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
library(optparse)
source(here::here("analysis", "seq_trials", "functions", "simplify_data.R"))
source(here::here("analysis", "seq_trials", "functions", "split_data.R"))
source(here::here("analysis", "seq_trials", "functions", "construct_trials.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "data")
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
                help = "Subsets in wich data is cut, options are 'month', '2month', '3month' and 'week' [default %default]. ",
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

################################################################################
# 0.4 Data manipulation
################################################################################
data_splitted <-
  data %>%
  simplify_data() %>%
  split_data()
# make dummy data better
if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")){
  data_splitted <-
    data_splitted %>%
    select(patient_id, tstart, tend, period, status_seq, starts_with("treatment_seq"))
}

################################################################################
# 1.0 Construct trials (eg monthly, bimonthly and weekly, depending on input args)
################################################################################
cuts <- data %>% pull(period) %>% unique() %>% sort()
trials <-
  map_dfr(
    .x = cuts,
    .f = ~
      construct_trials(
        data_splitted %>% filter(period == .x),
        5)
    )

################################################################################
# 2.0 Save output
################################################################################.
file_name <- paste0("data_seq_trials_", period, "ly.feather")
arrow::write_feather(trials, fs::path(output_dir, file_name))
