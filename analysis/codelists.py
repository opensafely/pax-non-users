from cohortextractor import (
    codelist,
    codelist_from_csv,
    combine_codelists
)

## HIGH RISK GROUPS ----
downs_syndrome_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-downs-syndrome-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

downs_syndrome_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-downs-syndrome-icd-10.csv",
  system = "icd10",
  column = "code",
)

sickle_cell_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-sickle-spl-atriskv4-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

sickle_cell_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-sickle-spl-hes-icd-10.csv",
  system = "icd10",
  column = "code",
)

non_haematological_cancer_opensafely_snomed_codes = codelist_from_csv(
  "codelists/opensafely-cancer-excluding-lung-and-haematological-snomed.csv",
  system = "snomed",
  column = "id",
)

non_haem_cancer_new_codes = codelist_from_csv(
  "codelists/user-bangzheng-cancer-excluding-lung-and-haematological-snomed-new.csv",
  system = "snomed",
  column = "code"
)

lung_cancer_opensafely_snomed_codes = codelist_from_csv(
  "codelists/opensafely-lung-cancer-snomed.csv", 
  system = "snomed", 
  column = "id"
)

chemotherapy_radiotherapy_opensafely_snomed_codes = codelist_from_csv(
  "codelists/opensafely-chemotherapy-or-radiotherapy-snomed.csv", 
  system = "snomed", 
  column = "id"
)

haematopoietic_stem_cell_transplant_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-haematopoietic-stem-cell-transplant-snomed.csv", 
  system = "snomed", 
  column = "code"
)

haematopoietic_stem_cell_transplant_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-haematopoietic-stem-cell-transplant-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

haematopoietic_stem_cell_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-haematopoietic-stem-cell-transplant-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

haematological_malignancies_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-haematological-malignancies-snomed.csv",
  system = "snomed",
  column = "code"
)

haematological_malignancies_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-haematological-malignancies-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

ckd_stage_5_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-ckd-stage-5-snomed-ct.csv", 
  system = "snomed", 
  column = "code"
)

ckd_stage_5_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-ckd-stage-5-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

liver_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-liver-cirrhosis.csv", 
  system = "snomed", 
  column = "code"
)

liver_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-liver-cirrhosis-icd-10.csv", 
  system = "icd10", 
  column = "code"
)

immunosuppresant_drugs_dmd_codes = codelist_from_csv(
  "codelists/nhsd-immunosuppresant-drugs-pra-dmd.csv", 
  system = "snomed", 
  column = "code"
)

immunosuppresant_drugs_snomed_codes = codelist_from_csv(
  "codelists/nhsd-immunosuppresant-drugs-pra-snomed.csv", 
  system = "snomed", 
  column = "code"
)

oral_steroid_drugs_dmd_codes = codelist_from_csv(
  "codelists/nhsd-oral-steroid-drugs-pra-dmd.csv",
  system = "snomed",
  column = "dmd_id",
)

oral_steroid_drugs_snomed_codes = codelist_from_csv(
  "codelists/nhsd-oral-steroid-drugs-snomed.csv", 
  system = "snomed", 
  column = "code"
)

immunosupression_nhsd_codes = codelist_from_csv(
  "codelists/nhsd-immunosupression-pcdcluster-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

immunosuppression_new_codes = codelist_from_csv(
  "codelists/user-bangzheng-nhsd-immunosupression-pcdcluster-snomed-ct-new.csv",
  system = "snomed",
  column = "code"
)

hiv_aids_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-hiv-aids-snomed.csv", 
  system = "snomed", 
  column = "code"
)

hiv_aids_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-hiv-aids-icd10.csv", 
  system = "icd10", 
  column = "code"
)

solid_organ_transplant_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-transplant-spl-atriskv4-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

solid_organ_transplant_new_codes = codelist_from_csv(
  "codelists/user-bangzheng-nhsd-transplant-spl-atriskv4-snomed-ct-new.csv",
  system = "snomed",
  column = "code"
)

solid_organ_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

thymus_gland_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-thymus-gland-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

replacement_of_organ_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-replacement-of-organ-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

conjunctiva_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-conjunctiva-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

conjunctiva_y_codes_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-conjunctiva-y-codes-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

stomach_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-stomach-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_1_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_1-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_2_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_2-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_1_y_codes_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_1-y-codes-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

ileum_2_y_codes_transplant_nhsd_opcs4_codes = codelist_from_csv(
  "codelists/nhsd-transplant-ileum_2-y-codes-spl-hes-opcs4.csv", 
  system = "opcs4", 
  column = "code"
)

multiple_sclerosis_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-multiple-sclerosis-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

multiple_sclerosis_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-multiple-sclerosis.csv",
  system = "icd10",
  column = "code",
)

motor_neurone_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-motor-neurone-disease-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

motor_neurone_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-motor-neurone-disease-icd-10.csv",
  system = "icd10",
  column = "code",
)

myasthenia_gravis_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-myasthenia-gravis-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

myasthenia_gravis_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-myasthenia-gravis.csv",
  system = "icd10",
  column = "code",
)

huntingtons_disease_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-huntingtons-snomed-ct.csv",
  system = "snomed",
  column = "code",
)

huntingtons_disease_nhsd_icd10_codes = codelist_from_csv(
  "codelists/nhsd-huntingtons.csv",
  system = "icd10",
  column = "code",
) 

# CONTRAINDICATIONS ----
advanced_decompensated_cirrhosis_snomed_codes = codelist_from_csv(
    "codelists/opensafely-condition-advanced-decompensated-cirrhosis-of-the-liver.csv",
    system="snomed",
    column="code"
)

advanced_decompensated_cirrhosis_icd10_codes = codelist_from_csv(
    "codelists/opensafely-condition-advanced-decompensated-cirrhosis-of-the-liver-and-associated-conditions-icd-10.csv",
    system="icd10",
    column="code"
)

ascitic_drainage_snomed_codes = codelist_from_csv(
    "codelists/opensafely-procedure-ascitic-drainage.csv",
    system="snomed",
    column="code"
)

chronic_kidney_disease_stages_3_5_codes = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-ckd35.csv",
    system="snomed",
    column="code",
)

primis_ckd_stage = codelist_from_csv(
    "codelists/user-Louis-ckd-stage.csv",
    system="snomed",
    column="code",
    category_column="stage"
)

ckd3_icd_codes = codelist(["N183"], system="icd10")

ckd4_icd_codes = codelist(["N184"], system="icd10")

ckd5_icd_codes = codelist(["N185"], system="icd10")

dialysis_codes = codelist_from_csv(
  "codelists/opensafely-dialysis.csv",
  system = "ctv3",
  column = "CTV3ID"
)

dialysis_icd10_codelist = codelist_from_csv(
    "codelists/ukrr-dialysis-icd10.csv",
    system="icd10",
    column="code"
)

dialysis_opcs4_codelist = codelist_from_csv(
    "codelists/ukrr-dialysis-opcs-4.csv",
    system="opcs4",
    column="code"
)

kidney_transplant_codes = codelist_from_csv(
  "codelists/opensafely-kidney-transplant.csv",
  system = "ctv3",
  column = "CTV3ID"
)

kidney_tx_icd10_codelist=codelist(["Z940"], system="icd10")

kidney_tx_opcs4_codelist = codelist_from_csv(
    "codelists/user-viyaasan-kidney-transplant-opcs-4.csv",
    system="opcs4",
    column="code"
)

creatinine_codes_ctv3 = codelist(["XE2q5"], system="ctv3")

creatinine_codes_snomed = codelist_from_csv(
    "codelists/user-bangzheng-creatinine-value.csv", system="snomed", column="code"
)

creatinine_codes_short_snomed = codelist_from_csv(
    "codelists/user-bangzheng-creatinine-value-shortlist.csv", system="snomed", column="code"
)

eGFR_level_codelist = codelist_from_csv(
    "codelists/user-ss808-estimated-glomerular-filtration-rate-egfr-values.csv",
    system="snomed",
    column="code",
)

eGFR_short_level_codelist = codelist_from_csv(
    "codelists/user-bangzheng-egfr-value-shortlist.csv",
    system="snomed",
    column="code",
)

solid_organ_transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation-snomed.csv",
    system = "snomed",
    column = "id",
)

drugs_do_not_use_codes = codelist_from_csv(
  "codelists/opensafely-sps-paxlovid-interactions-do-not-use.csv", 
  system = "snomed", 
  column = "code"
)

# CAUTION AGAINST ----
drugs_consider_risk_codes = codelist_from_csv(
  "codelists/opensafely-nirmatrelvir-drug-interactions.csv", 
  system = "snomed", 
  column = "code"
)

## COVARIATES ----
ethnicity_primis_snomed_codes = codelist_from_csv(
  "codelists/primis-covid19-vacc-uptake-eth2001.csv",
  system = "snomed",
  column = "code",
  category_column="grouping_6_id",
)

clear_smoking_codes = codelist_from_csv(
    "codelists/opensafely-smoking-clear.csv",
    system="ctv3",
    column="CTV3Code",
    category_column="Category",
)

chronic_cardiac_dis_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease-snomed.csv",
    system="snomed",
    column="id"
)

chronic_respiratory_dis_codes = codelist_from_csv(
    "codelists/opensafely-chronic-respiratory-disease-snomed.csv",
    system="snomed",
    column="id"
)

serious_mental_illness_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-primary-care-domain-refsets-mh_cod.csv",
  system = "snomed",
  column = "code",
)

wider_ld_primis_snomed_codes = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-learndis.csv", 
    system = "snomed", 
    column = "code"
)

dementia_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-primary-care-domain-refsets-dem_cod.csv", 
  system = "snomed", 
  column = "code",
)

diabetes_codes = codelist_from_csv(
    "codelists/opensafely-diabetes-snomed.csv",
    system="snomed",
    column="id"
)

autism_nhsd_snomed_codes = codelist_from_csv(
  "codelists/nhsd-primary-care-domain-refsets-autism_cod.csv",
  system = "snomed",
  column = "code",
)

care_home_primis_snomed_codes = codelist_from_csv(
    "codelists/primis-covid19-vacc-uptake-longres.csv", 
    system = "snomed", 
    column = "code")

housebound_opensafely_snomed_codes = codelist_from_csv(
    "codelists/opensafely-housebound.csv", 
    system = "snomed", 
    column = "code"
)

no_longer_housebound_opensafely_snomed_codes = codelist_from_csv(
    "codelists/opensafely-no-longer-housebound.csv", 
    system = "snomed", 
    column = "code"
)

hypertension_codes = codelist_from_csv(
    "codelists/opensafely-hypertension-snomed.csv",
    system="snomed",
    column="id"
)

first_dose_declined = codelist_from_csv(
  "codelists/opensafely-covid-19-vaccination-first-dose-declined.csv",
  system = "snomed",
  column = "code",
)

second_dose_declined = codelist_from_csv(
  "codelists/opensafely-covid-19-vaccination-second-dose-declined.csv",
  system = "snomed",
  column = "code",
)

covid_vaccine_declined_codes = combine_codelists(
  first_dose_declined, second_dose_declined
)

## OUTCOMES ----
covid_icd10_codes = codelist_from_csv(
  "codelists/opensafely-covid-identification.csv",
  system = "icd10",
  column = "icd10_code",
)

mabs_procedure_codes = codelist(
  ["X891", "X892"], system="opcs4"
)