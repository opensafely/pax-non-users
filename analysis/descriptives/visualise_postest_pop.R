################################################################################
#
# Visualise characteristics pos test pop
# 
# The output of this script is:
# csv file ./output/descriptives/figures/postest_pop_x/*.png
# where x is all or untrt
# where * is e.g. agegroup; sex, imd etc.
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(readr)
library(dplyr)
library(fs)
library(here)
library(purrr)
library(patchwork)
library(ggplot2)
source(here::here("lib", "design", "covars_postest_pop.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives", "figures")
output_dir_all <- here::here("output", "descriptives", "figures", "postest_pop_all")
output_dir_untrt <- here::here("output", "descriptives", "figures", "postest_pop_untrt")
fs::dir_create(output_dir)
fs::dir_create(output_dir_all)
fs::dir_create(output_dir_untrt)

################################################################################
# 0.2 Import data
################################################################################
postest_pop <- read_csv(here("output", "descriptives", "postest_pop_red.csv"),
                             col_types = cols_only(
                               group = col_character(),
                               variable = col_character(),
                               All = col_character(),
                               Untreated = col_character(),
                               period = col_integer()))

################################################################################
# 0.4 Data manipulation
################################################################################
postest_pop <-
  postest_pop %>%
  mutate(All = if_else(All == "[REDACTED]", "8", All),
         All = All %>% as.integer(),
         Untreated = if_else(Untreated == "[REDACTED]", "8", Untreated),
         Untreated = Untreated %>% as.integer(),
         variable = if_else(is.na(variable), "Yes", variable),
         period = case_when(period == 1 ~ "Feb",
                            period == 2 ~ "Mar",
                            period == 3 ~ "Apr",
                            period == 4 ~ "May",
                            period == 5 ~ "Jun",
                            period == 6 ~ "Jul",
                            period == 7 ~ "Aug",
                            period == 8 ~ "Sep",
                            period == 9 ~ "Oct",
                            period == 10 ~ "Nov",
                            period == 11 ~ "Dec",
                            period == 12 ~ "Jan") %>% 
           factor(levels = c("Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan")))
total_n <-
  postest_pop %>%
  filter(group == "N") %>%
  select(All, Untreated, period) %>%
  rename(n_total = All,
         n_total_untrt = Untreated)
postest_pop <-
  postest_pop %>%
  filter(group != "N") %>%
  left_join(total_n, by = "period")
# because want bars for proportions of people who don't have the condition
postest_pop_not_binary_condition <- 
  postest_pop %>%
    filter(variable == "Yes") %>%
    transmute(group,
              variable = "No",
              All = n_total - All,
              Untreated = n_total_untrt - Untreated,
              period, n_total, n_total_untrt)
postest_pop <-
  postest_pop %>%
  bind_rows(postest_pop_not_binary_condition) %>%
  arrange(period, group, variable) %>%
  mutate(prop = All / n_total,
         prop_untrt = Untreated / n_total_untrt)

################################################################################
# 1.1 Make prop bar chart characteristics
################################################################################
plot_n_postest <-
  ggplot(total_n, aes(x = n_total, y = period)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_minimal() +
  labs(x = "Number of positive tests",
       y = "Period") 

################################################################################
# 1.2 Make prop bar chart characteristics
################################################################################
plot_postest_pop <- function(data, characteristic, prop_var) {
  plot <-
    ggplot(data %>% filter(group == characteristic),
           aes(x = {{ prop_var }}, y = factor(period), fill = factor(variable))) +
    geom_bar(stat = "identity") +
    coord_flip() +
    theme_minimal() +
    scale_fill_discrete(name = characteristic) +
    labs(x = "Proportion of people (%)",
         y = "Period") 
}
plot_postest_pop_all_characteristics <- function(data, prop_var){
  groups <- postest_pop %>% pull(group) %>% unique()
  plots <- 
    map(.x = groups,
        .f = ~ plot_postest_pop(postest_pop, .x, {{ prop_var }}))
  names(plots) <- 
    groups %>% tolower() %>% 
    gsub(" ", "_", .) %>% 
    sub("/", "_", .) %>%
    sub("'", "", .) %>%
    sub("’", "", .) %>%
    sub("-", "_", .)
  names(plots)[which(names(plots) == "immune_mediated_inflammatory_disorders_(imid)")] <- "imid"
  plots
}
plots_all <- plot_postest_pop_all_characteristics(data, prop)
plots_untrt <- plot_postest_pop_all_characteristics(data, prop_untrt)

################################################################################
# 1.3 Combine graphs
################################################################################
aggregate_plots <- function(plots){
  plots_demographics <- 
    plots$age + plots$sex +
    plots$ethnicity + plots$imd +
    plots$region + plots$setting + plot_layout(ncol = 2)
  plots_clin <-
    plots$obesity + plots$smoking_status +
    plots$diabetes + plots$hypertension +
    plots$chronic_cardiac_disease + plots$copd +
    plots$dialysis + plots$severe_mental_illness +
    plots$learning_disability + plots$dementia +
    plots$autism + plots$care_home +
    plots$housebound + plot_layout(ncol = 2)
  plots_highrisk <-
    plots$downs_syndrome + plots$solid_cancer +
    plots$haematological_diseases + plots$ckd_stage_5 +
    plots$liver_disease + plots$imid +
    plots$immune_deficiencies + plots$hiv_aids +
    plots$solid_organ_transplant + plots$multiple_sclerosis +
    plots$motor_neurone_disease + plots$myasthenia_gravis +
    plots$huntingtons_disease + plot_layout(ncol = 2)
  plots_vax <- 
    plots$vaccination_status + plots$most_recent_vaccination + 
    plot_layout(ncol = 2)
  out <- 
    list(plots_demographics, plots_clin, plots_highrisk, plots_vax)
  names(out) <- c("demographics", "clin", "highrisk", "vax")
  out
}
plots_all_aggregated <- aggregate_plots(plots_all)
plots_untrt_aggregated <- aggregate_plots(plots_untrt)

################################################################################
# 2.0 Save output
################################################################################
ggsave(plot_n_postest,
       filename = fs::path(output_dir, "postest_pop_n.png"),
       device = "png",
       bg = "white")
iwalk(.x = plots_all,
      .f = ~ ggsave(.x,
                    filename = fs::path(output_dir_all, paste0(.y, ".png")),
                    device = "png",
                    bg = "white"))
iwalk(.x = plots_untrt,
      .f = ~ ggsave(.x,
                    filename = fs::path(output_dir_untrt, paste0(.y, ".png")),
                    device = "png",
                    bg = "white"))
save_aggregated_plots <- function(plots_aggregated, output_dir, height) {
  iwalk(.x = plots_aggregated,
        .f = ~ ggsave(.x,
                      filename = fs::path(output_dir, paste0(.y, ".png")),
                      device = "png",
                      width = 350,
                      height = height,
                      units = "mm",
                      bg = "white"))
}
save_aggregated_plots(list(clin = plots_all_aggregated$clin, highrisk = plots_all_aggregated$highrisk),
                      output_dir_all,
                      875)
save_aggregated_plots(list(demographics = plots_all_aggregated$demographics),
                      output_dir_all,
                      250)
save_aggregated_plots(list(vax = plots_all_aggregated$vax),
                      output_dir_all,
                      125)
save_aggregated_plots(list(clin = plots_untrt_aggregated$clin, highrisk = plots_untrt_aggregated$highrisk),
                      output_dir_untrt,
                      875)
save_aggregated_plots(list(demographics = plots_untrt_aggregated$demographics),
                      output_dir_untrt,
                      250)
save_aggregated_plots(list(vax = plots_untrt_aggregated$vax),
                      output_dir_untrt,
                      125)
