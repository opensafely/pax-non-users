################################################################################
#
# Distribution of outcomes during treatment window
# 
# The output of this script is:
# csv file ./output/descriptives/outcomes_in_trt_window(_red).csv
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
source(here::here("lib", "design", "redaction.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 0.3 Import data
################################################################################
data <- read_rds(here("output", "data", "data_processed.rds"))

################################################################################
# 1.0 Distribution trt init
################################################################################
total_n <- nrow(data)

calc_outcomes_in_trt_window <- function(data, treat_window_days = 4) {
  outcomes_in_trt_window <- 
    data %>%
    filter(!(any_treatment_strategy_cat %in% c("Sotrovimab", "Molnupiravir")) &
             contraindicated == TRUE) %>%
    filter(fu_primary <= treat_window_days) %>%
    group_by(status_primary, .drop = FALSE) %>%
    tally() %>%
    mutate(trt_window = treat_window_days + 1)
}
outcomes_in_trt_window <-
  map_dfr(.x = c(4, 5, 6, 7),
          .f = ~ calc_outcomes_in_trt_window(data, .x))
outcomes_in_trt_window_red <- 
  outcomes_in_trt_window %>%
  mutate(n = case_when(n > 0 & n <= redaction_threshold ~ "[REDACTED]",
                       TRUE ~ n %>% 
                         plyr::round_any(rounding_threshold) %>%
                         as.character()))

################################################################################
# 2.0 Save output
################################################################################
write_csv(x = outcomes_in_trt_window,
          path(output_dir, "outcomes_in_trt_window.csv"))
write_csv(x = outcomes_in_trt_window_red,
          path(output_dir, "outcomes_in_trt_window_red.csv"))
