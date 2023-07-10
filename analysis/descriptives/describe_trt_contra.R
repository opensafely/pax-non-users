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
# Set rounding and redaction thresholds
rounding_threshold = 6
redaction_threshold = 8
total_n <- nrow(data)
# Proportion treated 
calc_trt_contra <- function(data) {
  n_trt_contra <- data %>%
    filter(excl_contraindicated == TRUE &
             treatment_strategy_cat %in% c("Paxlovid", "Untreated")) %>%
    group_by(treatment_strategy_cat, .drop = FALSE) %>%
    summarise(n_cirrhosis = sum(advanced_decompensated_cirrhosis == TRUE |
                        decompensated_cirrhosis_icd10 == TRUE),
              n_ascitic_drainage = sum(ascitic_drainage_snomed == TRUE),
              n_liver_disease = sum(liver_disease_nhsd_icd10 == TRUE),
              n_solid_organ_highrisk = sum(solid_organ_transplant_nhsd_new == TRUE),
              n_solid_organ_snomed = sum(solid_organ_transplant_snomed == TRUE),
              n_ckd_stage5_nhsd = sum(ckd_stage_5_nhsd == TRUE),
              n_ckd_3_primis = sum(ckd_primis_stage== "3"), #FIXME
              n_ckd_stages45_primis = sum(ckd_stages_3_5 == TRUE |
                                            ckd_primis_stage %in% c("4", "5")), #FIXME
              n_ckd3_icd10 = sum(ckd3_icd10 == TRUE),
              n_ckd45_icd10 = sum(ckd4_icd10 == TRUE | ckd5_icd10 == TRUE),
              n_dialysis = sum(dialysis == TRUE | dialysis_icd10 == TRUE |
                                 dialysis_procedure == TRUE),
              n_kidney_transplant = sum(kidney_transplant == TRUE | 
                                          kidney_transplant_icd10 == TRUE | 
                                          kidney_transplant_procedure == TRUE),
              n_egfr_30_59 = sum((!is.na(eGFR_record) & (eGFR_record >= 30 & eGFR_record < 60)) | 
                                   (!is.na(eGFR_short_record) & (eGFR_short_record >= 30 & eGFR_short_record < 60))),
              n_egfr_below30 = sum((!is.na(eGFR_record) & eGFR_record < 30) | 
                                     (!is.na(eGFR_short_record) & eGFR_short_record < 30)),
              n_egfr_creat_30_59 = sum((!is.na(egfr_ctv3) & (egfr_ctv3 >= 30 & egfr_ctv3 < 60)) | 
                                         (!is.na(egfr_snomed) & (egfr_snomed >= 30 & egfr_snomed < 60)) |
                                         (!is.na(egfr_short_snomed) & (egfr_short_snomed >= 30 & egfr_short_snomed < 60))),
              n_egfr_creat_30 = sum((!is.na(egfr_ctv3) & egfr_ctv3 < 30) | 
                                      (!is.na(egfr_snomed) & egfr_snomed < 30) |
                                      (!is.na(egfr_short_snomed) & egfr_short_snomed < 30)),
              n_drugs_do_not_use = sum(drugs_do_not_use == TRUE),
              n_drugs_caution = sum(drugs_consider_risk == TRUE),
              n_all = n(),
              .groups = "keep") %>%
    tidyr::pivot_longer(-1) %>%
    tidyr::pivot_wider(names_from = 1, values_from = value) %>%
    mutate(n_total = rowSums(across(where(is.numeric))))
}
redact_trt_contra <- function(trt_contra) {
  trt_contra #FIXME
}
trt_contra <- calc_trt_contra(data)
trt_contra_red <-
  trt_contra %>% redact_trt_contra()

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = trt_contra,
          path(output_dir, "trt_contra.csv"))
write_csv(x = trt_contra_red,
          path(output_dir, "trt_contra_red.csv"))
