################################################################################
#
# Visualise output ps models
# 
# The output of this script is:
# png file ./output/descriptives/figures/psCoefs_treatment_population.png
# where treatment is Paxlovid, Sotrovimab or Molnupiravir
# where population is all_ci (all contraindications)
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
library(ggplot2)
library(cowplot)

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives", "figures")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import data
################################################################################
create_names <- function(prefix){
  names <- paste0(prefix, c("Paxlovid", "Sotrovimab", "Molnupiravir"), "_all_ci.csv")
  names(names) <- c("Paxlovid", "Sotrovimab", "Molnupiravir")
  names
}
coefs <- map(.x = create_names("psCoefs_"),
             .f = ~ read_csv(here::here("output", "descriptives", .x),
                             col_types = cols_only(
                               variable = col_character(),
                               estimate = col_double(),
                               lci = col_double(),
                               uci = col_double(),
                               abs_estimate = col_double())) %>% 
               filter(variable != "(Intercept)") %>%
               arrange(estimate))

################################################################################
# 1.0 Plot coefs
################################################################################
plot_coefs <- function(coefs){
  plot <- coefs %>% 
    ggplot(aes(estimate, reorder(variable, estimate))) +
    geom_segment(aes(yend = variable, x = lci, xend = uci), colour="blue") +
    geom_point(colour="blue", fill = "blue") +
    geom_vline(xintercept = 1, lty = 2) + 
    theme_bw() +
    xlab('Odds ratio') +
    ylab('Variable') 
  plot_abs <- coefs %>% 
    ggplot(aes(abs_estimate,reorder(variable, abs_estimate))) +
    geom_point(colour="darkorange", fill = "darkorange") +
    theme_bw() +
    xlab('|1-Odds ratio|') +
    ylab('') 
  plot_grid(plot, plot_abs, labels = c('A', 'B'))
}
plots <- 
  map(.x = coefs,
      .f = ~ plot_coefs(.x))

################################################################################
# 2.0 Save plots
################################################################################
iwalk(.x = plots,
      .f = ~ ggsave(
        .x,
        filename = fs::path(output_dir, paste0("psCoefs_", .y, "_all_ci.png")),
        width = 25, height = 20, units = "cm"))
