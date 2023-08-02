extract_data <- function(input_filename){
  data_extract <- read_csv(
    here::here("output", input_filename),
    col_types = cols_only(
      
      # Identifier
      patient_id = col_integer(),
      
      # POPULATION ----
      age = col_integer(),
      sex = col_character(),
      ethnicity = col_character(),
      imdQ5 = col_character(),
      region_nhs = col_character(),
      stp = col_character(),
      rural_urban = col_character(),
      
      # MAIN ELIGIBILITY - FIRST POSITIVE SARS-CoV-2 TEST IN PERIOD ----
      covid_test_positive_date = col_date(format = "%Y-%m-%d"),
      covid_test_positive = col_logical(),
      
      # TREATMENT - NEUTRALISING MONOCLONAL ANTIBODIES OR ANTIVIRALS ----
      paxlovid_covid_therapeutics = col_date(format = "%Y-%m-%d"),
      sotrovimab_covid_therapeutics = col_date(format = "%Y-%m-%d"),
      remdesivir_covid_therapeutics = col_date(format = "%Y-%m-%d"),
      molnupiravir_covid_therapeutics = col_date(format = "%Y-%m-%d"),
      casirivimab_covid_therapeutics = col_date(format = "%Y-%m-%d"),
      date_treated = col_date(format = "%Y-%m-%d"),
      
      # HIGH RISK GROUPS ----
      high_risk_cohort_covid_therapeutics = col_character(),
      downs_syndrome_nhsd  = col_logical(),
      cancer_opensafely_snomed = col_logical(), 
      cancer_opensafely_snomed_new = col_logical(), # non-overlapping
      haematological_disease_nhsd = col_logical(),
      ckd_stage_5_nhsd = col_logical(), 
      liver_disease_nhsd = col_logical(), 
      imid_nhsd = col_logical(), 
      immunosupression_nhsd = col_logical(),
      immunosupression_nhsd_new = col_logical(), # non-overlapping
      hiv_aids_nhsd = col_logical(),
      solid_organ_transplant_nhsd = col_logical(), 
      solid_organ_transplant_nhsd_new = col_logical(), # non-overlapping
      multiple_sclerosis_nhsd = col_logical(),
      motor_neurone_disease_nhsd = col_logical(),
      myasthenia_gravis_nhsd = col_logical(),
      huntingtons_disease_nhsd = col_logical(), 
      # because investigating contraindications
      solid_organ_transplant_nhsd_snomed_new = col_logical(),
      solid_organ_transplant_nhsd_snomed_new_code = col_character(), # added to investigate codes for exclusion while treated
      solid_organ_transplant_nhsd_opcs4 = col_logical(),
      transplant_thymus_opcs4 = col_logical(),
      transplant_conjunctiva_opcs4 = col_logical(),
      transplant_stomach_opcs4 = col_logical(),
      transplant_ileum_1_opcs4 = col_logical(),
      transplant_ileum_2_opcs4 = col_logical(),
      

      # CONTRAINDICATIONS ----
      advanced_decompensated_cirrhosis = col_logical(),
      advanced_decompensated_cirrhosis_code = col_character(), # added to investigate codes for exclusion while treated
      decompensated_cirrhosis_icd10 = col_logical(), 
      decompensated_cirrhosis_icd10_code = col_character(), # added to investigate codes for exclusion while treated
      ascitic_drainage_snomed = col_logical(),
      ascitic_drainage_snomed_date = col_date(format = "%Y-%m-%d"),
      liver_disease_nhsd_icd10 = col_logical(), #note subset of decompensated_cirrhosis_icd10
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
      solid_organ_transplant_snomed = col_logical(),
      solid_organ_transplant_snomed_code = col_character(), # added to investigate codes for exclusion while treated
      drugs_do_not_use = col_logical(),

      # CAUTION AGAINST ----
      drugs_consider_risk = col_logical(),

      # CLINICAL/DEMOGRAPHIC COVARIATES ----
      diabetes = col_logical(),
      hypertension = col_logical(),
      chronic_cardiac_disease = col_logical(),
      obese = col_character(),
      smoking_status = col_character(),
      copd = col_logical(),
      autism_nhsd = col_logical(),
      care_home_primis = col_logical(),
      dementia_nhsd = col_logical(),
      housebound_opensafely = col_logical(),
      serious_mental_illness_nhsd = col_logical(),
      learning_disability_primis = col_logical(),
      
      # VACCINATION ----
      vaccination_status = col_character(),
      date_most_recent_cov_vac = col_date(format = "%Y-%m-%d"),
      pfizer_most_recent_cov_vac = col_logical(),
      az_most_recent_cov_vac = col_logical(),
      moderna_most_recent_cov_vac = col_logical(),
      
      # OUTCOMES ----
      death_date = col_date(format = "%Y-%m-%d"),
      died_ons_covid_any_date = col_date(format = "%Y-%m-%d"),
      died_ons_covid_date = col_date(format = "%Y-%m-%d"),
      dereg_date = col_date(format = "%Y-%m-%d"),
      # hosp
      # covid specific
      covid_hosp_admission_date0 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_date1 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_date2 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_date3 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_date4 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_date5 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_date6 = col_date(format = "%Y-%m-%d"),
      covid_hosp_admission_first_date7_28 = col_date(format = "%Y-%m-%d"),
      covid_hosp_discharge_date = col_date(format = "%Y-%m-%d"),
      covid_hosp_date_mabs_procedure = col_date(format = "%Y-%m-%d"),
      # all cause
      allcause_hosp_admission_date0 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_date1 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_date2 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_date3 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_date4 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_date5 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_date6 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_admission_first_date7_28 = col_date(format = "%Y-%m-%d"),
      allcause_hosp_discharge_date = col_date(format = "%Y-%m-%d"),
      allcause_hosp_date_mabs_procedure = col_date(format = "%Y-%m-%d"),
      # cause/diagnosis
      death_cause = col_character(),
      allcause_hosp_admission_diagnosis0 = col_character(),
      allcause_hosp_admission_diagnosis1 = col_character(),
      allcause_hosp_admission_diagnosis2 = col_character(),
      allcause_hosp_admission_diagnosis4 = col_character(),
      allcause_hosp_admission_diagnosis3 = col_character(),
      allcause_hosp_admission_diagnosis5 = col_character(),
      allcause_hosp_admission_diagnosis6 = col_character(),
      allcause_hosp_admission_first_diagnosis7_28 = col_character()
    )
  )
}