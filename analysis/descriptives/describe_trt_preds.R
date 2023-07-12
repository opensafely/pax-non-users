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

library('here')
library('tidyverse')
library('readr')
library('tidyr')
library('glue')
library('gt')
library('gtsummary')
library('kableExtra')
library('cowplot')
library('splines')
library('fs')
library('purrr')

# Import custom user functions
source(here::here("lib", "functions", "clean_coef_names.R"))

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

if (length(args) != 1){
  stop("One argument is needed")
} else if (length(args) == 1) {
  if (args[[1]] == "all_ci") {
    population = "all_ci"
  }
  else if (args[[1]] == "ci_drugs_dnu") {
  population = "excl_drugs_dnu"
  }
}
  
################################################################################
# 0.3 Import data
################################################################################
if (population == "all_ci") {
  data_cohort <- read_rds(here("output", "data", "data_processed_excl_contraindicated.rds")) #%>%
  #mutate(treatment_strategy_cat = ifelse(row_number() > 13000, 0, treatment_strategy_cat))
  
} else if (population == "excl_drugs_dnu") {
  data_cohort <- read_rds(here("output", "data", "data_processed.rds")) %>%
    mutate(contraindicated_excl_rx_dnu =
              if_else(ci_liver_disease | ci_solid_organ_transplant | 
                        ci_renal_disease | ci_ckd3_primis | ci_ckd3_icd10 |
                        ci_egfr_30_59 | ci_egfr_creat_30_59, TRUE, FALSE)) %>% 
    filter(contraindicated_excl_rx_dnu == TRUE)
}

############################################################################
# 1.0 Specify model for treatment status at day 5
############################################################################
# Create vector of variables for propensity score model
# Note: age modelled with cubic spline with 3 knots
vars <-
    c("ns(age, df=3)",
      "ns(study_week, df=3)",
      "sex",
      "ethnicity",
      "imdQ5" ,
      "stp",
      "rural_urban",
      "huntingtons_disease_nhsd" ,
      "myasthenia_gravis_nhsd" ,
      "motor_neurone_disease_nhsd" ,
      "multiple_sclerosis_nhsd"  ,
      "hiv_aids_nhsd" ,
      "imid_nhsd" ,
      "liver_disease_nhsd",
      "ckd_stage_5_nhsd",
      "haematological_disease_nhsd",
      "cancer_opensafely_snomed_new",
      "downs_syndrome_nhsd",
      "diabetes",
      "smoking_status",
      "copd",
      "dialysis",
      "vaccination_status",
      "pfizer_most_recent_cov_vac",
      "az_most_recent_cov_vac",
      "moderna_most_recent_cov_vac",
      "learning_disability_primis",
      "autism_nhsd",
      "care_home_primis",
      "housebound_opensafely",
      "obese",
      "serious_mental_illness_nhsd",
      "chronic_cardiac_disease",
      "dementia_nhsd",
      "hypertension")


############################################################################
# 1.1 Fit Propensity Score Model
############################################################################
# Specify model
psModelFunction <- as.formula(
  paste("treatment_strategy_cat", 
        paste(vars, collapse = " + "), 
        sep = " ~ "))

# Fit PS model
psModel <- glm(psModelFunction,
               family = binomial(link = "logit"),
               data = data_cohort)

# Calculate patient-level predicted probability of being assigned to cohort
data_cohort$pscore <- predict(psModel, type = "response")

############################################################################
# 1.2 Visually inspect propensity score distributions
############################################################################
# Make plot of non-trimmed propensity scores and save
# Overlap plot 
overlapPlot <- data_cohort %>% 
  mutate(trtlabel = ifelse(treatment_strategy_cat == 1,
                           yes = 'Treated',
                           no = 'Untreated')) %>%
  ggplot(aes(x = pscore, linetype = trtlabel)) +
  scale_linetype_manual(values=c("solid", "dotted")) +
  geom_density(alpha = 0.5) +
  xlab('Probability of receiving treatment') +
  ylab('Density') +
  scale_fill_discrete('') +
  scale_color_discrete('') +
  theme(strip.text = element_text(colour ='black')) +
  theme_bw() +
  scale_x_continuous(breaks=seq(0,1,0.1), limits=c(0,1)) +
  theme(legend.title = element_blank()) +
  theme(legend.position = c(0.1,.9),
        legend.direction = 'vertical', 
        panel.background = element_rect(fill = "white", colour = "white"),
        axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

############################################################################
# 1.3 Trimmed propensity score distributions
############################################################################
# Check overlap
# Identify lowest and highest propensity score in each group
ps_trim <- data_cohort %>% 
  select(treatment_strategy_cat, pscore) %>% 
  group_by(treatment_strategy_cat) %>% 
  summarise(min = min(pscore), max= max(pscore)) %>% 
  ungroup() %>% 
  summarise(min = max(min), max = min(max)) 
# Restricted to observations within a PS range common to both treated and 
# untreated persons—
# (i.e. exclude all patients in the non-overlapping parts of the PS 
# distribution)
data_cohort_trimmed <- data_cohort %>% 
  filter(pscore >= ps_trim$min[1] & pscore <= ps_trim$max[1])

# Make plot of trimmed propensity scores and save
# Overlap plot 
overlapPlot2 <- data_cohort_trimmed %>% 
  mutate(trtlabel = ifelse(treatment_strategy_cat == 1,
                           yes = 'Treated',
                           no = 'Untreated')) %>%
  ggplot(aes(x = pscore, linetype = trtlabel)) +
  scale_linetype_manual(values=c("solid", "dotted")) +
  geom_density(alpha = 0.5) +
  xlab('Probability of receiving treatment') +
  ylab('Density') +
  scale_fill_discrete('') +
  scale_color_discrete('') +
  scale_x_continuous(breaks=seq(0, 1, 0.1), limits=c(0,1)) +
  theme(strip.text = element_text(colour ='black')) +
  theme_bw() +
  theme(legend.title = element_blank()) +
  theme(legend.position = c(0.82,.8),
        legend.direction = 'vertical', 
        panel.background = element_rect(fill = "white", colour = "white"),
        axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

############################################################################
# 2.0 Propensity score model coefficients
############################################################################

coefs <- as.data.frame(coefficients(summary(psModel))) %>% 
  mutate(estimate = exp(Estimate),
         lci = exp(Estimate - 1.96*`Std. Error`),
         uci = exp(Estimate + 1.96*`Std. Error`),
  )

coefs$variable = rownames(coefs)

coefs_plot <- coefs %>% 
  filter(variable!= "(Intercept)") %>% 
  arrange(estimate) %>% 
  mutate(abs_estimate = abs(estimate-1))
  
coefs_plot_clean = clean_coef_names(coefs_plot)  
  
plot <- coefs_plot_clean %>% ggplot(aes(estimate,reorder(variable, estimate))) +
  geom_segment(aes(yend = variable, x = lci, xend = uci), colour="blue") +
  geom_point(colour="blue", fill = "blue") +
  geom_vline(xintercept = 1, lty = 2) + 
  theme_bw() +
  xlab('Odds ratio') +
  ylab('Variable') 

plot2 <- coefs_plot_clean %>% ggplot(aes(abs_estimate,reorder(variable, abs_estimate))) +
  geom_point(colour="darkorange", fill = "darkorange") +
  theme_bw() +
  xlab('|1-Odds ratio|') +
  ylab('') 

plot_combined <- plot_grid(plot, plot2, labels = c('A', 'B'))

############################################################################
# 3.0 Descriptives
############################################################################
desc1 <- data_cohort %>% 
  group_by(treatment_strategy_cat) %>%
  count() %>%
  mutate(analysis = "Untrimmed")

desc2 <- data_cohort_trimmed %>% 
  group_by(treatment_strategy_cat) %>%
  count() %>%
  mutate(analysis = "Trimmed")

desc <- rbind(desc1, desc2)

############################################################################
# 4.0 Save outputs
############################################################################  
# Save fitted model
write_rds(psModel,
          here::here("output", "descriptives",
                     paste0("psModel_", population, ".rds")))

# Save full overlap plot
ggsave(overlapPlot, 
       filename = 
         here::here("output", "descriptives", 
                   paste0("psOverlap_untrimmed_",population,".png")),
       width = 20, height = 14, units = "cm")

# Save trimmed overlap plot
ggsave(overlapPlot2, 
       filename = 
         here::here("output", "descriptives", 
              paste0("psOverlap_trimmed_",population,".png")),
       width = 20, height = 14, units = "cm")

# Save ps model coefficient plot
ggsave(plot_combined, 
       filename = 
         here::here("output", "descriptives", 
              paste0("psCoefs_",
                     population,
                     ".png")),
       width = 20, height = 25, units = "cm")

# Save trimmed versus untrimmed descriptives
write_csv(desc, 
            here::here("output", "descriptives",
               paste0("trimming_descriptives_", population, ".csv"))
)

          