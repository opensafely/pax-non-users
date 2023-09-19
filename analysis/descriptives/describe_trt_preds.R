################################################################################
#
# Predictors of treatment and distribution of estimated propensity scores
# 
# The output of this script is:
# csv file ./output/descriptives/
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(here)
library(dplyr)
library(readr)
library(splines)
library(fs)
library(purrr)
# Import custom user functions
source(here::here("analysis", "descriptives", "functions", "clean_coef_names.R"))
source(here::here("lib", "design", "covars_psmodels.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import command-line arguments
################################################################################
args <- commandArgs(trailingOnly=TRUE)
print(args)
if (length(args) == 0){
  population = "all_ci" # when run not via action.yaml
  treatment = "Paxlovid" # when run not via action.yaml
} else if (length(args) != 2){
  stop("Two arguments are needed")
} else if (length(args) == 2) {
  if (args[[1]] == "all_ci") {
    population = "all_ci"
  }
  else if (args[[1]] == "ci_drugs_dnu") {
  population = "excl_drugs_dnu"
  }
  if (args[[2]] == "Paxlovid") {
    treatment = "Paxlovid"
  }
  else if (args[[2]] == "Sotrovimab") {
    treatment = "Sotrovimab"
  }
  else if (args[[2]] == "Molnupiravir") {
    treatment = "Molnupiravir"
  }
}
  
################################################################################
# 0.3 Import data
################################################################################
if (population == "all_ci") {
  data_cohort <- 
    read_rds(here("output", "data", "data_processed_excl_contraindicated.rds")) %>%
    filter(treatment_strategy_cat %in% c(!!treatment, "Untreated")) 
} else if (population == "excl_drugs_dnu") {
  data_cohort <- read_rds(here("output", "data", "data_processed.rds")) %>%
    mutate(contraindicated_excl_rx_dnu =
              if_else(ci_liver_disease | ci_solid_organ_transplant | 
                        ci_renal_disease, TRUE, FALSE)) %>% 
    filter(treatment_strategy_cat %in% c(!!treatment, "Untreated") &
             contraindicated_excl_rx_dnu == FALSE) 
}

############################################################################
# 1.0 Specify model for treatment status at day 5
############################################################################
psModelFunction <- as.formula(
  paste("treatment_strategy_cat", 
        paste(covars, collapse = " + "), 
        sep = " ~ "))

############################################################################
# 1.1 Fit Propensity Score Model
############################################################################
# Fit PS model
psModel <- glm(psModelFunction,
               family = binomial(link = "logit"),
               data = data_cohort)
# Calculate patient-level predicted probability of being assigned to cohort
data_cohort$pscore <- predict(psModel, type = "response")

############################################################################
# 1.2 Functions for density and size
############################################################################
calc_dens <- function(data, treatment, type){
  dens <- data %>%
    mutate(
      trtlabel = if_else(treatment_strategy_cat == !!treatment, 'Treated', 'Untreated')
      ) %>%
    select(trtlabel, pscore) %>%
    group_by(trtlabel) %>%
    summarise(dens_x = density(pscore)$x,
              dens_y = density(pscore)$y,
              .groups = "drop") %>%
    filter(dens_x >= 0 & dens_x <= 1) %>%
    mutate(analysis = type)
}
calc_size <- function(data, type){
  data %>% 
    group_by(treatment_strategy_cat) %>%
    count() %>%
    mutate(analysis = type)
}

############################################################################
# 1.4 Density and size for trimmed and untrimmed analysis
############################################################################
# density and size untrimmed
dens <- calc_dens(data_cohort, treatment, "Untrimmed")
size <- calc_size(data_cohort, "Untrimmed")
# trimmed
# Identify lowest and highest propensity score in each group
ps_trim <- data_cohort %>% 
  select(treatment_strategy_cat, pscore) %>% 
  group_by(treatment_strategy_cat) %>% 
  summarise(min = min(pscore), max = max(pscore)) %>% 
  ungroup() %>% 
  summarise(min = max(min), max = min(max))
# Restricted to observations within a PS range common to both treated and 
# untreated persons—
# (i.e. exclude all patients in the non-overlapping parts of the PS 
# distribution)
data_cohort_trimmed <- data_cohort %>% 
  filter(pscore >= ps_trim$min[1] & pscore <= ps_trim$max[1])
# density and size trimmed
dens_trimmed <- calc_dens(data_cohort_trimmed, treatment, "Trimmed")
size <- size %>% bind_rows(calc_size(data_cohort_trimmed, "Trimmed"))

############################################################################
# 1.5 Propensity score model coefficients
############################################################################
coefs <- broom::tidy(psModel, conf.int = TRUE) %>% 
  mutate(estimate = exp(estimate),
         lci = exp(conf.low),
         uci = exp(conf.high),
         abs_estimate = abs(estimate - 1)
  ) %>%
  rename(variable = term) %>%
  select(-c(conf.low, conf.high, statistic)) %>%
  clean_coef_names()

############################################################################
# 2.0 Save outputs
############################################################################  
# Save fitted model
write_rds(psModel,
          fs::path(output_dir, 
                   paste0("psModel_",treatment, "_",population, ".rds")))
# save density
iwalk(.x = list(Dens_untrimmed_ = dens, Dens_trimmed_ = dens_trimmed),
      .f = ~ write_csv(.x,
                       fs::path(output_dir,
                               paste0("ps", .y, treatment, "_", population, ".csv"))))
# save coefs
write_csv(coefs,
          fs::path(output_dir, 
                   paste0("psCoefs_", treatment, "_", population, ".csv")))
# save trimmed versus untrimmed descriptives
write_csv(size, 
          fs::path(output_dir, 
                   paste0("trimming_descriptives_", treatment, "_", population, ".csv")))
