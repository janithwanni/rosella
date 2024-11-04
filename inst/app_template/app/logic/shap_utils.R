box::use(
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
  tidyr[pivot_longer],
  tibble[as_tibble, tibble],
  glue[glue],
  dplyr[
    row_number,
    left_join,
    mutate,
    select
  ],
)

box::use(
  app/logic/constants[green, orange],
  app/logic/utils[load_tour_data],
)

#'@export
load_shap_data <- function() {
  shap_data <- readRDS(here::here("app/data/shap_vals.rds"))
  original_data <- load_tour_data()
  out <- list(
    shap = shap_data$S$A |>
      as_tibble() |>
      mutate(id = row_number(), .before = 1) |>
      left_join(
        original_data |> select(id, cluster, cls_color),
        by = c("id")
      ),
    preds = tibble(pred = shap_data$predictions[, "A"]) |>
      mutate(id = row_number(), .before = 1)
  )
  return(out)
}

#' @export
plot_shap_importances <- function(shap) {
  shap |>
    pivot_longer(cols = x:z, names_to = "dim", values_to = "shap") |>
    ggplot(aes(x = shap, y = dim)) +
    geom_bar(stat = "identity") +
    theme_minimal() +
    labs(
      x = "Variable",
      y = "SHAP value",
      title = "SHAP values of each dimension",
      subtitle = "Larger values indicate higher importances"
    ) +
    theme(plot.caption = element_text(hjust = 0))
}
