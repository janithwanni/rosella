box::use(
  r/core[...],
  here[here],
  dplyr[mutate, row_number, select, filter],
)

box::use(
  app/logic/constants[green, orange],
)

#' @export
load_tour_data <- function() {
  dataset <- readRDS(here("app/data/dataset_scaled.rds")) |>
    mutate(id = row_number())

  tour_data <- dataset |>
    mutate(cls_color = ifelse(cluster == "A", orange, green))

  return(tour_data)
}

#' @export
filter_saved_points_table <- function(dataset, selected_ids) {
  saved_table <- dataset |>
    filter(id %in% selected_ids) |>
    select(id, x, y, z, cluster)

  if (length(selected_ids) != 0) {
    return(saved_table[match(selected_ids, saved_table$id), ])
  }
  return(saved_table)
}

#' @export
get_scale_factor <- function(x) {
  xs <- x |> select(x:z) |> scale(scale = FALSE)
  return(1 / max(sqrt(rowSums(xs^2))))
}

#' @export
get_scale_attributes <- function(x) {
  xs <- x |> select(x:z) |> scale(scale = FALSE)
  return(attributes(xs))
}

#' @export
init_par_coord_plot <- function(session, data, svg_id, message_id) {
  session$sendCustomMessage(message_id, list(
    data = data,
    ns = session$ns(""),
    svg_id = svg_id
  ))
}