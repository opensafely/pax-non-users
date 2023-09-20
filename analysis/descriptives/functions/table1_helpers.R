add_period <- function(table1, name){
  map(.x = table1,
      .f = ~ .x %>% mutate(period = name))
}
remove_all_cat <- function(table1){
  map(.x = table1,
      .f = ~ .x %>% select(-starts_with("All")))
}
combine_tables <- function(table1){
  table_types = c("table1", "table1_red","table1_red_unf")
  table1 <- map(
    .x = table_types,
    .f = ~ rbind(
      table1[["period1"]][[.x]],
      table1[["period2"]][[.x]],
      table1[["period3"]][[.x]],
      table1[["period4"]][[.x]]))
  names(table1) <- table_types
  table1 <- map(
    .x = table1,
    .f = ~ .x %>%
      pivot_wider(
        names_from = period,
        names_glue = "{period}_{.value}",
        values_from = -names(.)[1:2]
      ) %>%
      select(-ends_with("_period")) %>%
      relocate(group, variable, starts_with("period1"), starts_with("period2"), starts_with("period3"), starts_with("period4"))
  )
  table1
}