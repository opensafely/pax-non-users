################################################################################
#
# KAPLAN MEIER CURVES
#
#
################################################################################

################################################################################
# 0.0 Import libraries + functions
################################################################################
library(ggplot2)
library(purrr)
library(dplyr)
library(readr)

################################################################################
# 0.2 Create directories for output
################################################################################
output_dir <- here::here("output", "seq_trials", "descriptives", "figures")
fs::dir_create(output_dir)

################################################################################
# 0.3 Search files + read
################################################################################
files <- 
  list.files(here::here("output", "seq_trials", "descriptives", "survival"),
             pattern = "_red2.csv$", 
             full.names = TRUE)
km_estimates <- 
  map(.x = files,
      .f = ~ read_csv(.x, 
                      col_types = cols_only(.subgroup_var = col_character(),
                                            .subgroup = col_factor(),
                                            arm = col_factor(),
                                            tstart = col_integer(),
                                            tend = col_integer(),
                                            surv = col_double(),
                                            surv.low.approx = col_double(),
                                            surv.high.approx = col_double())) %>%
        mutate(arm_descr = if_else(arm == 1, "Treated", "Untreated")))
km_estimates[[2]] <-
  km_estimates[[2]] %>%
  mutate(.subgroup = "All periods")


################################################################################
# 0.4 Function plotting KMs
################################################################################
km_plot_rounded <- function(.data) {
  .data %>%
    group_by(.subgroup, arm_descr, arm) %>%
    group_modify(
      ~ add_row(
        .x,
        tstart = 0, # assumes time origin is zero
        tend = 0,
        surv = 1,
        surv.low.approx = 1,
        surv.high.approx = 1,
        .before = 0
      ),
    ) %>%
    ungroup() %>%
    ggplot(aes(x = tend, y = surv, group = arm_descr, colour = arm_descr)) +
    geom_step() +
    #geom_rect(aes(xmin = tstart, xmax = tend, ymin = surv.low.approx, ymax = surv.high.approx), alpha = 0.1, colour = "transparent") +
    facet_grid(rows = vars(.subgroup)) +
    scale_color_brewer(type = "qual", palette = "Set1", na.value = "grey") +
    scale_y_continuous(limits = limits_y, breaks = breaks_y, labels = lbs_y) +
    scale_x_continuous(limits = c(0, 28), breaks = c(0, 7, 14, 21, 28)) +
    #coord_cartesian(xlim = c(0, NA)) +
    labs(
      x = "Days since origin",
      y = "Survival",
      colour = NULL,
      title = NULL
    ) +
    theme_minimal() +
    theme(
      axis.line.x = element_line(colour = "black"),
      panel.grid.minor.x = element_blank(),
      legend.text = element_text(size = 7),
      axis.title = element_text(size = 9),
      strip.text.x = element_text(size = 30),
      strip.background =element_rect(fill="grey")
    )
}
limits_y <- c(0.95, 1)
breaks_y <- seq(0.95, 1, 0.01)
lbs_y <- ifelse(breaks_y %in% c(0.95, 1.00), format(breaks_y, digits = 2, nsmall = 1), "")
plots <- 
  map(.x = km_estimates,
      .f = ~ km_plot_rounded(.x))

ggsave(plots[[1]], 
       filename = fs::path(output_dir, "km_period.png"),
       width = 20,
       height = 30,
       units = "cm",
       bg = "white")

ggsave(plots[[2]], 
       filename = fs::path(output_dir, "km.png"),
       width = 20,
       height = 10,
       units = "cm",
       bg = "white")
