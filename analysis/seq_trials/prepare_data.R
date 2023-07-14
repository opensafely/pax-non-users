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
data <-
  data %>%
  simplify_data() %>%
  survsplit_data()
  

data_trial0 <-
  data %>%
  mutate(trial = 0) %>%
  group_by(patient_id) %>%
  mutate(rownum = row_number())%>%
  mutate(A.baseline = first(A))%>%
  mutate(L.baseline = first(L))%>%
  mutate(time.new = time - trial)%>%
  mutate(time.stop.new = time.stop - trial)

################################################################################
# 1.0 
################################################################################

################################################################################
# 2.0 Save output
################################################################################
saveRDS(path(output_dir, "data_seq_trial.rds"))
