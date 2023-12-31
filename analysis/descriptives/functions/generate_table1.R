library('gt')
library('gtsummary')
source(here::here("analysis", "descriptives", "functions", "clean_table_names.R"))
source(here::here("lib", "design", "redaction.R"))
generate_table1 <- function(data_table, pop_levels) {
  for (pop_level in pop_levels) {
    if (pop_level != "All"){
      data_summary <-
        data_table %>%
        filter(treatment_strategy_cat_prim %in% pop_level)
    } else data_summary <- data_table
    data_summary <- 
      data_summary %>% 
      mutate(N = 1, allpop = "All") %>%
      select(-treatment_strategy_cat_prim) %>% 
      tbl_summary(by = allpop,
                  statistic = everything() ~ "{n}")
    table1 <- 
      data_summary$table_body %>%
      filter(!is.na(stat_1)) %>%
      mutate(label = if_else(var_type == "dichotomous", "", label)) %>%
      select(group = variable, variable = label, count = stat_1) %>%
      mutate(count = case_when(!is.na(count) ~ as.numeric(gsub(",", "", count)),
                               TRUE ~ NA_real_)) %>%
      mutate(percent = round(count / data_summary$N * 100, 1)) %>%
      clean_table_names()
    # Calculate rounded total
    rounded_n = plyr::round_any(data_summary$N, rounding_threshold)
    # Round individual values to rounding threshold
    table1_redacted <- table1 %>%
      mutate(count = plyr::round_any(count, rounding_threshold),
             percent = round(count / rounded_n * 100, 1),
             non_count = rounded_n - count)
    # Redact any rows with rounded cell data or non-data <= redaction threshold
    table1_redacted_formatted <-
      table1_redacted %>%
      mutate(summary = paste0(prettyNum(count, big.mark = ","),
                              " (",
                              format(percent, nsmall = 1), "%)") %>%
               gsub(" ", "", .,  fixed = TRUE) %>% # Remove spaces generated by decimal formatting
               gsub("(", " (", ., fixed = TRUE)) %>% # Add first space before (
      mutate(summary = if_else((count >= 0 & count <= redaction_threshold) | 
                                 (non_count >= 0 & non_count <= redaction_threshold),
                               "[Redacted]", 
                               summary)) %>%
      mutate(summary = if_else(group == "N",
                               prettyNum(count, big.mark = ","),
                               summary)) %>%
      select(-non_count, -count, -percent) %>%
      rename("{pop_level}" := summary)
    table1 <-
      table1 %>%
      select(-percent) %>%
      rename("{pop_level}" := count)
    table1_redacted <-
      table1_redacted %>%
      mutate(count = if_else((count >= 0 & count <= redaction_threshold) |
                               (non_count >= 0 & non_count <= redaction_threshold & group != "N"),
                               "[Redacted]",
                             count %>% as.character()),
             percent = if_else(count == "[Redacted]", "[Redacted]", percent %>% as.character())) %>%
      select(-non_count) %>%
      rename("{pop_level}" := count,
             "{pop_level} (percent)" := percent)
    # collate table
    if (pop_level == "All") { 
      collated_table = table1_redacted_formatted
      collated_table_unformatted = table1_redacted
      collated_table_unred = table1
    } else { 
      collated_table = collated_table %>% 
        left_join(table1_redacted_formatted, 
                  by = c("group", "variable"))
      collated_table_unformatted = collated_table_unformatted %>% 
        left_join(table1_redacted, 
                  by = c("group", "variable"))
      collated_table_unred = collated_table_unred %>% 
        left_join(table1, 
                  by = c("group", "variable"))
    }
  }
  list(table1 = collated_table_unred,
       table1_red = collated_table,
       table1_red_unf = collated_table_unformatted)
}
