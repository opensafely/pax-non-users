################################################################################
#
# Table 1
# 
#
# The output of this script is:
# -./output/tables/stratified_3months/table1_*_*.csv
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
# Import custom user functions
source(here::here("lib", "design", "covars_table.R"))
source(here::here("analysis", "descriptives", "functions", "generate_table1.R"))
source(here::here("analysis", "descriptives", "functions", "table1_helpers.R"))

################################################################################
# 0.1 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)
study_dates <-
  jsonlite::read_json(path = here::here("lib", "design", "study-dates.json")) %>%
  map(as.Date)

################################################################################
# 0.2 Create directories for output
################################################################################
output_dir <- here::here("output", "tables", "stratified_3months")
fs::dir_create(output_dir)

################################################################################
# 0.3 Import data
################################################################################
data <- read_rds(here("output", "data", "data_processed_excl_contraindicated.rds"))

################################################################################
# 1 Format data
################################################################################
data_table_full <- 
  data %>%
  select(treatment_strategy_cat_prim, period_3month, all_of(covars))
data_table <-
  data_table_full %>%
  filter(treatment_strategy_cat_prim %in% c("Paxlovid", "Untreated"))
data_table_trt_untrt <- 
  data %>%
  select(treatment_strategy_cat_prim, period_3month, all_of(covars)) %>%
  mutate(treatment_strategy_cat_prim =
           if_else(treatment_strategy_cat_prim == "Paxlovid", "Paxlovid", "Not treated with Paxlovid"))
# make list data used for creating tables (per period)
create_list_data_tables <- function(data_table){
  data_table <-
    map(.x = 1:4,
        .f = ~ data_table %>% filter(period_3month == .x) %>% select(-period_3month))
  names(data_table) <- paste0("period", 1:4)
  data_table
}
data_table_full <- create_list_data_tables(data_table_full)
data_table <- create_list_data_tables(data_table)
data_table_trt_untrt <- create_list_data_tables(data_table_trt_untrt)

################################################################################
# 2 Create table 1
################################################################################
# exclude mol/sot treated
pop_levels <- c("All", "Paxlovid", "Untreated")
table1 <-
  map(.x = data_table,
      .f = ~ generate_table1(.x, pop_levels))
table1 <-
  imap(.x = table1,
       .f = ~ .x %>% add_period(.y) %>% remove_all_cat()) %>%
  combine_tables()
# full table
pop_levels_full <- c("All", "Paxlovid", "Sotrovimab", "Molnupiravir", "Untreated")
table1_full <-
  map(.x = data_table_full,
      .f = ~ generate_table1(.x, pop_levels_full))
table1_full <-
  imap(.x = table1_full,
       .f = ~ .x %>% add_period(.y) %>% remove_all_cat()) %>%
  combine_tables()
# pax treated vs non-pax treated
pop_levels_trt_untrt = c("All", "Paxlovid", "Not treated with Paxlovid")
table1_trt_untrt <-
  map(.x = data_table_trt_untrt,
      .f = ~ generate_table1(.x, pop_levels_trt_untrt))
table1_trt_untrt <-
  imap(.x = table1_trt_untrt,
       .f = ~ .x %>% add_period(.y) %>% remove_all_cat()) %>%
  combine_tables()

################################################################################
# 2 Save table
################################################################################
write_csv(table1$table1,
          fs::path(output_dir, "table1.csv"))
write_csv(table1$table1_red,
          fs::path(output_dir, "table1_red.csv"))
write_csv(table1$table1_red_unf,
          fs::path(output_dir, "table1_red_unf.csv")) # aiding output checks
write_csv(table1_full$table1,
          fs::path(output_dir, "table1_full.csv"))
write_csv(table1_full$table1_red,
          fs::path(output_dir, "table1_full_red.csv"))
write_csv(table1_full$table1_red_unf,
          fs::path(output_dir, "table1_full_red_unf.csv")) # aiding output checks
write_csv(table1_trt_untrt$table1,
          fs::path(output_dir, "table1_trt_untrt.csv"))
write_csv(table1_trt_untrt$table1_red,
          fs::path(output_dir, "table1_trt_untrt_red.csv"))
write_csv(table1_trt_untrt$table1_red_unf,
          fs::path(output_dir, "table1_trt_untrt_red_unf.csv")) # aiding output checks
