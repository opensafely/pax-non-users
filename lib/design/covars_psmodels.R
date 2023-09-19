# Note: age modelled with cubic spline with 3 knots
covars <-
  c("ns(age, df = 3)",
    "sex",
    "ethnicity",
    "imdQ5",
    "rural_urban",
    "region_nhs",
    # other comorbidities/clinical characteristics
    "obese",
    "smoking_status",
    "diabetes",
    "hypertension",
    "chronic_cardiac_disease",                                       
    "copd",
    "serious_mental_illness_nhsd",
    "learning_disability_primis",
    "dementia_nhsd",
    "autism_nhsd",
    "care_home_primis",
    "housebound_opensafely",
    # high risk group
    "downs_syndrome_nhsd",
    "cancer_opensafely_snomed_new", # non-overlapping
    "haematological_disease_nhsd",
    "imid_nhsd",
    "immunosupression_nhsd_new", # non-overlapping
    "hiv_aids_nhsd",
    "multiple_sclerosis_nhsd", 
    "motor_neurone_disease_nhsd",
    "myasthenia_gravis_nhsd",
    "huntingtons_disease_nhsd",
    # vax vars
    "vaccination_status",
    "tb_postest_vacc_cat",
    # calendar time
    "ns(study_week, df = 3)")