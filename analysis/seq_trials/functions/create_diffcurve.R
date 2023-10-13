create_diffcurve <- function(
    survcurve1,
    survcurve0,
    data_counterfact1,
    data_counterfact0,
    plrmod,
    vcov,
    riskdiff_variance, # function to estimate variance risk difference
    id,
    time,
    weights){
  
  curves <- 
    survcurve1 %>% 
    left_join(survcurve0, by = c("tend", "lead_tend"), suffix = c("1", "0"))
  
  curves %>%
    mutate(
      diff = (1 - survival1) - (1 - survival0),
    ) %>%
    filter(tend != 0) %>%
    select(tend, lead_tend, diff) %>%
    mutate(
      diff_se = riskdiff_variance(
        plrmod = fit,
        vcov = vcov,
        newdata0 = data_counterfact0,
        newdata1 = data_counterfact1,
        id = id,
        time = time,
        weights = weights
      ) %>% sqrt(),
      diff_ll = pmax(0, diff + qnorm(0.025) * diff_se) - pmax(0, diff + qnorm(0.975) * diff_se - 1),
      diff_ul = pmin(1, diff + qnorm(0.975) * diff_se) + pmin(0, diff + qnorm(0.025) * diff_se),
    ) %>%
    add_row(
      tend = 0,
      lead_tend = 1,
      diff = 0,
      diff_se = 0,
      diff_ul = 0,
      diff_ll = 0,
      .before = 1
    )
}