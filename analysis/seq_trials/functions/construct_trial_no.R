construct_trial_no <- function(data, trial_no){
  data %>%
    filter(tstart >= trial_no) %>%
    mutate(trial = trial_no) %>%
    group_by(patient_id) %>%
    mutate(arm = first(treatment_seq),
           treatment_seq_lag1_baseline = first(treatment_seq_lag1),
           tstart = tstart - trial_no,
           tend = tend - trial_no) %>%
    filter(treatment_seq_lag1_baseline == 0, #restrict to those not previously treated at the start of the trial
           first(status_seq) == 0,
           first(treatment_seq_sotmol) == 0) %>% # restrict to those not experiencing an outcome in first interval of trial &
    # restrict to those not treated with sot/mol in the first interval
    # note that individuals censored (dereg/non covid death) in a given interval, are not filtered out; we just want to make sure no-one
    # experiences the outcome (covid_hosp_death) in the first interval
    ungroup() %>%
    select(- c(treatment_seq_lag1_baseline, treatment_seq_lag1)) %>%
    relocate(patient_id, starts_with("period_"), trial, tstart, tend, arm)
}