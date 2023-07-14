library(survival)
survsplit_data <- function(data) {
  splits <- 1:28
  data <-
    data %>%
    survSplit(cut = splits,
              end = "fup_seq",
              event = "status_seq") %>%
    rename(tend = fup_seq)
  ## TODO: make variable T0, T1, T2, T3, T4 0 if untreated, 1 if treated.
  
  ## TODO: if treated with sot/mol, censor (fup_seq = tb_postest_treat_seq;
  ## status_seq = 0)
}