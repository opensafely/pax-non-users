################################################################################
#
# FUP and number of outcomes experienced in study population
# 
#
# The output of this script is:
# -./output/descriptives/overview_fup_outcomes.csv
#
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library('tidyverse')
library('here')
library('glue')
library('gt')
library('gtsummary')
library('fs')

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import data
################################################################################
data <- read_rds(here("output", "data", "data_processed_excl_contraindicated.rds"))
data <-
  data %>%
  filter(treatment_strategy_cat_prim %in% c("Paxlovid", "Untreated"))

################################################################################
# 1 Make overview fup and outcomes experienceds
################################################################################
n_total <- data %>% nrow()
fup_sum <- data %>% pull(fu_primary) %>% sum()
fup_mean <- data %>% pull(fu_primary) %>% mean() %>% round(1)
fup_median <- data %>% pull(fu_primary) %>% median()
fup_iqr1 <- data %>% pull(fu_primary) %>% quantile(1/4)
fup_iqr3 <- data %>% pull(fu_primary) %>% quantile(3/4)
n_outcome <- data %>% filter(status_primary == "covid_hosp_death") %>% nrow()
overview_fup_outcomes <- 
  tibble(n_total,
         fup_sum,
         fup_mean,
         fup_median,
         fup_iqr1,
         fup_iqr3,
         n_outcome)

################################################################################
# 2 Save overview
################################################################################
write_csv(overview_fup_outcomes,
          fs::path(output_dir, "overview_fup_outcomes.csv"))
