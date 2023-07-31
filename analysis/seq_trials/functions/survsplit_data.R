library(survival)
source(here::here("lib", "design", "covars_seq_trials.R"))
survsplit_data <- function(data) {
  data_fup_splitted <-
    data %>%
    survSplit(cut = 1:28,
              end = "fup_seq",
              event = "status_seq") %>%
    rename(tend = fup_seq) %>%
    select(-c(treatment_seq, treatment_seq_sotmol))
  data_trt_splitted <-
    data %>%
    select(patient_id, tb_postest_treat_seq, treatment_seq) %>%
    survSplit(cut = 1:5,
              end = "tb_postest_treat_seq",
              event = "treatment_seq") %>%
    rename(tend = tb_postest_treat_seq)
  data_trt_sotmol_splitted <- 
    data %>%
    select(patient_id, tb_postest_treat_seq_sotmol, treatment_seq_sotmol) %>%
    survSplit(cut = 1:5,
              end = "tb_postest_treat_seq_sotmol",
              event = "treatment_seq_sotmol") %>%
    rename(tend = tb_postest_treat_seq_sotmol)
  # join tables
  data_splitted <- 
    data_fup_splitted %>%
    left_join(data_trt_splitted,
              by = c("patient_id", "tstart", "tend")) %>%
    left_join(data_trt_sotmol_splitted,
              by = c("patient_id", "tstart", "tend")) %>%
    group_by(patient_id) %>%
    mutate(treatment_seq = 
             if_else(is.na(treatment_seq), sum(treatment_seq, na.rm = TRUE), treatment_seq),
           treatment_seq_sotmol = 
             if_else(is.na(treatment_seq_sotmol), sum(treatment_seq_sotmol, na.rm = TRUE), treatment_seq_sotmol),
           treatment_seq_lag1 = lag(treatment_seq, n = 1, default = 0),
           treatment_seq_lag2 = lag(treatment_seq, n = 2, default = 0),
           treatment_seq_lag3 = lag(treatment_seq, n = 3, default = 0),
           treatment_seq_lag4 = lag(treatment_seq, n = 4, default = 0),
           treatment_seq_lag5 = lag(treatment_seq, n = 5, default = 0)) %>%
    ungroup() %>%
    select(patient_id, tstart, tend, status_seq, starts_with("treatment_seq"),
           all_of(covars))
}

