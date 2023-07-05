exclude_contraindicated <- function(data_processed) {
  data_processed <-
    data_processed %>% 
    filter(advanced_decompensated_cirrhosis == FALSE & decompensated_cirrhosis_icd10 == FALSE) %>%
    filter(ascitic_drainage_snomed == FALSE) %>%
    filter(liver_disease_nhsd_icd10 == FALSE) %>%
    filter(solid_organ_transplant_nhsd_new == FALSE) %>%
    filter(solid_organ_transplant_snomed == FALSE) %>%
    filter(ckd_stage_5_nhsd == FALSE) %>%
    filter(!(ckd_stages_3_5 %in% c("3", "4", "5"))) %>%
    filter(ckd3_icd10 == FALSE & ckd4_icd10 == FALSE & ckd5_icd10 == FALSE) %>%
    filter(dialysis == FALSE & dialysis_icd10 == FALSE & dialysis_procedure == FALSE) %>%
    filter(kidney_transplant == FALSE & kidney_transplant_icd10 == FALSE & kidney_transplant_procedure == FALSE) %>%
    filter(eGFR_record >= 60 & eGFR_short_record >= 60 & egfr_ctv3 >= 60 & egfr_snomed >= 60 & egfr_short_snomed >= 60) %>%
    filter(drugs_do_not_use == FALSE) 
}