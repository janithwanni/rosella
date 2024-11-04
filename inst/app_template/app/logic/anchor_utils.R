box::use(
  dplyr[filter, select, mutate, between],
  tidyr[expand_grid, fill],
  here[here],
)

#' @export
load_anchor_data <- function() {
  saved_file <- here("app/data/anchors_bounds.rds")
  saved_results <- readRDS(saved_file)
  saved_results$reward_history <- saved_results$reward_history |>
    mutate(
      id = rep(seq(100), each = (50 * 20)),
      time = rep(seq((50 * 20)), times = 100)
    ) |>
    fill(prec, cover, .direction = "down")
  return(saved_results)
}

#' @export
get_bounds <- function(input_click, saved_anchors, dataset) {
  bounds <- saved_anchors |>
    mutate(idd = dataset$id[id]) |>
    filter(idd == input_click)
  return(bounds)
}

#' @export
init_anchor_plot <- function(session, reward_history, cluster_colors) {
  session$sendCustomMessage("setup-anchor", list(
    data = reward_history |>
      filter(
        game == 20, epoch == 50
      ) |>
      select(id, prec, cover) |>
      mutate(cls_color = cluster_colors),
    ns = session$ns("")
  ))
}

#' @export
init_trajectory_plot <- function(session, reward_history) {
  session$sendCustomMessage("setup-trajectory", list(
    data = reward_history,
    ns = session$ns("")
  ))
}

#' @export
get_anchor <- function(bounds) {
  bounds_list <- bounds |> select(x:z) |> as.list()
  do.call(expand_grid, bounds_list)
}

#' @export
get_obs_in_bounds <- function(bounds, data) {
  data$id <- seq_len(nrow(data))
  lower <- bounds[bounds$bound == "lower", ] |> select(x:z)
  upper <- bounds[bounds$bound == "upper", ] |> select(x:z)
  data <- data |>
    filter(
      between(x, lower$x, upper$x),
      between(y, lower$y, upper$y),
      between(z, lower$z, upper$z)
    )
  return(data$id)
}