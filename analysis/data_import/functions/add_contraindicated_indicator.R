add_contraindicated_indicator <- function(data_processed) {
  data_processed <-
    data_processed %>% 
    mutate(
      excl_liver_disease = 
        if_else(
          advanced_decompensated_cirrhosis == TRUE |
            decompensated_cirrhosis_icd10 == TRUE |
            ascitic_drainage_snomed == TRUE |
            liver_disease_nhsd_icd10 == TRUE,
          TRUE,
          FALSE
        ),
      excl_solid_organ_transplant =
        if_else(
          solid_organ_transplant_nhsd_new == TRUE |
            solid_organ_transplant_snomed == TRUE,
          TRUE,
          FALSE
        ),
      excl_renal_disease =
        if_else(
          ckd_stage_5_nhsd == TRUE |
            (ckd_stages_3_5 %in% c("3", "4", "5")) |
            ckd3_icd10 == TRUE | ckd4_icd10 == TRUE | ckd5_icd10 == TRUE |
            dialysis == TRUE | dialysis_icd10 == TRUE | dialysis_procedure == TRUE |
            kidney_transplant == TRUE | kidney_transplant_icd10 == TRUE | kidney_transplant_procedure == TRUE |
            eGFR_record < 60 | eGFR_short_record < 60 | egfr_ctv3 < 60 | egfr_snomed < 60 | egfr_short_snomed < 60,
          TRUE,
          FALSE
        ),
      excl_drugs_do_not_use =
        if_else(
          drugs_do_not_use == TRUE,
          TRUE,
          FALSE
        ),
      excl_contraindicated =
        if_else(excl_liver_disease == TRUE |
                  excl_solid_organ_transplant == TRUE |
                  excl_renal_disease == TRUE |
                  excl_drugs_do_not_use == TRUE,
                TRUE,
                FALSE)
    )
}