# load libraries
library(forcats)
source(here::here("lib", "functions", "fct_case_when.R"))
source(here::here("analysis", "data_import", "functions", "define_status_and_fu_primary.R"))
source(here::here("analysis", "data_import", "functions", "define_status_and_fu_all.R"))
source(here::here("analysis", "data_import", "functions", "add_kidney_vars_to_data.R"))
# function
process_data <- function(data_extracted, study_dates, treat_window_days = 4){
  data_processed <- data_extracted %>%
    mutate(
      # COVARIATES -----
      ageband = cut(
        age,
        breaks = c(18, 40, 60, 80, Inf),
        labels = c("18-39", "40-59", "60-79", "80+"),
        right = FALSE
      ),
      
      sex = fct_case_when(
        sex == "F" ~ "Female",
        sex == "M" ~ "Male",
        TRUE ~ NA_character_
      ),
      
      ethnicity = fct_case_when(
        ethnicity == "0" ~ "Unknown",
        ethnicity == "1" ~ "White",
        ethnicity == "2" ~ "Mixed",
        ethnicity == "3" ~ "Asian or Asian British",
        ethnicity == "4" ~ "Black or Black British",
        ethnicity == "5" ~ "Other ethnic groups",
        TRUE ~ NA_character_),
      
      obese = fct_case_when(
        obese == "Not obese" ~ "Not obese",
        obese == "Obese I (30-34.9)" ~ "Obese I (30-34.9)",
        obese == "Obese II (35-39.9)" ~ "Obese II (35-39.9)",
        obese == "Obese III (40+)" ~ "Obese III (40+)",
        TRUE ~ NA_character_),
      
      smoking_status_comb = fct_case_when(
        smoking_status %in% c("N", "M") ~ "Never and unknown",
        smoking_status == "E" ~ "Former",
        smoking_status == "S" ~ "Current",
        TRUE ~ NA_character_
      ),
      
      smoking_status = fct_case_when(
        smoking_status == "S" ~ "Smoker",
        smoking_status == "E" ~ "Ever",
        smoking_status == "N" ~ "Never",
        smoking_status == "M" ~ "Unknown"),
      
      imdQ5 = fct_case_when(
        imdQ5 == "5 (least deprived)" ~ "5 (least deprived)",
        imdQ5 == "4" ~ "4",
        imdQ5 == "3" ~ "3",
        imdQ5 == "2" ~ "2",
        imdQ5 == "1 (most deprived)" ~ "1 (most deprived)",
        TRUE ~ NA_character_
      ),
      
      region_nhs = fct_case_when(
        region_nhs == "London" ~ "London",
        region_nhs == "East" ~ "East of England",
        region_nhs == "East Midlands" ~ "East Midlands",
        region_nhs == "North East" ~ "North East",
        region_nhs == "North West" ~ "North West",
        region_nhs == "South East" ~ "South East",
        region_nhs == "South West" ~ "South West",
        region_nhs == "West Midlands" ~ "West Midlands",
        region_nhs == "Yorkshire and The Humber" ~ "Yorkshire and the Humber"),
      
      # Rural/urban
      rural_urban = fct_case_when(
        rural_urban %in% c(1:2) ~ "Urban - conurbation",
        rural_urban %in% c(3:4) ~ "Urban - city and town",
        rural_urban %in% c(5:6) ~ "Rural - town and fringe",
        rural_urban %in% c(7:8) ~ "Rural - village and dispersed"
      ),
      
      # STP
      stp = as.factor(stp), 
      
      # Calendar Time
      study_week = difftime(
        covid_test_positive_date,
        study_dates$start_date,
        units = "weeks") %>% 
        as.numeric() %>%
        floor(),
      
      # Time-between positive test and last vaccination
      tb_postest_vacc = 
        if_else(!is.na(date_most_recent_cov_vac),
                difftime(covid_test_positive_date,
                         date_most_recent_cov_vac, units = "days") %>%
                  as.numeric(),
                NA_real_),
      
      tb_postest_vacc_cat = case_when(
        is.na(tb_postest_vacc) ~ "Unknown",
        tb_postest_vacc < 7 ~ "< 7 days",
        tb_postest_vacc >=7 & tb_postest_vacc < 28 ~ "7-27 days",
        tb_postest_vacc >= 28 & tb_postest_vacc < 84 ~ "28-83 days",
        tb_postest_vacc >= 84 ~ ">= 84 days"
      ) %>% factor(
        levels = c("28-83 days", "< 7 days", "7-27 days", ">= 84 days", "Unknown")
      ),
      
      # because want to add dummy var
      tb_postest_vax = 
        fct_recode(tb_postest_vacc_cat,
                   "7" = "< 7 days",
                   "7_27" = "7-27 days",
                   "28_83" = "28-83 days",
                   "84" = ">= 84 days"),
      
      most_recent_vax_cat = fct_case_when(
        pfizer_most_recent_cov_vac == TRUE ~ "Pfizer",
        az_most_recent_cov_vac == TRUE ~ "AstraZeneca",
        moderna_most_recent_cov_vac == TRUE ~ "Moderna",
        !(vaccination_status %in% 
            c("Un-vaccinated", "Un-vaccinated (declined)")) ~ "Other",
        TRUE ~ "Un-vaccinated"),
      
      # TREATMENT ----              
      # Time-between positive test and day of treatment
      tb_postest_treat = 
        if_else(!is.na(date_treated), 
                difftime(date_treated, 
                         covid_test_positive_date, units = "days") %>%
                  as.numeric(),
                NA_real_),
      
      # treatment window
      treat_window = covid_test_positive_date + days(treat_window_days),
      
      # Treatment strategy categories
      # (regardless of treatment is in treat window)
      any_treatment_strategy_cat = 
        case_when(date_treated == 
                    paxlovid_covid_therapeutics ~ "Paxlovid",
                  date_treated == 
                    sotrovimab_covid_therapeutics ~ "Sotrovimab",
                  date_treated == 
                    molnupiravir_covid_therapeutics ~ "Molnupiravir",
                  TRUE ~ "Untreated") %>% 
        factor(levels = c("Untreated", "Paxlovid", "Sotrovimab", "Molnupiravir")),
      
      any_treatment_date =
        if_else(any_treatment_strategy_cat != "Untreated",
                date_treated,
                NA_Date_),
      
      # Flag records where treatment date falls in treatment assignment window
      treat_check = 
        if_else(date_treated >= covid_test_positive_date & 
                  date_treated <= treat_window,
                1,
                0),
      
      # Flag records where treatment date falls after treat_windows
      treat_after_treat_window = 
        if_else(date_treated >= covid_test_positive_date &
                  date_treated > treat_window,
                1,
                0),
      
      # Treatment strategy categories
      treatment_strategy_cat = 
        case_when(date_treated == paxlovid_covid_therapeutics &
                    treat_check == 1 ~ "Paxlovid",
                  date_treated == sotrovimab_covid_therapeutics & 
                    treat_check == 1 ~ "Sotrovimab",
                  date_treated == molnupiravir_covid_therapeutics & 
                    treat_check == 1 ~ "Molnupiravir",
                  TRUE ~ "Untreated") %>% 
        factor(levels = c("Untreated", "Paxlovid", "Sotrovimab", "Molnupiravir")),
      
      # Treatment strategy overall
      treatment = 
        case_when(treatment_strategy_cat %in% 
                    c("Paxlovid", "Sotrovimab", "Molnupiravir") ~ "Treated",
                  TRUE ~ "Untreated") %>%
        factor(levels = c("Untreated", "Treated")),
      
      # Treatment date
      treatment_date = 
        if_else(treatment == "Treated",
                date_treated,
                NA_Date_),
      
      # Identify patients treated with pax and sot or mol on same day
      treated_pax_mol_same_day = 
        case_when(is.na(paxlovid_covid_therapeutics) ~ 0,
                  is.na(molnupiravir_covid_therapeutics) ~ 0,
                  paxlovid_covid_therapeutics == 
                    molnupiravir_covid_therapeutics ~ 1,
                  TRUE ~ 0),
      
      treated_pax_sot_same_day = 
        case_when(is.na(paxlovid_covid_therapeutics) ~ 0,
                  is.na(sotrovimab_covid_therapeutics) ~ 0,
                  paxlovid_covid_therapeutics == 
                    sotrovimab_covid_therapeutics ~ 1,
                  TRUE ~ 0),
      
      creatinine_ctv3 = if_else(creatinine_ctv3 == 0, NA_real_, creatinine_ctv3),
      creatinine_snomed = if_else(creatinine_snomed == 0, NA_real_, creatinine_snomed),
      creatinine_short_snomed = if_else(creatinine_short_snomed == 0, NA_real_, creatinine_short_snomed),
      eGFR_record = if_else(eGFR_record == 0, NA_real_, eGFR_record),
      eGFR_record = if_else(is.na(eGFR_operator) | eGFR_operator == "=", eGFR_record, NA_real_),
      eGFR_short_record = if_else(eGFR_short_record == 0, NA_real_, eGFR_short_record),
      eGFR_short_record = if_else(is.na(eGFR_short_operator) | eGFR_short_operator == "=", eGFR_short_record, NA_real_),
      
    ) %>%
    add_kidney_vars_to_data() %>%
    # add dummy variable tb_postest categories
    pivot_wider(names_from = tb_postest_vax,
                values_from = tb_postest_vax,
                names_prefix = "tb_postest_vax_",
                values_fill = 0,
                values_fn = length) %>%
    mutate(across(starts_with("tb_postest_vax_"), . %>% as.logical())) %>%
    # because makes logic better readable
    rename(covid_death_date = died_ons_covid_any_date) %>%
    mutate(
      # Outcome prep --> outcomes are added in add_*_outcome() functions below
      study_window = covid_test_positive_date + days(28),
      # make distinction between noncovid death and covid death, since noncovid
      # death is a censoring event and covid death is an outcome
      noncovid_death_date = 
        case_when(!is.na(death_date) & is.na(covid_death_date) ~ death_date,
                  TRUE ~ NA_Date_
        ),
      # make distinction between noncovid hosp admission and covid hosp
      # admission, non covid hosp admission is not used as a censoring event in
      # our study, but we'd like to report how many pt were admitted to the 
      # hospital for a noncovid-y reason before one of the other events
      # of note, patients can have allcause (non covid!) hosp before covid hosp, 
      # so the number of noncovid_hosp + covid_hosp is not strictly the number
      # of allcause_hosp
      noncovid_hosp_admission_date =
        case_when(!is.na(allcause_hosp_admission_date) &
                    is.na(covid_hosp_admission_date) ~
                    allcause_hosp_admission_date,
                  (!is.na(allcause_hosp_admission_date) &
                     !is.na(covid_hosp_admission_date)) &
                    allcause_hosp_admission_date != covid_hosp_admission_date ~
                    allcause_hosp_admission_date, # in this case individual can 
                  # have both allcause hosp (not covid!) and covid hosp both
                  # first event for patient and therefore picked up both.
                  # all cause only includes first admissions so noncovid + covid
                  # can exceed number of all cause admissions.
                  TRUE ~ NA_Date_),
    ) %>%
    # adds column status_all and fu_all 
    add_status_and_fu_all() %>%
    # adds column status_primary and fu_primary
    add_status_and_fu_primary() %>%
    # some patients have a record of a hospitalisation that we believe is 
    # associated with sotrovimab infusion, in this study receiving sotrovimab is 
    # a censoring event, however if there is an outcome on the same day as treat
    # ment initiation, outcome is counted. It is therefore important to censor
    # patients receiving sotrovimab and not count their hosp event (which is 
    # believed to be to receive sotrovimab).
    mutate(
      tb_covid_hosp_admission_discharge = 
        if_else(!is.na(covid_hosp_admission_date) & !is.na(covid_hosp_discharge_date), 
                difftime(covid_hosp_discharge_date, 
                         covid_hosp_admission_date, units = "days") %>% as.numeric(),
                NA_real_),
      sot_and_covid_hosp_same_day = 
        if_else(any_treatment_strategy_cat == "Sotrovimab" &
                  status_all == "covid_hosp" &
                  ((min_date_all == any_treatment_date & 
                     (!is.na(tb_covid_hosp_admission_discharge) &
                     tb_covid_hosp_admission_discharge %in% c(0, 1))) |
                     (!is.na(covid_hosp_date_mabs_procedure) &
                       covid_hosp_date_mabs_procedure == any_treatment_date)),
                TRUE,
                FALSE),
      fu_all = 
        if_else(sot_and_covid_hosp_same_day,
                NA_real_,
                fu_all),
      status_all =
        if_else(sot_and_covid_hosp_same_day,
                NA_character_,
                status_all %>% as.character()) %>% factor(),
      fu_primary = 
        if_else(sot_and_covid_hosp_same_day,
                NA_real_,
                fu_primary),
      status_primary = 
        if_else(sot_and_covid_hosp_same_day,
                NA_character_,
                status_primary %>% as.character()) %>% factor()
    ) %>%
    # some patients experience one of our outcomes (prim outcome) 
    # on or before day of treatment --> if so, patients will be categorised as 
    # untreated
    # for more info, see 
    # https://docs.google.com/document/d/1ZPLQ34C0SrXsIrBXy3j9iIlRCfnEEYbEUmgMBx6mv8U/edit#heading=h.sncyl4m0nk5s
    mutate(
      ## PRIMARY ##
      # Treatment strategy categories
      treatment_strategy_cat_prim = 
        if_else(status_primary %in% 
                  c("covid_hosp_death", "noncovid_death", "dereg") &
                  treatment == "Treated" &
                  min_date_primary <= treatment_date,
                "Untreated",
                treatment_strategy_cat %>% as.character()) %>%
        factor(levels = c("Untreated", "Paxlovid", "Sotrovimab", "Molnupiravir")),
      # Treatment strategy overall
      treatment_prim =
        if_else(treatment_strategy_cat_prim == "Untreated",
                "Untreated",
                "Treated") %>%
        factor(levels = c("Untreated", "Treated")),
      # Treatment date
      treatment_date_prim = 
        if_else(treatment_prim == "Treated", treatment_date, NA_Date_),
    )
}