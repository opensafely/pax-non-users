# some sense checks to show data structure
# relies on script 'prepare_data.R'
source(here::here("analysis", "seq_trials", "prepare_data.R"))

# Checks for individual experiencing the outocme
patient_id_outcome <- # sample patient_id
  data_splitted %>% filter(status_seq == 1 & treatment_seq == 0 & tend < 5) %>% pull(patient_id) %>% sample(1)
# pt should have n rows in 'data_splitted' and experience 'covid_hosp_death' if fu_primary == n
data_splitted %>%
  filter(patient_id == patient_id_outcome)
data %>%
  filter(patient_id == patient_id_outcome) %>%
  select(fu_primary, status_primary)
# number of trials is equal to fu_primary - 1
trials_monthly %>%
  filter(patient_id == patient_id_outcome) %>%
  select(patient_id, tstart, tend, period_month, trial, status_seq) %>% View()

# Checks for individual treated with Paxlovid
patient_id_trt <- # sample patient_id
  data_splitted %>% filter(treatment_seq == 1) %>% pull(patient_id) %>% sample(1)
# pt starts treatment on interval [tstart, tend] in 'data_splitted' and 'treatment_strategy_cat_prim' is Paxlovid in 'data' with tb_postest_treat equal to tstart
data_splitted %>%
  filter(patient_id == patient_id_trt)
data %>%
  filter(patient_id == patient_id_trt) %>%
  select(treatment_strategy_cat_prim, tb_postest_treat)
# in the sequential trials, patient is included in trial 1, .., tb_postest_treat;
# in the untreated arm (treatment_seq_baseline) in trial 1, .., tb_postest_treat - 1
# in the treated arm (treatment_seq_baseline) in trial tb_postest_treat
trials_monthly %>%
  filter(patient_id == patient_id_trt) %>%
  select(patient_id, tstart, tend, period_month, trial, treatment_seq, treatment_seq_baseline) %>% View()

# Checks for individual treated with Paxlovid
patient_id_trt_sotmol <-
  data_splitted %>% filter(treatment_seq_sotmol == 1) %>% pull(patient_id) %>% sample(1)
# pt starts treatment on interval [tstart, tend] in 'data_splitted' and 'treatment_strategy_cat_prim' is Paxlovid in 'data' with tb_postest_treat equal to tstart
data_splitted %>%
  filter(patient_id == patient_id_trt_sotmol)
data %>%
  filter(patient_id == patient_id_trt_sotmol) %>%
  select(treatment_strategy_cat_prim, tb_postest_treat)
