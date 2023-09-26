split_data <- function(data){
  data %>%
    group_by(patient_id) %>%
    tidyr::uncount(fup_seq, .remove = FALSE) %>%
    mutate(tend = row_number(),
           tstart = tend - 1L,
           status_seq = if_else(tend == fup_seq, status_seq, 0L),
           treatment_seq = if_else(tstart == tb_postest_treat_seq | tstart > tb_postest_treat_seq, treatment_seq, 0L),
           treatment_seq_sotmol = if_else(tstart == tb_postest_treat_seq_sotmol | tstart > tb_postest_treat_seq_sotmol, treatment_seq_sotmol, 0L)) %>%
    select(- c(fup_seq, tb_postest_treat_seq, tb_postest_treat_seq_sotmol)) %>%
    relocate(patient_id, tstart, tend) %>%
    ungroup()
} 
