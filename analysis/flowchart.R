################################################################################
#
# Numbers for flowchart
# 
# The output of this script is:
# -./output/data_properties/flowchart.csv
#
################################################################################

################################################################################
# 0.0 Import libraries + functions
library(here)
library(readr)
library(dplyr)
library(fs)

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "flowchart")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 1 Import data
################################################################################
data_filename <- "data_flowchart_processed.rds"
n_excluded_filename <- "n_excluded.rds"
n_excluded_contraindicated_filename <- "n_excluded_contraindicated.rds"
data <-
  read_rds(here::here("output", "data", data_filename))
n_excluded_in_data_processing <-
  read_rds(here::here("output", "data_properties", n_excluded_filename))
n_excluded_contraindicated <-
  read_rds(here::here("output", "data_properties", n_excluded_contraindicated_filename))

################################################################################
# 2 Calc numbers
################################################################################
# Set rounding and redaction thresholds
rounding_threshold = 6
redaction_threshold = 8
total_n <- nrow(data)
# missing age
missing_age <-
  data %>%
  filter(is.na(age)) %>%
  nrow()
age_outside_range <- 
  data %>%
  filter(!is.na(age) & (age < 18 | age >= 110)) %>%
  nrow()
# missing sex
missing_sex <-
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(is.na(sex) | !(sex %in% c("F", "M"))) %>%
  nrow()
# missing stp
missing_stp <-
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(sex %in% c("F", "M")) %>%
  filter(stp == "" | is.na(stp)) %>%
  nrow()
# missing imd
missing_imd <-
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(sex %in% c("F", "M")) %>%
  filter(stp != "" & !is.na(stp)) %>%
  filter(imd == "-1") %>%
  nrow()
# previously treated
prev_treated <- 
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(sex %in% c("F", "M")) %>%
  filter(stp != "" & !is.na(stp)) %>%
  filter(imd != "-1") %>%
  filter(prev_treated == TRUE) %>% 
  nrow()
# not previously treated but evidence of covid < 90 days
evidence_covid <- 
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(sex %in% c("F", "M")) %>%
  filter(stp != "" & !is.na(stp)) %>%
  filter(imd != "-1") %>%
  filter(prev_treated == FALSE) %>%
  filter(covid_positive_prev_90_days == TRUE |
           any_covid_hosp_prev_90_days == TRUE ) %>%
  nrow()
# not previously treated and no evidence of covid < 90 days but in hospital
in_hospital_when_tested <- 
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(sex %in% c("F", "M")) %>%
  filter(stp != "" & !is.na(stp)) %>%
  filter(imd != "-1") %>%
  filter(prev_treated == FALSE) %>%
  filter(covid_positive_prev_90_days == FALSE &
           any_covid_hosp_prev_90_days == FALSE) %>%
  filter(in_hospital_when_tested == TRUE) %>% 
  nrow()
# included
total_n_included <- 
  data %>%
  filter(!is.na(age) & (age >= 18 & age < 110)) %>%
  filter(sex %in% c("F", "M")) %>%
  filter(stp != "" & !is.na(stp)) %>%
  filter(imd != "-1") %>%
  filter(prev_treated == FALSE) %>%
  filter(covid_positive_prev_90_days == FALSE &
           any_covid_hosp_prev_90_days == FALSE) %>%
  filter(in_hospital_when_tested == FALSE) %>% 
  nrow()
# combine numbers
out <-
  tibble(total_n,
         missing_age,
         age_outside_range,
         missing_sex,
         missing_stp,
         missing_imd,
         prev_treated,
         evidence_covid,
         in_hospital_when_tested,
         total_n_included)
out <- 
  bind_cols(out, n_excluded_in_data_processing, n_excluded_contraindicated) %>%
  tidyr::pivot_longer(everything())
out_redacted <- 
  out %>%
  mutate(across(where(~ is.integer(.x)), 
                ~ case_when(.x > 0 & .x <= redaction_threshold ~ "[REDACTED]",
                            TRUE ~ .x %>% 
                              plyr::round_any(rounding_threshold) %>% 
                              as.character())))

################################################################################
# 3 Save output
################################################################################
write_csv(x = out,
          path(output_dir, "flowchart.csv"))
write_csv(x = out_redacted,
          path(output_dir, "flowchart_redacted.csv"))
