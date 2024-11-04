box::use(
  here[here],
  dplyr[left_join, rename, mutate, select, group_by, slice_max, ungroup],
  tidyr[pivot_longer],
  tibble[tibble],
  ggplot2[
    ggplot,
    aes,
    geom_bar,
    theme_minimal,
    labs,
    theme,
    element_text,
    geom_point,
    geom_jitter
  ],
  glue[glue],
)

box::use(
  app/logic/constants[green, orange],
  app/logic/utils[load_tour_data],
)

#' @export
load_counterfact_data <- function() {
  saved_file <- here("app/data/counter_facts.rds")
  saved_results <- readRDS(saved_file)
  original_data <- load_tour_data()
  cf_data <- original_data |>
    left_join(
      saved_results |>
        rename(
          cx = x,
          cy = y,
          cz = z,
          id = index
        ) |>
        mutate(cf_target = factor(ifelse(preds == "A", "B", "A"))) |>
        select(-preds),
      by = c("id")
    ) |>
    mutate(cf_target_color = ifelse(cf_target == "A", orange, green))
}

#' @export
calc_dim_diffs <- function(data) {
  data |> mutate(
    dx = (data$cx - data$x),
    dy = (data$cy - data$y),
    dz = (data$cz - data$z),
    mac = ((x + y + z) / 3)
  )
}

#' @export
plot_dim_diffs <- function(dim_diffs) {
  dim_diffs |>
    pivot_longer(cols = dx:dz, names_to = "dim", values_to = "diff") |>
    ggplot(aes(x = diff, y = dim)) +
    geom_bar(stat = "identity") +
    theme_minimal() +
    labs(
      x = "Variable",
      y = "Absolute difference",
      title = "Absolute difference between counterfactual and original by dimension",
      subtitle = "Larger differences mean more important",
      caption = glue(
        "Mean absolute difference {round(unique(dim_diffs$mac), 3)}"
      )
    ) +
    theme(plot.caption = element_text(hjust = 0))
}
