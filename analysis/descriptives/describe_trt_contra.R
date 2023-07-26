################################################################################
#
# Proportion treated
# 
# The output of this script is:
# csv file ./output/descriptives/trt_contra(_red).csv
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
source(here::here("lib", "design", "redaction.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives")
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
data <- read_rds(here("output", "data", "data_processed.rds"))

################################################################################
# 0.4 Data manipulation
################################################################################

################################################################################
# 1.0 Number of people treated who are contraindicated
################################################################################
# Proportion treated 
calc_trt_contra <- function(data) {
  n_trt_contra <- data %>%
    group_by(treatment_strategy_cat, .drop = FALSE) %>%
    summarise(n_cirrhosis_snomed = sum(ci_cirrhosis_snomed),
              n_cirrhosis_icd10 = sum(ci_cirrhosis_icd10),
              n_ascitic_drainage = sum(ci_ascitic_drainage),
              n_solid_organ_highrisk = sum(ci_solid_organ_highrisk),
              n_solid_organ_snomed = sum(ci_solid_organ_snomed),
              n_ckd_stage5_nhsd = sum(ci_ckd5_nhsd),
              n_ckd3_primis = sum(ci_ckd3_primis),
              n_ckd45_primis = sum(ci_ckd45_primis),
              n_ckd3_icd10 = sum(ci_ckd3_icd10),
              n_ckd45_icd10 = sum(ci_ckd45_icd10),
              n_dialysis = sum(ci_dialysis),
              n_kidney_transplant = sum(ci_kidney_transplant),
              n_egfr_30_59 = sum(ci_egfr_30_59),
              n_egfr_below30 = sum(ci_egfr_below30),
              n_egfr_creat_30_59 = sum(ci_egfr_creat_30_59),
              n_egfr_creat_below30 = sum(ci_egfr_creat_below30),
              n_drugs_do_not_use = sum(ci_drugs_do_not_use),
              n_drugs_caution = sum(drugs_consider_risk),
              n_contraindicated = sum(contraindicated),
              n_contraindicated_strict = sum(contraindicated_strict),
              n_all = n(),
              .groups = "keep") %>%
    tidyr::pivot_longer(-1) %>%
    tidyr::pivot_wider(names_from = 1, values_from = value) %>%
    mutate(n_total = rowSums(across(where(is.numeric))))
}
redact_trt_contra <- function(trt_contra) {
  trt_contra <-
    trt_contra %>%
    mutate(across(where(is.numeric), ~ if_else(.x > 0 & .x <= redaction_threshold, 
                                               "[REDACTED]",  
                                               .x %>% plyr::round_any(rounding_threshold) %>% as.character())))
}
trt_contra <- calc_trt_contra(data)
trt_contra_red <-
  trt_contra %>% redact_trt_contra()

################################################################################
# 1.1 Codes 
################################################################################
n_cirrhosis_snomed <-
  data %>%
  filter(ci_cirrhosis_snomed & treatment_strategy_cat == "Paxlovid") %>%
  group_by(advanced_decompensated_cirrhosis_code, .drop = FALSE) %>%
  summarise(n = n())
n_cirrhosis_icd10 <-
  data %>%
  filter(ci_cirrhosis_icd10 & treatment_strategy_cat == "Paxlovid") %>%
  group_by(decompensated_cirrhosis_icd10_code, .drop = FALSE) %>%
  summarise(n = n())
n_organ_transplant_nhsd_snomed_new <-
  data %>%
  filter(ci_solid_organ_highrisk & treatment_strategy_cat == "Paxlovid") %>%
  group_by(solid_organ_transplant_nhsd_snomed_new_code, .drop = FALSE) %>%
  summarise(n = n())  
n_organ_transplant_snomed <-
  data %>%
  filter(ci_solid_organ_snomed & treatment_strategy_cat == "Paxlovid") %>%
  group_by(solid_organ_transplant_snomed_code, .drop = FALSE) %>%
  summarise(n = n()) 
n_codes_contra <-
  list(cirrhosis_snomed = n_cirrhosis_snomed,
       cirrhosis_icd10 = n_cirrhosis_icd10,
       organ_transplant_nhsd_snomed_new = n_organ_transplant_nhsd_snomed_new,
       organ_transplant_snomed = n_organ_transplant_snomed)
n_codes_contra_red <-
  map(.x = n_codes_contra,
      .f = ~ .x %>% redact_trt_contra())

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = trt_contra,
          path(output_dir, "trt_contra.csv"))
write_csv(x = trt_contra_red,
          path(output_dir, "trt_contra_red.csv"))
iwalk(.x = n_codes_contra,
      .f = ~ write_csv(.x,
                       path(output_dir, paste0("n_codes_", .y, ".csv"))))
iwalk(.x = n_codes_contra_red,
      .f = ~ write_csv(.x,
                       path(output_dir, paste0("n_codes_", .y, "_red.csv"))))
