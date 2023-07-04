################################################################################
#
# Processing data
# 
# This script can be run via an action in project.yaml
#
# The output of this script is:
# -./output/data/data_processed.rds
# - ./output/data_properties/n_excluded.rds
# 
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library('dplyr')
library('lubridate')
library('here')
library('readr')
library('purrr')
## Import custom user functions
source(here::here("analysis", "data_import", "extract_data.R"))
source(here::here("analysis", "data_import", "process_data.R"))
source(here::here("analysis", "data_import", "calc_n_excluded.R"))
source(here::here("analysis", "data_import", "functions", "add_kidney_vars_to_data.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
fs::dir_create(here::here("output", "data"))
fs::dir_create(here::here("output", "data_properties"))

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)
study_dates <-
    jsonlite::read_json(path = here::here("lib", "design", "study-dates.json")) %>%
    map(as.Date)

################################################################################
# 1 Import data
################################################################################
input_filename <- "input.csv.gz"
data_extracted <- 
  extract_data(input_filename) %>%
  add_kidney_vars_to_data()
# change data if run using dummy data
if(Sys.getenv("OPENSAFELY_BACKEND") %in% c("", "expectations")){
  data_extracted <- 
    data_extracted %>%
    mutate(died_ons_covid_any_date = 
             if_else(!is.na(death_date), death_date, died_ons_covid_any_date),
           death_date =
             if_else(!is.na(died_ons_covid_any_date), died_ons_covid_any_date, death_date)) 
}

################################################################################
# 2 Process data
################################################################################
data_processed <- 
  map(.x = list(4, 5, 6, 7),
      .f = ~ process_data(data_extracted, study_dates, treat_window_days = .x))
names(data_processed) <- c("grace5", "grace6", "grace7", "grace8")

################################################################################
# 3 Apply additional eligibility and exclusion criteria
################################################################################
# calc n excluded
n_excluded <- calc_n_excluded(data_processed$grace5)
data_processed <-
  map(.x = data_processed, 
      .f = ~ .x %>%
        # Exclude patients treated with paxlovid and molnupiravir or sotrovimab on the
        # same day 
        filter(treated_pax_mol_same_day  == 0 & treated_pax_sot_same_day  == 0) %>%
        # Exclude patients hospitalised on day of positive test
        filter(!(status_all %in% c("covid_hosp", "noncovid_hosp") &
                   fu_all == 0)) %>%
        # if treated with remidesivir --> exclude
        filter(is.na(remdesivir_covid_therapeutics)))

################################################################################
# 4 Save data
################################################################################
# data_processed are saved
iwalk(.x = data_processed,
      .f = ~ write_rds(.x,
                       here::here("output", "data", 
                                  paste0(
                                    "data_processed",
                                    "_"[!.y == "grace5"],
                                    .y[!.y == "grace5"],
                                    ".rds"))))
write_rds(n_excluded,
          here::here("output", "data_properties", "n_excluded.rds"))