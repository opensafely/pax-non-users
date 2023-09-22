################################################################################
#
# Visualise output ps models
# 
# The output of this script is:
# png file ./output/descriptives/figures/psOverlap_trimmed_treatment_population.png
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

################################################################################
# 0.1 Create directories for output
################################################################################
output_dir <- here::here("output", "descriptives")
fs::dir_create(output_dir)
if(Sys.getenv("OPENSAFELY_BACKEND") == ""){
  output_dir <- here::here("output", "descriptives", "figures")
  fs::dir_create(output_dir)
}

################################################################################
# 0.2 Import data
################################################################################
create_names <- function(prefix){
  names <- paste0(prefix, c("Paxlovid", "Sotrovimab", "Molnupiravir"), "_all_ci.csv")
  names(names) <- c("Paxlovid", "Sotrovimab", "Molnupiravir")
  names
}
dens <- map(.x = create_names("psDens_untrimmed_"),
             .f = ~ read_csv(here::here("output", "descriptives", .x),
                             col_types = cols_only(
                               trtlabel = col_character(),
                               dens_x = col_double(),
                               dens_y = col_double(),
                               analysis = col_character())))
dens_trimmed <- map(.x = create_names("psDens_trimmed_"),
                    .f = ~ read_csv(here::here("output", "descriptives", .x),
                                    col_types = cols_only(
                                      trtlabel = col_character(),
                                      dens_x = col_double(),
                                      dens_y = col_double(),
                                      analysis = col_character())))

############################################################################
# 1.0 Plot densities
############################################################################
plot_density <- function(dens){
  dens %>%
    ggplot(aes(x = dens_x, y = dens_y, linetype = trtlabel)) +
    geom_line() +
    xlab('Probability of receiving treatment') +
    ylab('Density') +
    scale_fill_discrete('') +
    scale_color_discrete('') +
    theme(strip.text = element_text(colour ='black')) +
    theme_bw() +
    scale_x_continuous(breaks=seq(0,1,0.1), limits=c(0,1)) +
    theme(legend.title = element_blank(),
          legend.position = c(.9,.9),
          legend.direction = 'vertical', 
          panel.background = element_rect(fill = "white", colour = "white"),
          axis.line = element_line(colour = "black"),
          panel.border = element_blank(),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
}
plots <- 
  map(.x = dens,
      .f = ~ plot_density(.x))
plots_trimmed <- 
  map(.x = dens_trimmed,
      .f = ~ plot_density(.x))

############################################################################
# 2.0 Save plots
############################################################################
iwalk(
  .x = plots,
  .f = ~ ggsave(
    .x,
    filename = fs::path(output_dir, paste0("psOverlap_untrimmed_", .y, "_all_ci.png")),
    width = 12, height = 10, units = "cm"
  )
)
iwalk(
  .x = plots_trimmed,
  .f = ~ ggsave(
    .x,
    filename = fs::path(output_dir, paste0("psOverlap_trimmed_", .y, "_all_ci.png")),
    width = 12, height = 8, units = "cm"
  )
)
