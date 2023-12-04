################################################################################
#
# Visualise survival curuves
# 
# The output of this script is:
# csv file ./output/seq_trials/itt/curves/figures/itt_survcurve.png
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
library(ggpattern) 

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "itt", "curves", "figures")
fs::dir_create(output_dir)

################################################################################
# 0.3 Import data
################################################################################
survcurves <- 
  read_csv(here("output", "seq_trials", "itt", "curves", "itt_survcurves_simple.csv"),
           col_types = cols_only(
             arm = col_double(),
             arm_descr = col_character(),
             tend = col_integer(),
             lead_tend = col_integer(),
             survival = col_double(),
             survival_ll = col_double(),
             survival_ul = col_double()))
diffcurve <- read_csv(here("output", "seq_trials", "itt", "curves", "itt_diffcurve_simple.csv"),
                      col_types = cols_only(
                        tend = col_integer(),
                        lead_tend = col_integer(),
                        diff = col_double(),
                        diff_ll = col_double(),
                        diff_ul = col_double()))
  

################################################################################
# 1.0 Make surv curve
################################################################################
surv_plot <- 
  survcurves %>%
  ggplot() +
  geom_step(aes(x = tend, y = survival * 1000, group = arm_descr, colour = arm_descr))+
  # geom_rect(aes(xmin = tend,
  #               xmax = lead_tend,
  #               ymin = survival_ll * 1000,
  #               ymax = survival_ul * 1000,
  #               group = arm_descr,
  #               fill = arm_descr), alpha = 0.1) +
  scale_x_continuous(
    breaks = seq(0, 28, by = 7),
    expand = expansion(0)
  )+
  scale_y_continuous(
    expand = expansion(0)
  )+
  scale_colour_brewer(type = "qual", palette = "Set1")+
  scale_fill_brewer(type = "qual", palette = "Set1", guide = "none")+
  labs(
    x = "Days since positive SARS-CoV-2 test",
    y = "Marginalised survival (per 1000 individuals)",
    colour = NULL,
    fill = NULL
  )+
  theme_bw()+
  theme(
    legend.position = c(.05,.05),
    legend.justification = c(0,0),
    axis.text.x.top = element_text(hjust=0)
  )

################################################################################
# 2.0 Make diff curve
################################################################################
diff_plot <- 
  diffcurve %>%
  ggplot() +
  geom_step(aes(x = tend, y = diff * 1000))+
  # geom_rect(aes(xmin = tend,
  #               xmax = lead_tend,
  #               ymin = diff_ll * 1000,
  #               ymax = diff_ul * 1000), alpha = 0.1) +
  scale_x_continuous(
    breaks = seq(0, 28, by = 7),
    expand = expansion(0)
  )+
  scale_y_continuous(
    expand = expansion(0)
  )+
  scale_colour_brewer(type = "qual", palette = "Set1")+
  scale_fill_brewer(type = "qual", palette = "Set1", guide = "none")+
  labs(
    x = "Days since positive SARS-CoV-2 test",
    y = "Difference in cumulative incidence (per 1000 individuals)",
    colour = NULL,
    fill = NULL
  )+
  theme_bw()+
  theme(
    legend.position = c(.05,.05),
    legend.justification = c(0,0),
    axis.text.x.top = element_text(hjust=0)
  )

################################################################################
# 3.0 Save output
################################################################################
ggsave(surv_plot,
       filename = path(output_dir, "surv.png"),
       device = "png",
       width = 12,
       height = 12,
       units = "cm",
       bg = "white")
ggsave(diff_plot,
       filename = path(output_dir, "diff.png"),
       device = "png",
       width = 12,
       height = 12,
       units = "cm",
       bg = "white")
