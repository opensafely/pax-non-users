#######
## Function to clean table names
clean_coef_names = function(input_table) {
  # Relabel variables for plotting
  #input_table$Variable[input_table$Variable=="diabetes"] = "Diabetes"
  
  # Relabel variables for plotting
  # demographics
  input_table$variable[input_table$variable=="ns(age, df = 3)3"] = "Age: term3"
  input_table$variable[input_table$variable=="ns(age, df = 3)2"] = "Age: term2"
  input_table$variable[input_table$variable=="ns(age, df = 3)1"] = "Age: term1"
  
  input_table$variable[input_table$variable=="sexMale"] = "Sex: Male"
  input_table$variable[input_table$variable=="ethnicityAsian or Asian British"] = "Ethnicity: Asian"
  input_table$variable[input_table$variable=="ethnicityBlack or Black British"] = "Ethnicity: Black"
  input_table$variable[input_table$variable=="ethnicityWhite"] = "Ethnicity: White"
  input_table$variable[input_table$variable=="ethnicityOther ethnic groups"] = "Ethnicity: Other"
  input_table$variable[input_table$variable=="ethnicityMixed"] = "Ethnicity: Mixed"
  
  input_table$variable[input_table$variable=="imdQ54"] = "IMD: 4"
  input_table$variable[input_table$variable=="imdQ53"] = "IMD: 3"
  input_table$variable[input_table$variable=="imdQ52"] = "IMD: 2"
  input_table$variable[input_table$variable=="imdQ51 (most deprived)"] = "IMD: 1"
  
  input_table$variable[input_table$variable=="stpSTP9"] = "STP9"
  input_table$variable[input_table$variable=="stpSTP10"] = "STP10"
  input_table$variable[input_table$variable=="stpSTP8"] = "STP8"
  input_table$variable[input_table$variable=="stpSTP7"] = "STP7"
  input_table$variable[input_table$variable=="stpSTP6"] = "STP6"
  input_table$variable[input_table$variable=="stpSTP5"] = "STP5"
  input_table$variable[input_table$variable=="stpSTP4"] = "STP4"
  input_table$variable[input_table$variable=="stpSTP3"] = "STP3"
  input_table$variable[input_table$variable=="stpSTP2"] = "STP2"
  
  input_table$variable[input_table$variable=="rural_urbanUrban - city and town"] = "Urban: City/Town"
  input_table$variable[input_table$variable=="rural_urbanRural - village and dispersed"] = "Rural: Village/Disp."
  input_table$variable[input_table$variable=="rural_urbanRural - town and fringe"] = "Rural: Town/Fringe"
  # clinical characteristics
  input_table$variable[input_table$variable=="obeseObese II (35-39.9)"] = "Obese II"
  input_table$variable[input_table$variable=="obeseObese I (30-34.9)"] = "Obesity I"
  input_table$variable[input_table$variable=="obeseObese III (40+)"] = "Obesity III"
  
  input_table$variable[input_table$variable=="smoking_statusUnknown"] = "Smoking status: Unknown"
  input_table$variable[input_table$variable=="smoking_statusNever"] = "Smoking status: Never"
  input_table$variable[input_table$variable=="smoking_statusEver"] = "Smoking status: Ever"
  input_table$variable[input_table$variable=="diabetesTRUE"] = "Diabetes"
  input_table$variable[input_table$variable=="chronic_cardiac_diseaseTRUE"] = "Chronic Cardiac Disease"
  input_table$variable[input_table$variable=="copdTRUE"] = "COPD"
  input_table$variable[input_table$variable=="dialysis"] = "Dialysis"
  input_table$variable[input_table$variable=="serious_mental_illness_nhsdTRUE"] = "Severe mental illness"
  input_table$variable[input_table$variable=="learning_disability_primisTRUE"] = "Learning disability"
  input_table$variable[input_table$variable=="dementia_nhsdTRUE"] = "Dementia"
  input_table$variable[input_table$variable=="autism_nhsdTRUE"] = "Autism"
  input_table$variable[input_table$variable=="care_home_primisTRUE"] = "Care home"
  input_table$variable[input_table$variable=="housebound_opensafelyTRUE"] = "Housebound"
  input_table$variable[input_table$variable=="hypertensionTRUE"] = "Hypertension"
  # high risk variables
  input_table$variable[input_table$variable=="downs_syndrome_nhsdTRUE"] = "Down's syndrome"
  input_table$variable[input_table$variable=="cancer_opensafely_snomed_newTRUE"] = "Solid cancer"
  input_table$variable[input_table$variable=="haematological_disease_nhsdTRUE"] = "Haematological diseases"
  input_table$variable[input_table$variable=="ckd_stage_5_nhsd"] = "Renal disease"
  input_table$variable[input_table$variable=="liver_disease_nhsdTRUE"] = "Liver disease"
  input_table$variable[input_table$variable=="imid_nhsdTRUE"] = "IMID)"
  input_table$variable[input_table$variable=="immunosupression_nhsd_new"] = "Immune deficiencies"
  input_table$variable[input_table$variable=="hiv_aids_nhsdTRUE"] = "HIV/AIDs"
  input_table$variable[input_table$variable=="solid_organ_transplant_nhsd_new"] = "Solid organ transplant"
  input_table$variable[input_table$variable=="multiple_sclerosis_nhsdTRUE"] = "Multiple sclerosis"
  input_table$variable[input_table$variable=="motor_neurone_disease_nhsdTRUE"] = "Motor neurone disease"
  input_table$variable[input_table$variable=="myasthenia_gravis_nhsdTRUE"] = "Myasthenia gravis"
  input_table$variable[input_table$variable=="huntingtons_disease_nhsdTRUE"] = "Huntington’s disease"
  # vax vars
  input_table$variable[input_table$variable=="vaccination_statusUn-vaccinated (declined)"] = "Unvaccinated (declined)"
  input_table$variable[input_table$variable=="vaccination_statusUn-vaccinated"] = "Unvaccinated"
  input_table$variable[input_table$variable=="vaccination_statusTwo vaccinations"] = "Two vaccinations"
  input_table$variable[input_table$variable=="vaccination_statusThree or more vaccinations"] = "Three or more vaccinations"
  
  #input_table$variable[input_table$variable=="tb_postest_vacc_cat"] = "Time-between test since last vaccination"
  #input_table$variable[input_table$variable=="most_recent_vax_cat"] = "Most recent: vaccination"
  input_table$variable[input_table$variable=="pfizer_most_recent_cov_vacTRUE"] = "Most recent: Pfizer"
  input_table$variable[input_table$variable=="az_most_recent_cov_vacTRUE"] = "Most recent: AstraZeneca"
  input_table$variable[input_table$variable=="moderna_most_recent_cov_vacTRUE"] = "Most recent: Moderna"
  #else
  input_table$variable[input_table$variable=="ns(study_week, df = 3)3"] = "Study week: term3"
  input_table$variable[input_table$variable=="ns(study_week, df = 3)2"] = "Study week: term2"
  input_table$variable[input_table$variable=="ns(study_week, df = 3)1"] = "Study week: term1"
  
  input_table$variable[input_table$variable=="treatment_strategy_cat"] = "Treatment variable"
  input_table$variable[input_table$Variable=="N"] = "N"
  return(input_table)
}
