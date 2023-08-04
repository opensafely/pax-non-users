# Import code building blocks from cohort extractor package
from cohortextractor import (
  StudyDefinition,
  patients,
  combine_codelists
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
    NOT has_died
    AND high_risk_group
    AND registered_eligible
    AND covid_test_positive
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
      "date": {"earliest": "index_date", "latest": end_date},
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
   return_expectations={"incidence": 0.05},
  ),

  # High risk groups
  # Definition of high risk using regular codelists
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
      "incidence": 0.4
    },
  ),

  liver_disease_nhsd_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    on_or_before="covid_test_positive_date",
    with_these_diagnoses=codelists.liver_disease_nhsd_icd10_codes,
    return_expectations={
      "incidence": 0.4
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

  decompensated_cirrhosis_icd10_prim_diag=patients.admitted_to_hospital(
    with_these_primary_diagnoses=codelists.advanced_decompensated_cirrhosis_icd10_codes,
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
              "1": 0.2, 
              "2": 0.2,
              "3": 0.2,
              "4": 0.2,
              "5": 0.2
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
      "incidence": 0.2,
    },
  ),

  ckd4_icd10=patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.ckd4_icd_codes,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.2,
    },
  ),

  ckd5_icd10 = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.ckd5_icd_codes,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.2,
    },
  ),    

  dialysis = patients.with_these_clinical_events(
    codelists.dialysis_codes,
    on_or_before ="covid_test_positive_date",
    returning = "binary_flag",
    find_last_match_in_period = True,
    return_expectations={
      "incidence": 0.2,
    },
  ),

  dialysis_icd10 = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.dialysis_icd10_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.2,
    },
  ),

  dialysis_procedure = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_procedures=codelists.dialysis_opcs4_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.2,
    },
  ),  

  kidney_transplant = patients.with_these_clinical_events(
    codelists.kidney_transplant_codes,
    on_or_before="covid_test_positive_date",
    returning="binary_flag",
    find_last_match_in_period=True,
    return_expectations={
      "incidence": 0.2,
    },    
  ),

  kidney_transplant_icd10 = patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_diagnoses=codelists.kidney_tx_icd10_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.2,
    },
  ),

  kidney_transplant_procedure=patients.admitted_to_hospital(
    returning="binary_flag",
    find_last_match_in_period=True,
    with_these_procedures=codelists.kidney_tx_opcs4_codelist,
    on_or_before="covid_test_positive_date",
    return_expectations={
      "incidence": 0.2,
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
      "incidence": 0.2,
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
      "incidence": 0.2,
    },
  ),
)
