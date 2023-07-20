################################################################################
#
# Visualise characteristics pos test pop
# 
# The output of this script is:
# csv file ./output/descriptives/figures/postest_pop_*.png
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
source(here::here("lib", "design", "covars_postest_pop.R"))

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives", "figures")
fs::dir_create(output_dir)

################################################################################
# 0.2 Import data
################################################################################
postest_pop <- read_csv(here("output", "descriptives", "postest_pop_red.csv"),
                             col_types = cols_only(
                               group = col_character(),
                               variable = col_character(),
                               All = col_character(),
                               period = col_integer()))

################################################################################
# 0.4 Data manipulation
################################################################################
postest_pop <-
  postest_pop %>%
  mutate(All = if_else(All == "[REDACTED]", "8", All),
         All = All %>% as.integer(),
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
  select(All, period) %>%
  rename(n_total = All)
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
              period, n_total)
postest_pop <-
  postest_pop %>%
  bind_rows(postest_pop_not_binary_condition) %>%
  arrange(period, group, variable) %>%
  mutate(prop = All / n_total)


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
plot_postest_pop <- function(data, characteristic) {
  plot <-
    ggplot(data %>% filter(group == characteristic),
           aes(x = prop, y = factor(period), fill = factor(variable))) +
    geom_bar(stat = "identity") +
    coord_flip() +
    theme_minimal() +
    scale_fill_discrete(name = characteristic) +
    labs(x = "Proportion of people (%)",
         y = "Period") 
}
groups <- postest_pop %>% pull(group) %>% unique()
plots <- 
  map(.x = groups,
      .f = ~ plot_postest_pop(postest_pop, .x))
names(plots) <- 
  groups %>% tolower() %>% 
  gsub(" ", "_", .) %>% 
  sub("/", "_", .) %>%
  sub("'", "", .) %>%
  sub("’", "", .) %>%
  sub("-", "_", .)
names(plots)[which(names(plots) == "immune_mediated_inflammatory_disorders_(imid)")] <- "imid"

################################################################################
# 1.3 Combine graphs
################################################################################
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
  

################################################################################
# 2.0 Save output
################################################################################
ggsave(plot_n_postest,
       filename = fs::path(output_dir, "postest_pop_n.png"),
       device = "png",
       bg = "white")
iwalk(.x = plots,
      .f = ~ ggsave(.x,
                    filename = fs::path(output_dir, paste0("postest_pop_", .y, ".png")),
                    device = "png",
                    bg = "white"))
ggsave(plots_demographics,
       filename = fs::path(output_dir, "postest_pop_demographics.png"),
       width = 350,
       height = 250,
       units = "mm",
       bg = "white")
ggsave(plots_clin,
       filename = fs::path(output_dir, "postest_pop_clin.png"),
       width = 350,
       height = 875,
       units = "mm",
       bg = "white")
ggsave(plots_highrisk,
       filename = fs::path(output_dir, "postest_pop_highrisk.png"),
       width = 350,
       height = 875,
       units = "mm",
       bg = "white")
ggsave(plots_vax,
       filename = fs::path(output_dir, "postest_pop_vax.png"),
       width = 350,
       height = 125,
       units = "mm",
       bg = "white")
