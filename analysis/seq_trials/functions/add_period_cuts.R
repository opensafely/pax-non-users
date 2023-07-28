# This function
# adds column period_week and period_month
# dividing pop in weekly/ monthly intervals based on covid_test_positive_date
# Arguments:
# data: data_frame with study pop
# study_dates: study_dates from lib/design/study-dates.json
add_period_cuts <- function(data, study_dates){
  seq_dates_start_interval_week <- 
    seq(study_dates$start_date, study_dates$end_date + 1, by = "1 week")
  seq_dates_start_interval_month <- 
    seq(study_dates$start_date, study_dates$end_date + 1, by = "1 month")
  data <-
    data %>%
    mutate(period_week = cut(covid_test_positive_date, 
                             breaks = seq_dates_start_interval_week, 
                             include.lowest = TRUE,
                             right = FALSE,
                             labels = 1:52),
           period_month = cut(covid_test_positive_date, 
                              breaks = seq_dates_start_interval_month, 
                              include.lowest = TRUE,
                              right = FALSE,
                              labels = 1:12))
}
