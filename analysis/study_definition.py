# Import code building blocks from cohort extractor package
from cohortextractor import (
  StudyDefinition,
  patients,
  filter_codes_by_category,
  combine_codelists,
)

# Import codelists from codelist.py
import codelists
import json

# Define study time variables by importing study-dates
with open('lib/design/study-dates.json', 'r') as f:
    study_dates = json.load(f)
start_date = study_dates["start_date"]
end_date = study_dates["end_date"]

# Define study population
study = StudyDefinition(

  default_expectations={
    "date": {"earliest": start_date, "latest": end_date},
    "rate": "uniform",
    "incidence": 0.05,
  }, 
  
  index_date=start_date,

  population=patients.satisfying(
    """
    age >= 18 AND age < 110
    AND NOT has_died
    AND (sex = "M" OR sex = "F")
    AND NOT stp = ""
    AND imd != -1
    AND high_risk_group
    AND registered_eligible
    AND (
      covid_test_positive
      AND NOT covid_positive_prev_90_days
      AND NOT any_covid_hosp_prev_90_days
      AND NOT prev_treated
      AND NOT in_hospital_when_tested
    )
    """,
  ),

  # We define baseline variables on the day of positive test
  covid_test_positive_date=patients.with_test_result_in_sgss(
    pathogen="SARS-CoV-2",
    test_result="positive",
    find_first_match_in_period=True,
    restrict_to_earliest_specimen_date=False,
    returning="date",
    date_format="YYYY-MM-DD",
    between=["index_date", end_date],
    return_expectations={
      "incidence": 1.0,
      "date": {"earliest": "index_date", "latest": "index_date"},
    },
  ),

  ###################################################################
  # STUDY POPULATION EXCLUSION AND INCLUSION ------------------------
  ###################################################################
  covid_test_positive=patients.with_test_result_in_sgss(
    pathogen="SARS-CoV-2",
    test_result="positive",
    returning="binary_flag",
    between=["index_date", end_date],
    find_first_match_in_period=True,
    restrict_to_earliest_specimen_date=False,
    return_expectations={
      "incidence": 1.0
    },
  ),

  has_died=patients.died_from_any_cause(
    on_or_before="covid_test_positive_date - 1 day",
    returning="binary_flag",
  ),

  registered_eligible=patients.registered_as_of("covid_test_positive_date"),

  # Age [inclusion: between 18 and 110]
  age=patients.age_as_of(
    "covid_test_positive_date",
    return_expectations={
      "rate": "universal",
      "int": {"distribution": "population_ages"},
      "incidence": 0.9
    },
  ),

  # Sex [inclusion: non-missing]
  sex=patients.sex(
    return_expectations={
      "rate": "universal",
      "category": {"ratios": {"M": 0.49, "F": 0.51}},
    }
  ),

  # STP and imd [inclusion: non-missing]
  # STP (NHS administration region based on geography, currenty closest match to CMDU)
  stp=patients.registered_practice_as_of(
    "covid_test_positive_date",
    returning="stp_code",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "STP1": 0.1,
          "STP2": 0.1,
          "STP3": 0.1,
          "STP4": 0.1,
          "STP5": 0.1,
          "STP6": 0.1,
          "STP7": 0.1,
          "STP8": 0.1,
          "STP9": 0.1,
          "STP10": 0.1,
        }
      },
    },
  ),

  imd=patients.address_as_of(
    "covid_test_positive_date",
    returning="index_of_multiple_deprivation",
    round_to_nearest=100,
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0,
          "1": 0.20,
          "2": 0.20,
          "3": 0.20,
          "4": 0.20,
          "5": 0.20,
        }
      },
    },
  ),

  # Previous treatment [inclusion: not prev treated]
  paxlovid_covid_prev=patients.with_covid_therapeutics(
    with_these_therapeutics="Paxlovid",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.01
    },
  ),

  sotrovimab_covid_prev=patients.with_covid_therapeutics(
    with_these_therapeutics="Sotrovimab",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.01
    },
  ),

  remdesivir_covid_prev=patients.with_covid_therapeutics(
    with_these_therapeutics="Remdesivir",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.01
    },
  ),

  molnupiravir_covid_prev=patients.with_covid_therapeutics(
    with_these_therapeutics="Molnupiravir",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    returning="binary_flag",
    date_format="YYYY-MM-DD",
    return_expectations={
      "incidence": 0.01
    },
  ),

  casirivimab_covid_prev=patients.with_covid_therapeutics(
    with_these_therapeutics="Casirivimab and imdevimab",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.01
    },
  ),

  prev_treated=patients.satisfying(
    """
    paxlovid_covid_prev OR
    sotrovimab_covid_prev OR
    remdesivir_covid_prev OR
    molnupiravir_covid_prev OR
    casirivimab_covid_prev
    """,
    return_expectations={
      "incidence": 0.01,
    },
  ),

  covid_positive_prev_90_days=patients.with_test_result_in_sgss(
    pathogen="SARS-CoV-2",
    test_result="positive",
    returning="binary_flag",
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    find_last_match_in_period=True,
    restrict_to_earliest_specimen_date=False,
    return_expectations={
      "incidence": 0.05
    },
  ),

  any_covid_hosp_prev_90_days=patients.admitted_to_hospital(
    with_these_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"],  # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],  # emergency admissions only to exclude incidental COVID
    between=["covid_test_positive_date - 91 days", "covid_test_positive_date - 1 day"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.05
    },
  ),

  in_hospital_when_tested=patients.satisfying(
   "discharged_date > covid_test_positive_date",
   discharged_date=patients.admitted_to_hospital(
      returning="date_discharged",
      on_or_before="covid_test_positive_date",
      with_patient_classification=["1"],  # ordinary admissions only - exclude day cases and regular attenders
      # see https://github.com/opensafely-core/cohort-extractor/pull/497 for codes
      # see https://docs.opensafely.org/study-def-variables/#sus for more info
      with_admission_method=["21", "22", "23", "24", "25", "2A", "2B", "2C", "2D", "28"],  # emergency admissions only to exclude incidental COVID
      find_last_match_in_period=True,
   ),
   return_expectations={"incidence": 0.05}
  ),

  # High risk groups
  # Blueteq ‘high risk’ cohort (useful for validating ehr high risk groups)
  high_risk_cohort_covid_therapeutics=patients.with_covid_therapeutics(
    with_these_therapeutics=["Sotrovimab", "Molnupiravir","Casirivimab and imdevimab", "Paxlovid", "Remdesivir"],
    with_these_indications="non_hospitalised",
    on_or_after="covid_test_positive_date",
    find_first_match_in_period=True,
    returning="risk_group",
    date_format="YYYY-MM-DD",
    return_expectations={
      "rate": "universal",
      "incidence": 0.4,
      "category": {
        "ratios": {
          "Downs syndrome": 0.1,
          "sickle cell disease": 0.1,
          "solid cancer": 0.1,
          "haematological diseases,stem cell transplant recipients": 0.1,
          "renal disease,sickle cell disease": 0.1,
          "liver disease": 0.05,
          "IMID": 0.1,
          "IMID,solid cancer": 0.1,
          "haematological malignancies": 0.05,
          "primary immune deficiencies": 0.1,
          "HIV or AIDS": 0.05,
          "NA": 0.05,
        },
      },
    },
  ),

  # Definition of high risk using regular codelists [inclusion: in one of these]
  # Down's syndrome
  downs_syndrome_nhsd_snomed=patients.with_these_clinical_events(
    codelists.downs_syndrome_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.05
    },
  ),

  downs_syndrome_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.downs_syndrome_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.05
    },
  ),

  downs_syndrome_nhsd=patients.satisfying(
    "downs_syndrome_nhsd_snomed OR downs_syndrome_nhsd_icd10",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  # Solid cancer
  cancer_opensafely_snomed=patients.with_these_clinical_events(
    combine_codelists(
      codelists.non_haematological_cancer_opensafely_snomed_codes,
      codelists.lung_cancer_opensafely_snomed_codes,
      codelists.chemotherapy_radiotherapy_opensafely_snomed_codes
    ),
    between=["covid_test_positive_date - 6 months", "covid_test_positive_date"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  cancer_opensafely_snomed_new=patients.with_these_clinical_events(
    combine_codelists(
      codelists.non_haem_cancer_new_codes,
      codelists.lung_cancer_opensafely_snomed_codes,
      codelists.chemotherapy_radiotherapy_opensafely_snomed_codes
    ),
    between=["covid_test_positive_date - 6 months", "covid_test_positive_date"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  # Haematological diseases
  haematopoietic_stem_cell_transplant_nhsd_snomed=patients.with_these_clinical_events(
    codelists.haematopoietic_stem_cell_transplant_nhsd_snomed_codes,
    between=["covid_test_positive_date - 12 months", "covid_test_positive_date"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  haematopoietic_stem_cell_transplant_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    between=["covid_test_positive_date - 12 months", "covid_test_positive_date"],
    with_these_diagnoses=codelists.haematopoietic_stem_cell_transplant_nhsd_icd10_codes,
    find_last_match_in_period=True,
    return_expectations={
      "incidence": 0.4
    },
  ),

  haematopoietic_stem_cell_transplant_nhsd_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    between=["covid_test_positive_date - 12 months", "covid_test_positive_date"],
    with_these_procedures=codelists.haematopoietic_stem_cell_transplant_nhsd_opcs4_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  haematological_malignancies_nhsd_snomed=patients.with_these_clinical_events(
    codelists.haematological_malignancies_nhsd_snomed_codes,
    between=["covid_test_positive_date - 24 months", "covid_test_positive_date"],
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  haematological_malignancies_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    between=["covid_test_positive_date - 24 months", "covid_test_positive_date"],
    with_these_diagnoses=codelists.haematological_malignancies_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  sickle_cell_disease_nhsd_snomed=patients.with_these_clinical_events(
    codelists.sickle_cell_disease_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  sickle_cell_disease_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.sickle_cell_disease_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  haematological_disease_nhsd=patients.satisfying(
    """
    haematopoietic_stem_cell_transplant_nhsd_snomed OR
    haematopoietic_stem_cell_transplant_nhsd_icd10 OR
    haematopoietic_stem_cell_transplant_nhsd_opcs4 OR
    haematological_malignancies_nhsd_snomed OR
    haematological_malignancies_nhsd_icd10 OR
    sickle_cell_disease_nhsd_snomed OR
    sickle_cell_disease_nhsd_icd10
    """,
    return_expectations={
      "incidence": 0.05,
    },
  ),

  # Renal disease
  ckd_stage_5_nhsd_snomed=patients.with_these_clinical_events(
    codelists.ckd_stage_5_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  ckd_stage_5_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.ckd_stage_5_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  ckd_stage_5_nhsd=patients.satisfying(
    "ckd_stage_5_nhsd_snomed OR ckd_stage_5_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Liver disease
  liver_disease_nhsd_snomed=patients.with_these_clinical_events(
    codelists.liver_disease_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.05
    },
  ),

  liver_disease_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.liver_disease_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.05
    },
  ),

  liver_disease_nhsd=patients.satisfying(
    "liver_disease_nhsd_snomed OR liver_disease_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Immune-mediated inflammatory disorders (IMID)
  immunosuppresant_drugs_nhsd=patients.with_these_medications(
    codelist=combine_codelists(
      codelists.immunosuppresant_drugs_dmd_codes, 
      codelists.immunosuppresant_drugs_snomed_codes),
    returning="binary_flag",
    between=["covid_test_positive_date - 6 months", "covid_test_positive_date"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  oral_steroid_drugs_nhsd=patients.with_these_medications(
    codelist=combine_codelists(
      codelists.oral_steroid_drugs_dmd_codes,
      codelists.oral_steroid_drugs_snomed_codes),
    returning="binary_flag",
    between=["covid_test_positive_date - 12 months", "covid_test_positive_date"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  oral_steroid_drug_nhsd_3m_count=patients.with_these_medications(
    codelist=combine_codelists(
      codelists.oral_steroid_drugs_dmd_codes,
      codelists.oral_steroid_drugs_snomed_codes),
    returning="number_of_matches_in_period",
    between=["covid_test_positive_date - 3 months", "covid_test_positive_date"],
    return_expectations={
      "incidence": 0.1,
      "int": {"distribution": "normal", "mean": 2, "stddev": 1},
    },
  ),

  oral_steroid_drug_nhsd_12m_count=patients.with_these_medications(
    codelist=combine_codelists(
      codelists.oral_steroid_drugs_dmd_codes,
      codelists.oral_steroid_drugs_snomed_codes),
    returning="number_of_matches_in_period",
    between=["covid_test_positive_date - 12 months", "covid_test_positive_date"],
    return_expectations={
      "incidence": 0.1,
      "int": {"distribution": "normal", "mean": 3, "stddev": 1},
    },
  ),

  oral_steroid_drugs_nhsd2=patients.satisfying(
    """
    oral_steroid_drugs_nhsd AND
    (oral_steroid_drug_nhsd_3m_count >=2 AND
    oral_steroid_drug_nhsd_12m_count >=4)
    """,
    return_expectations={
      "incidence": 0.05
    },
  ),

  imid_nhsd=patients.satisfying(
    "immunosuppresant_drugs_nhsd OR oral_steroid_drugs_nhsd2",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Primary immune deficiencies
  immunosupression_nhsd=patients.with_these_clinical_events(
    codelists.immunosupression_nhsd_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  immunosupression_nhsd_new=patients.with_these_clinical_events(
    codelists.immunosuppression_new_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  # HIV/AIDs
  hiv_aids_nhsd_snomed=patients.with_these_clinical_events(
    codelists.hiv_aids_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  hiv_aids_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.hiv_aids_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  hiv_aids_nhsd=patients.satisfying(
    "hiv_aids_nhsd_snomed OR hiv_aids_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Solid organ transplant
  solid_organ_transplant_nhsd_snomed=patients.with_these_clinical_events(
    codelists.solid_organ_transplant_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  solid_organ_transplant_nhsd_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_procedures=codelists.solid_organ_transplant_nhsd_opcs4_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  transplant_all_y_codes_opcs4=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_procedures=codelists.replacement_of_organ_transplant_nhsd_opcs4_codes,
    on_or_before="covid_test_positive_date",
    date_format="YYYY-MM-DD",
    find_last_match_in_period=True,
    return_expectations={
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),

  transplant_thymus_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    with_these_procedures=codelists.thymus_gland_transplant_nhsd_opcs4_codes,
    between=["transplant_all_y_codes_opcs4","transplant_all_y_codes_opcs4"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  transplant_conjunctiva_y_code_opcs4=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_procedures=codelists.conjunctiva_y_codes_transplant_nhsd_opcs4_codes,
    on_or_before="covid_test_positive_date",
    date_format="YYYY-MM-DD",
    find_last_match_in_period=True,
    return_expectations={
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),

  transplant_conjunctiva_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    with_these_procedures=codelists.conjunctiva_transplant_nhsd_opcs4_codes,
    between=["transplant_conjunctiva_y_code_opcs4","transplant_conjunctiva_y_code_opcs4"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  transplant_stomach_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    with_these_procedures=codelists.stomach_transplant_nhsd_opcs4_codes,
    between=["transplant_all_y_codes_opcs4","transplant_all_y_codes_opcs4"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  transplant_ileum_1_Y_codes_opcs4=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_procedures=codelists.ileum_1_y_codes_transplant_nhsd_opcs4_codes,
    on_or_before="covid_test_positive_date",
    date_format="YYYY-MM-DD",
    find_last_match_in_period=True,
    return_expectations={
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),

  transplant_ileum_2_Y_codes_opcs4=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_procedures=codelists.ileum_1_y_codes_transplant_nhsd_opcs4_codes,
    on_or_before="covid_test_positive_date",
    date_format="YYYY-MM-DD",
    find_last_match_in_period=True,
    return_expectations={
      "date": {"earliest": "2020-02-01"},
      "rate": "exponential_increase",
      "incidence": 0.01,
    },
  ),

  transplant_ileum_1_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    with_these_procedures=codelists.ileum_1_transplant_nhsd_opcs4_codes,
    between=["transplant_ileum_1_Y_codes_opcs4","transplant_ileum_1_Y_codes_opcs4"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  transplant_ileum_2_opcs4=patients.admitted_to_hospital(
    returning="binary_flag",
    with_these_procedures=codelists.ileum_2_transplant_nhsd_opcs4_codes,
    between=["transplant_ileum_2_Y_codes_opcs4","transplant_ileum_2_Y_codes_opcs4"],
    return_expectations={
      "incidence": 0.4
    },
  ),

  solid_organ_transplant_nhsd=patients.satisfying(
    """
    solid_organ_transplant_nhsd_snomed OR
    solid_organ_transplant_nhsd_opcs4 OR
    transplant_thymus_opcs4 OR
    transplant_conjunctiva_opcs4 OR
    transplant_stomach_opcs4 OR
    transplant_ileum_1_opcs4 OR
    transplant_ileum_2_opcs4
    """,
    return_expectations={
      "incidence": 0.05
    },
  ),

  solid_organ_transplant_nhsd_snomed_new=patients.with_these_clinical_events(
    codelists.solid_organ_transplant_new_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  solid_organ_transplant_nhsd_new=patients.satisfying(
    """
    solid_organ_transplant_nhsd_snomed_new OR
    solid_organ_transplant_nhsd_opcs4 OR
    transplant_thymus_opcs4 OR
    transplant_conjunctiva_opcs4 OR
    transplant_stomach_opcs4 OR
    transplant_ileum_1_opcs4 OR
    transplant_ileum_2_opcs4
    """,
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Rare neurological conditions
  # Multiple sclerosis
  multiple_sclerosis_nhsd_snomed=patients.with_these_clinical_events(
    codelists.multiple_sclerosis_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  multiple_sclerosis_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.multiple_sclerosis_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  multiple_sclerosis_nhsd=patients.satisfying(
    "multiple_sclerosis_nhsd_snomed OR multiple_sclerosis_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Motor neurone disease
  motor_neurone_disease_nhsd_snomed=patients.with_these_clinical_events(
    codelists.motor_neurone_disease_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  motor_neurone_disease_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.motor_neurone_disease_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  motor_neurone_disease_nhsd=patients.satisfying(
    "motor_neurone_disease_nhsd_snomed OR motor_neurone_disease_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Myasthenia gravis
  myasthenia_gravis_nhsd_snomed=patients.with_these_clinical_events(
    codelists.myasthenia_gravis_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  myasthenia_gravis_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.myasthenia_gravis_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  myasthenia_gravis_nhsd=patients.satisfying(
    "myasthenia_gravis_nhsd_snomed OR myasthenia_gravis_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # Huntington’s disease
  huntingtons_disease_nhsd_snomed=patients.with_these_clinical_events(
    codelists.huntingtons_disease_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ),

  huntingtons_disease_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.huntingtons_disease_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
    },
  ),

  huntingtons_disease_nhsd=patients.satisfying(
    "huntingtons_disease_nhsd_snomed OR huntingtons_disease_nhsd_icd10",
    return_expectations={
      "incidence": 0.05
    },
  ),

  # High risk ehr recorded
  high_risk_group=patients.satisfying(
    """
    huntingtons_disease_nhsd OR
    myasthenia_gravis_nhsd OR
    motor_neurone_disease_nhsd OR
    multiple_sclerosis_nhsd OR
    solid_organ_transplant_nhsd OR
    hiv_aids_nhsd OR
    immunosupression_nhsd OR
    imid_nhsd OR
    liver_disease_nhsd OR
    ckd_stage_5_nhsd OR
    haematological_disease_nhsd OR
    cancer_opensafely_snomed OR
    downs_syndrome_nhsd
    """,
    return_expectations={
      "incidence": 1.0
    },
  ),

  ###################################################################
  # CONTRAINDICATIONS FOR PAXLOVID ----------------------------------
  ###################################################################
  advanced_decompensated_cirrhosis=patients.with_these_clinical_events(
    codelists.advanced_decompensated_cirrhosis_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    find_last_match_in_period=True,
  ),

  decompensated_cirrhosis_icd10=patients.admitted_to_hospital(
    with_these_diagnoses=codelists.advanced_decompensated_cirrhosis_icd10_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    find_last_match_in_period=True,
  ),

  # regular ascitic drainage (opcs4_codes in hospital??)
  ascitic_drainage_snomed=patients.with_these_clinical_events(
    codelists.ascitic_drainage_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    include_date_of_match=True,
    find_last_match_in_period=True,
    date_format="YYYY-MM-DD",
  ), 

  ## CKD DEFINITIONS - adapted from https://github.com/opensafely/risk-factors-research
  # new codelist see https://github.com/opensafely/codelist-development/issues/267#event-9788015642
  ckd_primis_stage=patients.with_these_clinical_events(
    codelist=codelists.primis_ckd_stage,
    on_or_before="covid_test_positive_date",
    returning="category",
    find_last_match_in_period=True,
    return_expectations={
      "rate": "universal",
      "category": {
          "ratios": {
              "1": 0.4, 
              "2": 0.45,
              "3": 0.05,
              "4": 0.05,
              "5": 0.05
            }
      },
    },
  ),

  ckd3_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.ckd3_icd_codes,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  ckd4_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.ckd4_icd_codes,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  ckd5_icd10 = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.ckd5_icd_codes,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),    

  dialysis = patients.with_these_clinical_events(
    codelists.dialysis_codes,
    on_or_before ="covid_test_positive_date",
    returning = "binary_flag",
    find_last_match_in_period = True,
    return_expectations={
      "incidence": 0.05,
    },
  ),

  dialysis_icd10 = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.dialysis_icd10_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  dialysis_procedure = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_procedures=codelists.dialysis_opcs4_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),  

  kidney_transplant = patients.with_these_clinical_events(
    codelists.kidney_transplant_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    find_last_match_in_period=True,
    return_expectations={
      "incidence": 0.05,
    },    
  ),

  kidney_transplant_icd10 = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.kidney_tx_icd10_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  kidney_transplant_procedure=patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_procedures=codelists.kidney_tx_opcs4_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  #  3-5 CKD based on recorded creatinine value
  creatinine_ctv3=patients.with_these_clinical_events(
    codelists.creatinine_codes_ctv3,
    find_last_match_in_period=True,
    on_or_before="covid_test_positive_date",
    returning="numeric_value",
    include_date_of_match=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "float": {"distribution": "normal", "mean": 45.0, "stddev": 20},
      "incidence": 0.5,
    },
  ),

  creatinine_operator_ctv3=patients.comparator_from(
    "creatinine_ctv3",
    return_expectations={
       "rate": "universal",
       "category": {
         "ratios": {  # ~, =, >=, >, <, <=
            None: 0.10,
            "~": 0.05,
            "=": 0.65,
            ">=": 0.05,
            ">": 0.05,
            "<": 0.05,
            "<=": 0.05,
         },
       },
       "incidence": 0.80,
    },
  ),

  age_creatinine_ctv3=patients.age_as_of(
    "creatinine_ctv3_date",
    return_expectations = {
      "rate": "universal",
      "int": {"distribution": "population_ages"},
    },
  ),

  creatinine_snomed=patients.with_these_clinical_events(
    codelist=codelists.creatinine_codes_snomed,
    find_last_match_in_period=True,
    on_or_before="covid_test_positive_date",
    returning="numeric_value",
    include_date_of_match=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "float": {"distribution": "normal", "mean": 45.0, "stddev": 20},
      "incidence": 0.5,
    },
  ),

  creatinine_operator_snomed=patients.comparator_from(
    "creatinine_snomed",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {  # ~, =, >= , > , < , <=
          None: 0.10,
          "~": 0.05,
          "=": 0.65,
          ">=": 0.05,
          ">": 0.05,
          "<": 0.05,
          "<=": 0.05,
        }
      },
    "incidence": 0.80,
    },
  ),  

  age_creatinine_snomed=patients.age_as_of(
    "creatinine_snomed_date",
    return_expectations = {
      "rate": "universal",
      "int": {"distribution": "population_ages"},
    },
  ),  

  creatinine_short_snomed=patients.with_these_clinical_events(
    codelist=codelists.creatinine_codes_short_snomed,
    find_last_match_in_period=True,
    on_or_before ="covid_test_positive_date",
    returning="numeric_value",
    include_date_of_match=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "float": {"distribution": "normal", "mean": 45.0, "stddev": 20},
      "incidence": 0.5,
    },
  ),

  creatinine_operator_short_snomed=patients.comparator_from(
    "creatinine_short_snomed",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {  # ~, =, >= , > , < , <=
          None: 0.10,
          "~": 0.05,
          "=": 0.65,
          ">=": 0.05,
          ">": 0.05,
          "<": 0.05,
          "<=": 0.05,
        }
      },
    "incidence": 0.80,
    },
  ),  

  age_creatinine_short_snomed=patients.age_as_of(
    "creatinine_short_snomed_date",
    return_expectations={
      "rate": "universal",
      "int": {"distribution": "population_ages"},
    },
  ),    

  #  3-5 CKD based on recorded eGFR value
  eGFR_record=patients.with_these_clinical_events(
    codelist=codelists.eGFR_level_codelist,
    find_last_match_in_period=True,
    on_or_before ="covid_test_positive_date",
    returning="numeric_value",
    return_expectations={
      "float": {"distribution": "normal", "mean": 70, "stddev": 30},
      "incidence": 0.2,
    },
  ),

  eGFR_operator=patients.comparator_from(
    "eGFR_record",
    return_expectations={
      "rate": "universal",
      "category": {
      "ratios": {  # ~, =, >= , > , < , <=
        None: 0.10,
        "~": 0.05,
        "=": 0.65,
        ">=": 0.05,
        ">": 0.05,
        "<": 0.05,
        "<=": 0.05,
      }
    },
    "incidence": 0.80,
    },
  ),  

  eGFR_short_record=patients.with_these_clinical_events(
    codelist=codelists.eGFR_short_level_codelist,
    find_last_match_in_period=True,
    on_or_before ="covid_test_positive_date",
    returning="numeric_value",
    return_expectations={
      "float": {"distribution": "normal", "mean": 70, "stddev": 30},
      "incidence": 0.2,
    },
  ),

  eGFR_short_operator=patients.comparator_from(
    "eGFR_short_record",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {  # ~, =, >= , > , < , <=
          None: 0.10,
          "~": 0.05,
          "=": 0.65,
          ">=": 0.05,
          ">": 0.05,
          "<": 0.05,
          "<=": 0.05,
        }
      },
    "incidence": 0.80,
    },
  ),

  solid_organ_transplant_snomed=patients.with_these_clinical_events(
    codelist=codelists.solid_organ_transplant_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    find_last_match_in_period=True,
  ),

  ### contraindicated medication
  drugs_do_not_use=patients.with_these_medications(
    codelist=codelists.drugs_do_not_use_codes,
    returning="binary_flag",
    between=["covid_test_positive_date - 180 days", "covid_test_positive_date"],
    find_last_match_in_period=True,
    return_expectations={
      "incidence": 0.05,
    },
  ),

  ###################################################################
  # CAUTION AGAINST PAXLOVID ----------------------------------------
  ###################################################################
  # drugs considering risks and benefits
  drugs_consider_risk=patients.with_these_medications(
    codelist=codelists.drugs_consider_risk_codes,
    returning="binary_flag",
    between=["covid_test_positive_date - 180 days", "covid_test_positive_date"],
    find_last_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "incidence": 0.05,
    },
  ),

  ###################################################################
  # TREATMENT - NEUTRALISING MONOCLONAL ANTIBODIES OR ANTIVIRALS ----
  ###################################################################
  paxlovid_covid_therapeutics=patients.with_covid_therapeutics(
    with_these_therapeutics="Paxlovid",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date", end_date],
    find_first_match_in_period=True,
    returning="date",
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date"},
      "incidence": 0.05
    },
  ),

  sotrovimab_covid_therapeutics=patients.with_covid_therapeutics(
    with_these_therapeutics="Sotrovimab",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date", end_date],
    find_first_match_in_period=True,
    returning="date",
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date"},
      "incidence": 0.5
    },
  ),

  remdesivir_covid_therapeutics=patients.with_covid_therapeutics(
    with_these_therapeutics="Remdesivir",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date", end_date],
    find_first_match_in_period=True,
    returning="date",
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date"},
      "incidence": 0.2
    },
  ),

  molnupiravir_covid_therapeutics=patients.with_covid_therapeutics(
    with_these_therapeutics="Molnupiravir",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date", end_date],
    find_first_match_in_period=True,
    returning="date",
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date"},
      "incidence": 0.5
    },
  ),

  casirivimab_covid_therapeutics=patients.with_covid_therapeutics(
    with_these_therapeutics="Casirivimab and imdevimab",
    with_these_indications="non_hospitalised",
    between=["covid_test_positive_date", end_date],
    find_first_match_in_period=True,
    returning="date",
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date"},
      "incidence": 0.05
    },
  ),

  date_treated=patients.minimum_of(
    "paxlovid_covid_therapeutics",
    "sotrovimab_covid_therapeutics",
    "remdesivir_covid_therapeutics",
    "molnupiravir_covid_therapeutics",
    "casirivimab_covid_therapeutics",
  ),

  ###################################################################
  # COVARIATES ------------------------------------------------------
  ###################################################################

  ethnicity_primis=patients.with_these_clinical_events(
    codelists.ethnicity_primis_snomed_codes,
    returning="category",
    on_or_before="covid_test_positive_date",
    find_first_match_in_period=True,
    include_date_of_match=False,
    return_expectations={
      "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
      "incidence": 0.75,
    },
  ),

  ethnicity_sus=patients.with_ethnicity_from_sus(
    returning="group_6",  
    use_most_frequent_code=True,
    return_expectations={
      "category": {"ratios": {"1": 0.2, "2": 0.2, "3": 0.2, "4": 0.2, "5": 0.2}},
      "incidence": 0.8,
    },
  ),

  ethnicity=patients.categorised_as(
    {
      "0": "DEFAULT",
      "1": "ethnicity_primis='1' OR (NOT ethnicity_primis AND ethnicity_sus='1')",
      "2": "ethnicity_primis='2' OR (NOT ethnicity_primis AND ethnicity_sus='2')",
      "3": "ethnicity_primis='3' OR (NOT ethnicity_primis AND ethnicity_sus='3')",
      "4": "ethnicity_primis='4' OR (NOT ethnicity_primis AND ethnicity_sus='4')",
      "5": "ethnicity_primis='5' OR (NOT ethnicity_primis AND ethnicity_sus='5')",
    },
    return_expectations={
      "category": {
        "ratios": {
            "0": 0.5,  # missing in 50%
            "1": 0.1,
            "2": 0.1,
            "3": 0.1,
            "4": 0.1,
            "5": 0.1
        }
      },
      "incidence": 1.0,
    },
  ),

  # https://docs.opensafely.org/study-def-tricks/#grouping-imd-by-quintile
  imdQ5=patients.categorised_as(
    {
      "0": "DEFAULT",
      "1 (most deprived)": "imd >= 0 AND imd < 32800*1/5",
      "2": "imd >= 32800*1/5 AND imd < 32800*2/5",
      "3": "imd >= 32800*2/5 AND imd < 32800*3/5",
      "4": "imd >= 32800*3/5 AND imd < 32800*4/5",
      "5 (least deprived)": "imd >= 32800*4/5 AND imd <= 32800",
    },
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "0": 0,
          "1 (most deprived)": 0.20,
          "2": 0.20,
          "3": 0.20,
          "4": 0.20,
          "5 (least deprived)": 0.20,
        }
      },
    },
  ),

  rural_urban=patients.address_as_of(
    "covid_test_positive_date",
    returning="rural_urban_classification",
    return_expectations={
      "rate": "universal",
      "category": {
          "ratios": {
            1: 0.125,
            2: 0.125, 
            3: 0.125, 
            4: 0.125, 
            5: 0.125, 
            6: 0.125, 
            7: 0.125, 
            8: 0.125},},
      "incidence": 1,
    },
  ),

  region_nhs=patients.registered_practice_as_of(
    "covid_test_positive_date",
    returning="nuts1_region_name",
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "North East": 0.1,
          "North West": 0.1,
          "Yorkshire and The Humber": 0.1,
          "East Midlands": 0.1,
          "West Midlands": 0.1,
          "East": 0.1,
          "London": 0.2,
          "South West": 0.1,
          "South East": 0.1,},},
    },
  ),

  smoking_status=patients.categorised_as(
    {
      "S": "most_recent_smoking_code = 'S'",
      "E": """
        most_recent_smoking_code = 'E' OR (
        most_recent_smoking_code = 'N' AND ever_smoked)
           """,
      "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
      "M": "DEFAULT",
    },
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "S": 0.6,
          "E": 0.1,
          "N": 0.2,
          "M": 0.1,
        }
      },
    },
    most_recent_smoking_code=patients.with_these_clinical_events(
      codelists.clear_smoking_codes,
      find_last_match_in_period=True,
      on_or_before="covid_test_positive_date",
      returning="category",
    ),
    ever_smoked=patients.with_these_clinical_events(
      filter_codes_by_category(codelists.clear_smoking_codes, include=["S", "E"]),
      on_or_before="covid_test_positive_date",
    ),
  ),

  chronic_cardiac_disease=patients.with_these_clinical_events(
    codelists.chronic_cardiac_dis_codes,
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    find_last_match_in_period=True,
  ),

  copd=patients.with_these_clinical_events(
    codelists.chronic_respiratory_dis_codes,
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    find_last_match_in_period=True,
  ),

  # set maximum to avoid any impossibly extreme values being classified as obese
  bmi_value=patients.most_recent_bmi(
    on_or_after="covid_test_positive_date - 5 years",
    minimum_age_at_measurement=16,
    return_expectations={
      "date": {"latest": "today"},
      "float": {"distribution": "normal", "mean": 25.0, "stddev": 7.5},
      "incidence": 0.8,
    },
  ),

  obese=patients.categorised_as(
    {
      "Not obese": "DEFAULT",
      "Obese I (30-34.9)": """ bmi_value >= 30 AND bmi_value < 35""",
      "Obese II (35-39.9)": """ bmi_value >= 35 AND bmi_value < 40""",
      "Obese III (40+)": """ bmi_value >= 40 AND bmi_value < 100""",
    },
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "Not obese": 0.7,
          "Obese I (30-34.9)": 0.1,
          "Obese II (35-39.9)": 0.1,
          "Obese III (40+)": 0.1,
        }
      },
      "incidence": 1.0,
    },
  ),

  serious_mental_illness_nhsd=patients.with_these_clinical_events(
    codelists.serious_mental_illness_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={"incidence": 0.1}
  ),

  learning_disability_primis=patients.with_these_clinical_events(
    codelists.wider_ld_primis_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={"incidence": 0.2}
  ),

  dementia_nhsd=patients.satisfying(
    """
    dementia_all
    AND
    age > 39
    """, 
    return_expectations={
      "incidence": 0.01,
    },
    dementia_all=patients.with_these_clinical_events(
      codelists.dementia_nhsd_snomed_codes,
      on_or_before="covid_test_positive_date",
      returning="binary_flag",
      return_expectations={"incidence": 0.05}
    ),
  ),

  diabetes=patients.with_these_clinical_events(
    codelists.diabetes_codes,
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    find_last_match_in_period=True,
  ),

  autism_nhsd=patients.with_these_clinical_events(
    codelists.autism_nhsd_snomed_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={"incidence": 0.3}
  ),

  care_home_primis=patients.with_these_clinical_events(
    codelists.care_home_primis_snomed_codes,
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    return_expectations={"incidence": 0.15,}
  ),

  housebound_opensafely=patients.satisfying(
    """
    housebound_date
    AND NOT no_longer_housebound
    AND NOT moved_into_care_home
    """,
    return_expectations={
      "incidence": 0.01,
    },
    housebound_date=patients.with_these_clinical_events( 
      codelists.housebound_opensafely_snomed_codes, 
      on_or_before="covid_test_positive_date",
      find_last_match_in_period=True,
      returning="date",
      date_format="YYYY-MM-DD",
    ),   
    no_longer_housebound=patients.with_these_clinical_events( 
      codelists.no_longer_housebound_opensafely_snomed_codes, 
      on_or_after="housebound_date",
    ),
    moved_into_care_home=patients.with_these_clinical_events(
      codelists.care_home_primis_snomed_codes,
      on_or_after="housebound_date",
    ),
  ),

  hypertension=patients.with_these_clinical_events(
    codelists.hypertension_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    return_expectations={"incidence": 0.1, },
  ),

  vaccination_status=patients.categorised_as(
    {
      "Un-vaccinated": "DEFAULT",
      "Un-vaccinated (declined)": """ covid_vax_declined AND NOT (covid_vax_1 OR covid_vax_2 OR covid_vax_3)""",
      "One vaccination": """ covid_vax_1 AND NOT covid_vax_2 """,
      "Two vaccinations": """ covid_vax_2 AND NOT covid_vax_3 """,
      "Three or more vaccinations": """ covid_vax_3 """
    },
    # first vaccine from during trials and up to treatment/test date
    covid_vax_1=patients.with_tpp_vaccination_record(
      target_disease_matches="SARS-2 CORONAVIRUS",
      between=["2020-06-08", "covid_test_positive_date"],
      find_first_match_in_period=True,
      returning="date",
      date_format="YYYY-MM-DD"
    ),
    covid_vax_2=patients.with_tpp_vaccination_record(
      target_disease_matches="SARS-2 CORONAVIRUS",
      between=["covid_vax_1 + 19 days", "covid_test_positive_date"],
      find_first_match_in_period=True,
      returning="date",
      date_format="YYYY-MM-DD"
    ),
    covid_vax_3=patients.with_tpp_vaccination_record(
      target_disease_matches="SARS-2 CORONAVIRUS",
      between=["covid_vax_2 + 56 days", "covid_test_positive_date"],
      find_first_match_in_period=True,
      returning="date",
      date_format="YYYY-MM-DD"
    ),
    covid_vax_declined=patients.with_these_clinical_events(
      codelists.covid_vaccine_declined_codes,
      returning="binary_flag",
      on_or_before="covid_test_positive_date",
    ),
    return_expectations={
      "rate": "universal",
      "category": {
        "ratios": {
          "Un-vaccinated": 0.1,
          "Un-vaccinated (declined)": 0.1,
          "One vaccination": 0.1,
          "Two vaccinations": 0.2,
          "Three or more vaccinations": 0.5,
        }
      },
    },
  ),

  date_most_recent_cov_vac=patients.with_tpp_vaccination_record(
    target_disease_matches="SARS-2 CORONAVIRUS",
    between=["2020-06-08", "covid_test_positive_date"],
    find_last_match_in_period=True,
    returning="date",
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date", "latest": end_date},
    },
  ),

  pfizer_most_recent_cov_vac=patients.with_tpp_vaccination_record(
    product_name_matches="COVID-19 mRNA Vaccine Comirnaty 30micrograms/0.3ml dose conc for susp for inj MDV (Pfizer)",
    between=["date_most_recent_cov_vac", "date_most_recent_cov_vac"],
    find_last_match_in_period=True,
    returning="binary_flag",
    return_expectations={
      "incidence": 0.4
    },
  ), 

  az_most_recent_cov_vac=patients.with_tpp_vaccination_record(
    product_name_matches="COVID-19 Vaccine Vaxzevria 0.5ml inj multidose vials (AstraZeneca)",
    between=["date_most_recent_cov_vac", "date_most_recent_cov_vac"],
    find_last_match_in_period=True,
    returning="binary_flag",
    return_expectations={
      "incidence": 0.5
    },
  ),

  moderna_most_recent_cov_vac=patients.with_tpp_vaccination_record(
    product_name_matches="COVID-19 mRNA Vaccine Spikevax (nucleoside modified) 0.1mg/0.5mL dose disp for inj MDV (Moderna)",
    between=["date_most_recent_cov_vac", "date_most_recent_cov_vac"],
    find_last_match_in_period=True,
      returning="binary_flag",
      return_expectations={
        "incidence": 0.5
      },
  ),

  ###################################################################
  # OUTCOME AND CENSORING VARIABLES ---------------------------------
  ###################################################################
  death_date=patients.died_from_any_cause(
    returning="date_of_death",
    date_format="YYYY-MM-DD",
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "incidence": 0.1
    },
  ),

  death_cause=patients.died_from_any_cause(
    returning="underlying_cause_of_death",
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    return_expectations={
      "rate": "universal",
      "incidence": 0.05,
      "category": {
        "ratios": {
          "icd1": 0.2,
          "icd2": 0.2,
          "icd3": 0.2,
          "icd4": 0.2,
          "icd5": 0.2,
        }
      },
    },
  ),

  # covid-related death (outcome)
  died_ons_covid_any_date=patients.with_these_codes_on_death_certificate(
    codelists.covid_icd10_codes,  # imported from codelists.py
    returning="date_of_death",
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    date_format="YYYY-MM-DD",
    match_only_underlying_cause=False,  # boolean for indicating if filters
    # results to only specified cause of death
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "exponential_increase",
      "incidence": 0.05,
    },
  ),

  # covid as primary cause of death
  died_ons_covid_date=patients.with_these_codes_on_death_certificate(
    codelists.covid_icd10_codes,  # imported from codelists.py
    returning="date_of_death",
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    date_format="YYYY-MM-DD",
    match_only_underlying_cause=True,  # boolean for indicating if filters
    # results to only specified cause of death
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "exponential_increase",
      "incidence": 0.05,
    },
  ),

  dereg_date=patients.date_deregistered_from_all_supported_practices(
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "incidence": 0.1
    },
  ),

  # covid as primary diagnosis (outcome)
  covid_hosp_admission_date=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_primary_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # associated discharge date used to check if day case for sotrovimab infusion
  # --> if day case for sotrovimab infusion, pt censored at sotrovimab init and hospital admission not counted as outcome
  covid_hosp_discharge_date=patients.admitted_to_hospital(
    returning="date_discharged",
    with_these_primary_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["covid_hosp_admission_date", "covid_hosp_admission_date + 1 day"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # mention of mabs procedure
  # --> if mabs procedure mentioned, pt censored at sotrovimab init and hospital admission not counted as outcome
  covid_hosp_date_mabs_procedure=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_primary_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    with_these_procedures=codelists.mabs_procedure_codes,
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # covid as one of the diagnoses
  covid_any_hosp_admission_date=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_primary_diagnoses=None,
    with_these_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # associated discharge date used to check if day case for sotrovimab infusion
  # --> if day case for sotrovimab infusion, pt censored at sotrovimab init and hospital admission not counted as outcome
  covid_any_hosp_discharge_date=patients.admitted_to_hospital(
    returning="date_discharged",
    with_these_primary_diagnoses=None,
    with_these_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["covid_any_hosp_admission_date", "covid_any_hosp_admission_date + 1 day"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # mention of mabs procedure
  # --> if mabs procedure mentioned, pt censored at sotrovimab init and hospital admission not counted as outcome
  covid_any_hosp_date_mabs_procedure=patients.admitted_to_hospital(
    returning="date_admitted",
    with_these_primary_diagnoses=None,
    with_these_diagnoses=codelists.covid_icd10_codes,
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    with_these_procedures=codelists.mabs_procedure_codes,
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # all cause hospitalisation
  allcause_hosp_admission_date=patients.admitted_to_hospital(
    returning="date_admitted",
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # return cause
  allcause_hosp_admission_diagnosis=patients.admitted_to_hospital(
    returning="primary_diagnosis",
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "rate": "universal",
      "incidence": 0.05,
      "category": {
        "ratios": {
          "icd1": 0.2,
          "icd2": 0.2,
          "icd3": 0.2,
          "icd4": 0.2,
          "icd5": 0.2}, }, },
  ),

  # associated discharge date used to check if day case for sotrovimab infusion
  # --> if day case for sotrovimab infusion, pt censored at sotrovimab init and hospital admission not counted as outcome
  allcause_hosp_discharge_date=patients.admitted_to_hospital(
    returning="date_discharged",
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    between=["allcause_hosp_admission_date", "allcause_hosp_admission_date + 1 day"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),

  # mention of mabs procedure
  # --> if mabs procedure mentioned, pt censored at sotrovimab init and hospital admission not counted as outcome
  allcause_hosp_date_mabs_procedure=patients.admitted_to_hospital(
    returning="date_admitted",
    with_patient_classification=["1"], # ordinary admissions only - exclude day cases and regular attenders
    # see https://docs.opensafely.org/study-def-variables/#sus for more info
    with_these_procedures=codelists.mabs_procedure_codes,
    between=["covid_test_positive_date", "covid_test_positive_date + 28 days"],
    find_first_match_in_period=True,
    date_format="YYYY-MM-DD",
    return_expectations={
      "date": {"earliest": "index_date + 1 day", "latest": end_date},
      "rate": "uniform",
      "incidence": 0.1
    },
  ),
)

