################################################################################
#
# Visualise distribution of treatment initiation
# 
# The output of this script is:
# csv file ./output/descriptives/figures/distr_pax_init.png
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
library(tidyr)
library(ggplot2)

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "descriptives", "figures")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 0.3 Import data
################################################################################
data_flow_seq_trials <- 
  read_csv(here("output", "seq_trials", "descriptives", "data_flow_seq_trials_monthly_red.csv"),
           col_types = cols(
             period_month = col_integer(),
             trial = col_integer(),
             treated_baseline = col_character(),
             untreated_baseline = col_character(),
             treatment_seq = col_character(),
             treatment_seq_sotmol = col_character()))

################################################################################
# 0.4 Data manipulation
################################################################################
data_flow_seq_trials <-
  data_flow_seq_trials %>%
  mutate(
    treated_baseline = if_else(treated_baseline == "[REDACTED]", "8", treated_baseline) %>% as.integer(),
    untreated_baseline = if_else(untreated_baseline == "[REDACTED]", "8", untreated_baseline) %>% as.integer(),
    treatment_seq = if_else(treatment_seq == "[REDACTED]", "8", treatment_seq) %>% as.integer(),
    treatment_seq_sotmol = if_else(treatment_seq_sotmol == "[REDACTED]", "8", treatment_seq_sotmol) %>% as.integer(),
    untreated_baseline = untreated_baseline - treatment_seq - treatment_seq_sotmol,
  ) %>%
  pivot_longer(cols = treated_baseline:treatment_seq_sotmol,
               names_to = "type",
               values_to = "count") %>%
  mutate(type2 = if_else(type %in% c("treated_baseline", "untreated_baseline"), 0, 1),
         type = case_when(type == "treated_baseline" ~ "Treated at baseline",
                          type == "untreated_baseline" ~ "Untreated at baseline",
                          type == "treatment_seq" ~ "Treated with Paxlovid after baseline",
                          type == "treatment_seq_sotmol" ~ "Treated with sot/mol after baseline"),
         type = factor(type, levels = c("Treated with Paxlovid after baseline",
                                        "Treated with sot/mol after baseline",
                                        "Untreated at baseline",
                                        "Treated at baseline")),
         trial = factor(trial, levels = c(4, 3, 2, 1, 0)))

################################################################################
# 1.0 Make histogram
################################################################################
plot <-
  ggplot(data_flow_seq_trials,
         aes(x = trial, y = count, fill = type, pattern = factor(type2))) +
  geom_bar_pattern(stat = "identity") +
  coord_flip() +
  facet_grid(rows = vars(period_month)) + 
  theme_minimal() +
  scale_pattern_manual(values = c("1" = "stripe", "0" = "none")) +
  labs(y = "Number of Patients",
       x = "Matched Set",
       fill = "Treatment Type")

################################################################################
# 2.0 Save output
################################################################################
ggsave(plot,
       filename = path(output_dir, "data_flow_monthly.png"),
       device = "png",
       bg = "white")
