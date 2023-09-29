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
  
  input_table$variable[input_table$variable=="region_nhsEast Midlands"] = "East Midlands"
  input_table$variable[input_table$variable=="region_nhsWest Midlands"] = "West Midlands"
  input_table$variable[input_table$variable=="region_nhsEast of England"] = "East of England"
  input_table$variable[input_table$variable=="region_nhsYorkshire and the Humber"] = "Yorkshire and the Humber"
  input_table$variable[input_table$variable=="region_nhsNorth West"] = "North West"
  input_table$variable[input_table$variable=="region_nhsNorth East"] = "North East"
  input_table$variable[input_table$variable=="region_nhsSouth East"] = "South East"
  input_table$variable[input_table$variable=="region_nhsSouth West"] = "South West"
  
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
  input_table$variable[input_table$variable=="dialysisTRUE"] = "Dialysis"
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
  input_table$variable[input_table$variable=="ckd_stage_5_nhsdTRUE"] = "Renal disease"
  input_table$variable[input_table$variable=="liver_disease_nhsdTRUE"] = "Liver disease"
  input_table$variable[input_table$variable=="imid_nhsdTRUE"] = "IMID"
  input_table$variable[input_table$variable=="immunosupression_nhsd_newTRUE"] = "Immune deficiencies"
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
  input_table$variable[input_table$variable=="vaccination_statusUnknown"] = "Unknown vaccination status"
  
  input_table$variable[input_table$variable=="tb_postest_vacc_cat< 7 days"] = "Time-between test since last vaccination: < 7 days"
  input_table$variable[input_table$variable=="tb_postest_vacc_cat7-27 days"] = "Time-between test since last vaccination: 7-27 days"
  input_table$variable[input_table$variable=="tb_postest_vacc_cat>= 84 days"] = "Time-between test since last vaccination: >= 84 days"
  input_table$variable[input_table$variable=="tb_postest_vacc_catUnknown"] = "Time-between test since last vaccination: not-vaccinated"
  #else
  input_table$variable[input_table$variable=="ns(period_week, df = 3)3"] = "Study week: term3"
  input_table$variable[input_table$variable=="ns(period_week, df = 3)2"] = "Study week: term2"
  input_table$variable[input_table$variable=="ns(period_week, df = 3)1"] = "Study week: term1"
  
  input_table$variable[input_table$variable=="treatment_strategy_cat"] = "Treatment variable"
  input_table$variable[input_table$variable=="N"] = "N"
  
  
  return(input_table)
}
