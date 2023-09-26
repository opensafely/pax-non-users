source(here::here("analysis", "seq_trials", "functions", "construct_trial_no.R"))
construct_trials <- function(data, treat_window, censor = FALSE){
  trials <-
    map_dfr(.x = 0:{treat_window - 1},
            .f = ~ construct_trial_no(data, .x))
  if (censor == TRUE) {
    trials %<>%
      group_by(patient_id, trial) %>%
      filter(!(arm == 0 & treatment_seq == 1)) %>%
      ungroup()
  }
  trials
}