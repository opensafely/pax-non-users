# This function 
# 1. Modifies the variable 'status_primary' to 'status_seq'
# --> levels are 0 (no event/censored/noncovid death); 
#     1 (covid hosp/death)
# --> Of note, variable 'status_primary', ignores noncovid_hosp (assuming 
#     outcome can still occur after noncovid hosp, so individual is still at 
#     risk of experiencing the outcome (covid hosp/death))
# 2. <odifies the variable 'tb_postest_treat' to 'tb_postest_treat_seq'
# --> we classify people as untreated if they experience an event before or on
#     day of treatment and set their
#     tb_postest_treat to NA (= time between treatment and day 0)
# 3. variable 'treatment_seq' == 'treatment_prim'
# 4. variable 'fup_seq' == 'fu_primary'
simplify_data <- function(data){
  data <-
    data %>%
    mutate(
      status_seq = if_else(
        status_primary %in% c("covid_hosp_death"),
        1,
        0),
      # some people have been treated on or after they experience an event,
      # variable 'treatment_prim' is then 'Untreated' (see process_data.R), if so,
      # set tb_postest_treat (day of fup on which they've been treated to NA)
      tb_postest_treat_seq = if_else(
        treatment_prim == "Untreated",
        NA_real_,
        tb_postest_treat),
      treatment_seq = treatment_prim,
      fup_seq = fu_primary
    )
}