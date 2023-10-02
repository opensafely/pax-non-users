construct_trials <- function(data, period, treat_window, censor = FALSE, construct_trial_no){
  data %<>%
    dplyr::filter(period == !!period)
  trials <-
    purrr::map_dfr(.x = 0:{treat_window - 1},
                  .f = ~ construct_trial_no(data, .x))
  if (censor == TRUE) {
    trials %<>%
      dplyr::group_by(patient_id, trial) %>%
      dplyr::filter(!(arm == 0 & treatment_seq == 1)) %>%
      dplyr::ungroup()
  }
  trials
}
