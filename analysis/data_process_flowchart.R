################################################################################
#
# Processing data flowchart
# 
# This script can be run via an action in project.yaml using one argument:
# - 'period' /in {ba1, ba2} --> period 
#
# Depending on 'period' the output of this script is:
# -./output/data/'period'_data_processed.rds
# (if period == ba1, no prefix is used)
#
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(here)
library(readr)
library(dplyr)
library(purrr)
library(fs)

################################################################################
# 0.1 Create directories for output
################################################################################
fs::dir_create(here::here("output", "data"))

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 1 Import data
################################################################################
input_filename <- "input_flowchart.csv.gz"
input_file <- here::here("output", input_filename)
data_processed <- 
  read_csv(input_file, 
           col_types = cols_only(
             patient_id = col_integer(),
             age = col_integer(),
             sex = col_character(),
             stp = col_character(),
             imd = col_character(),
             prev_treated = col_logical(),
             covid_positive_prev_90_days = col_logical(),
             any_covid_hosp_prev_90_days = col_logical(),
             in_hospital_when_tested = col_logical(),
             # CONTRAINDICATIONS ----
             advanced_decompensated_cirrhosis = col_logical(),
             decompensated_cirrhosis_icd10 = col_logical(), 
             ascitic_drainage_snomed = col_logical(),
             ascitic_drainage_snomed_date = col_date(format = "%Y-%m-%d"),
             ascitic_drainage_snomed_pre = col_logical(),
             ascitic_drainage_snomed_pre_date = col_date(format = "%Y-%m-%d"),
             ckd_primis_stage = col_character(),
             ckd3_icd10 = col_logical(),
             ckd4_icd10 = col_logical(),
             ckd5_icd10 = col_logical(),
             dialysis = col_logical(),
             dialysis_icd10 = col_logical(),
             dialysis_procedure = col_logical(),
             kidney_transplant = col_logical(),
             kidney_transplant_icd10 = col_logical(),
             kidney_transplant_procedure = col_logical(),
             rrt = col_logical(),
             rrt_icd10 = col_logical(),
             rrt_procedure = col_logical(),
             creatinine_ctv3 = col_double(),
             creatinine_operator_ctv3 = col_character(),
             age_creatinine_ctv3 = col_integer(),
             creatinine_snomed = col_double(),
             creatinine_operator_snomed = col_character(),
             age_creatinine_snomed = col_integer(),
             creatinine_short_snomed = col_double(),
             creatinine_operator_short_snomed = col_character(),
             age_creatinine_short_snomed = col_integer(),
             eGFR_record = col_double(),
             eGFR_operator = col_character(),
             eGFR_short_record = col_double(),
             eGFR_short_operator = col_character(),
             drugs_do_not_use = col_logical(),
             # CAUTION AGAINST ----
             drugs_consider_risk = col_logical()))

################################################################################
# 2 Save data
################################################################################
write_rds(data_processed,
          here::here("output", "data", "data_flowchart_processed.rds")
          )
