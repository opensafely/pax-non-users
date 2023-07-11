add_contraindicated_indicator <- function(data_processed) {
  data_processed <-
    data_processed %>% 
    mutate(
      excl_cirrhosis = 
        if_else(advanced_decompensated_cirrhosis | decompensated_cirrhosis_icd10, TRUE, FALSE),
      excl_ascitic_drainage =
        if_else(ascitic_drainage_snomed, TRUE, FALSE),
      excl_liver_disease_icd10 =
        if_else(liver_disease_nhsd_icd10, TRUE, FALSE),
      excl_solid_organ_highrisk =
        if_else(solid_organ_transplant_nhsd_new, TRUE, FALSE),
      excl_solid_organ_snomed =
        if_else(solid_organ_transplant_snomed, TRUE, FALSE),
      excl_ckd5_nhsd = 
        if_else(ckd_stage_5_nhsd, TRUE, FALSE),
      excl_ckd3_primis =
        if_else(!is.na(ckd_primis_stage) & ckd_primis_stage == "3", TRUE, FALSE), # FIXME: add one missing code ckd_stages_3_5
      # https://www.opencodelists.org/codelist/primis-covid19-vacc-uptake/ckd35/v.1.5.3/diff/77b93e93/
      excl_ckd45_primis =
        if_else(ckd_primis_stage %in% c("4", "5"), TRUE, FALSE), #FIXME: add two codes ckd_stages_3_5
      excl_ckd3_icd10 = 
        if_else(ckd3_icd10, TRUE, FALSE),
      excl_ckd45_icd10 =
        if_else(ckd4_icd10 | ckd5_icd10, TRUE, FALSE),
      excl_dialysis =
        if_else(dialysis | dialysis_icd10 | dialysis_procedure, TRUE, FALSE),
      excl_kidney_transplant =
        if_else(kidney_transplant | kidney_transplant_icd10 | kidney_transplant_procedure, TRUE , FALSE),
      excl_egfr_30_59 = 
        if_else((!is.na(eGFR_record) & (eGFR_record >= 30 & eGFR_record < 60)) | 
                  (!is.na(eGFR_short_record) & (eGFR_short_record >= 30 & eGFR_short_record < 60)), TRUE, FALSE),
      excl_egfr_below30 = 
        if_else((!is.na(eGFR_record) & eGFR_record < 30) | 
                  (!is.na(eGFR_short_record) & eGFR_short_record < 30), TRUE, FALSE),
      excl_egfr_creat_30_59 =
        if_else((!is.na(egfr_ctv3) & (egfr_ctv3 >= 30 & egfr_ctv3 < 60)) | 
                  (!is.na(egfr_snomed) & (egfr_snomed >= 30 & egfr_snomed < 60)) |
                  (!is.na(egfr_short_snomed) & (egfr_short_snomed >= 30 & egfr_short_snomed < 60)), TRUE, FALSE),
      excl_egfr_creat_below30 =
        if_else((!is.na(egfr_ctv3) & egfr_ctv3 < 30) | 
                  (!is.na(egfr_snomed) & egfr_snomed < 30) |
                  (!is.na(egfr_short_snomed) & egfr_short_snomed < 30), TRUE, FALSE),
      excl_drugs_do_not_use =
        if_else(drugs_do_not_use, TRUE, FALSE),
      # aggregated
      excl_liver_disease = 
        if_else(excl_cirrhosis | excl_ascitic_drainage | excl_liver_disease_icd10, TRUE, FALSE),
      excl_solid_organ_transplant =
        if_else(excl_solid_organ_highrisk | excl_solid_organ_snomed, TRUE, FALSE),
      excl_renal_disease =
        if_else(excl_ckd5_nhsd | excl_ckd45_primis | excl_ckd45_icd10 |
                  excl_dialysis | excl_kidney_transplant | excl_egfr_below30 |
                  excl_egfr_creat_below30, TRUE, FALSE), # not excluding ckd stage3
      excl_contraindicated =
        if_else(excl_liver_disease | excl_solid_organ_transplant |
                  excl_renal_disease | excl_drugs_do_not_use, TRUE, FALSE),
      excl_contraindicated_strict =
        if_else(excl_liver_disease | excl_solid_organ_transplant | 
                  excl_renal_disease | excl_ckd3_primis | excl_ckd3_icd10 |
                  excl_egfr_30_59 | excl_egfr_creat_30_59 |
                  excl_drugs_do_not_use, TRUE, FALSE)
    )
}