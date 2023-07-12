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

# Import custom user functions
source(here::here("lib", "functions", "clean_coef_names.R"))

## Import data
data_cohort <-
  read_rds(here::here("output", "data", "data_processed_excl_contraindicated.rds")) #%>%
  #mutate(treatment_strategy_cat = ifelse(row_number() > 13000, 0, treatment_strategy_cat))


############################################################################
# PART A: Model treatment status at day 5
############################################################################
# Create vector of variables for propensity score model
# Note: age modelled with cubic spline with 3 knots
if (adjustment_set == "full"){
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
} else if (adjustment_set == "agesex") {
  vars <-
    c("ns(age, df=3)",
      "sex")
}


############################################################################
# A.2.2 Fit Propensity Score Model
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
# Save fitted model
saveRDS(psModel,
        here("output", 
             "data_models",
             paste0(trt_grp[i],
                    "_",
                    adjustment_set,
                    "_psModelFit_",
                    data_label,
                    "_",
                    period[!period == "ba1"], "_"[!period == "ba1"],
                    "new.rds")
        )
)
# Calculate patient-level predicted probability of being assigned to cohort
data_cohort$pscore <- predict(psModel, type = "response")

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

overlapPlot
# Save plot
ggsave(overlapPlot, 
       filename = 
         here("output", "figs", 
              paste0(trt_grp[i],
                     "_",
                     adjustment_set,
                     "_overlap_plot_",
                     data_label,
                     "_before_restriction_",
                     period[!period == "ba1"], "_"[!period == "ba1"],
                     "new.png")),
       width = 20, height = 14, units = "cm")

############################################################################
# Truncated propensity score distributions
############################################################################
# Check overlap
# Identify lowest and highest propensity score in each group
ps_trunc <- data_cohort %>% 
  select(treatment_strategy_cat, pscore) %>% 
  group_by(treatment_strategy_cat) %>% 
  summarise(min = min(pscore), max= max(pscore)) %>% 
  ungroup() %>% 
  summarise(min = max(min), max = min(max)) # see below for why max of min 
# and min of max is taken
# Restricted to observations within a PS range common to both treated and 
# untreated persons—
# (i.e. exclude all patients in the non-overlapping parts of the PS 
# distribution)
data_cohort_sub_trimmed <- data_cohort_sub %>% 
  filter(pscore >= ps_trim$min[1] & pscore <= ps_trim$max[1])
# Save n in 'estimates' after trimming
estimates[c(seq(1, 12, 3) + (i - 1)), "n_after_restriction"] <-
  nrow(data_cohort_sub_trimmed) %>% plyr::round_any(5)
# Fill counts after trimming
counts_n_restr[i, "comparison"] <- t
counts_n_restr[i, ] <- fill_counts_n(counts_n_restr[i, ], data_cohort_sub_trimmed)
# Make plot of trimmed propensity scores and save
# Overlap plot 
overlapPlot2 <- data_cohort_sub_trimmed %>% 
  mutate(trtlabel = ifelse(treatment == "Treated",
                           yes = 'Treated',
                           no = 'Untreated')) %>%
  ggplot(aes(x = pscore, linetype = trtlabel)) +
  scale_linetype_manual(values=c("solid", "dotted")) +
  geom_density(alpha = 0.5) +
  xlab('Probability of receiving treatment') +
  ylab('Density') +
  scale_fill_discrete('') +
  scale_color_discrete('') +
  scale_x_continuous(breaks=seq(0, 1, 0.1)) +
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
# Save plot
ggsave(overlapPlot2, 
       filename = 
         here("output", "figs", 
              paste0(trt_grp[i],
                     "_",
                     adjustment_set,
                     "_overlap_plot_",
                     data_label,
                     "_after_restriction_",
                     period[!period == "ba1"], "_"[!period == "ba1"],
                     "new.png")),
       width = 20, height = 14, units = "cm")



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

plot

plot2 <- coefs_plot_clean %>% ggplot(aes(abs_estimate,reorder(variable, abs_estimate))) +
  geom_point(colour="darkorange", fill = "darkorange") +
  theme_bw() +
  xlab('|1-Odds ratio|') +
  ylab('') 

plot2

a <- plot_grid(plot, plot2, labels = c('A', 'B'))
a

# Save plot
ggsave(a, 
       filename = 
         here("output", "figs", 
              paste0("trt_preds",
                     ".png")),
       width = 20, height = 25, units = "cm")

write_csv(counts_n_outcome_restr,
          here("output",
               "counts",
               paste0("counts_n_outcome_restr_",
                      data_label,
                      "_",
                      adjustment_set,
                      "_"[!period == "ba1"],
                      period[!period == "ba1"],
                      ".csv")))
  