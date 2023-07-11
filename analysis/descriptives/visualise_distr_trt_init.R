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

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives", "figures")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)

################################################################################
# 0.3 Import data
################################################################################
distr_trt_init <- read_csv(here("output", "descriptives", "distr_pax_init_red.csv"),
                           col_types = c(
                             tb_postest_treat = col_character(),
                             n = col_character(),
                             contraindicated = col_logical()))

################################################################################
# 0.4 Data manipulation
################################################################################
distr_trt_init <-
  distr_trt_init %>%
  mutate(n = if_else(n == "[REDACTED]", "0", n),
         n = n %>% as.integer(),
         contraindicated = if_else(contraindicated == TRUE,
                                   "Contraindicated individuals",
                                   "Including contraindicated"))

################################################################################
# 1.0 Make histogram
################################################################################
plot <-
  ggplot(distr_trt_init,
         aes(x = n, y = factor(tb_postest_treat))) +
  geom_bar(stat = "identity") +
  coord_flip() +
  facet_grid(rows = vars(contraindicated)) + 
  theme_minimal() +
  labs(x = "Number of patients receiving Paxlovid",
       y = "Time between positive test and treatment initiation")

################################################################################
# 2.0 Save output
################################################################################
ggsave(plot,
       filename = path(output_dir, "pax_init.png"),
       device = "png",
       bg = "white")
