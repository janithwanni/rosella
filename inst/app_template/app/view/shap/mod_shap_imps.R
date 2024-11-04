box::use(
  shiny[
    bootstrapPage,
    div,
    moduleServer,
    NS,
    renderPlot,
    tags,
    plotOutput,
    req,
    observeEvent,
    HTML
  ],
  r/core[...],
  dplyr[filter, glimpse, select, rename, pull],
  detourr[
    display_scatter_proxy,
    add_points,
    add_edges,
    enlarge_points,
    clear_points,
    clear_edges,
    clear_highlight,
    clear_enlarge
  ],
  glue[glue],
)

box::use(
  app/logic/shap_utils[load_shap_data, plot_shap_importances],
  app/logic/utils[init_par_coord_plot, get_scale_factor],
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  tags$div(
    class = "plot-carousel",
    tags$div(
      class = "card-container",
      plotOutput(ns("shap_importances"))
    ),
    tags$div(
      class = "card-container",
      tags$div(
        class = "svg-container",
        HTML("
          <svg 
            id='shap-parcoord' 
            class='svg-content-responsive' 
            viewBox='0 0 400 400' 
            preserveAspectRatio='xMinYMin meet'>
          </svg>
        "),
        tags$script(
          glue(
            "Shiny.setInputValue(
              '{{ns(\"\")}shap_parcoord_rendered', {is_rendered: true}, {priority: 'event'}
            )",
            .open = "{{"
          )
        )
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    shap_data <- load_shap_data()

    output$shap_importances <- renderPlot({
      req(!is.null(state$current_id))
      plot_shap_importances(shap_data$shap |> filter(id == state$current_id))
    })

    observeEvent(input$shap_parcoord_rendered, {
      req(input$shap_parcoord_rendered == TRUE)
      init_par_coord_plot(
        session,
        data = shap_data$shap |> select(id, x, y, z, color = cls_color),
        svg_id = "shap-parcoord",
        message_id = "setup-shap-par-coord"
      )
    })

    observeEvent(list(state$current_id, state$xai_selected), {
      req(state$xai_selected == "shap")
      if (is.null(state$current_id)) {
        session$sendCustomMessage("toggle-highlight-shap-path", list(
          highlight = FALSE
        ))
        display_scatter_proxy(state$detour_id) |>
          clear_points() |>
          clear_edges() |>
          clear_highlight() |>
          clear_enlarge()
      }
      req(!is.null(state$current_id))
      session$sendCustomMessage("toggle-highlight-shap-path", list(
        highlight = TRUE,
        id = state$current_id
      ))
      # TODO: Implement the changes to detourr from here
      current_data <- state$tour_data |> filter(id == state$current_id) |> select(x:z)
      current_shap <- shap_data$shap |> filter(id == state$current_id)
      point_data <- data.frame(
        x = c(current_shap$x, current_data$x, current_data$x),
        y = c(current_data$y, current_shap$y, current_data$y),
        z = c(current_data$z, current_data$z, current_shap$z)
      )
      display_scatter_proxy(state$detour_id) |>
        clear_points() |>
        clear_edges() |>
        clear_highlight() |>
        clear_enlarge() |>
        add_points(
          rbind(
            current_data,
            point_data
          ),
          scale_attr = list("scaled:center" = rep(0, 3)),
          scale_factor = get_scale_factor(state$tour_data),
          colour = c(state$tour_data$cls_color[state$current_id], "black")
        ) |>
        add_edges(data.frame(from = rep(1, 3), to = seq(2, 4))) |>
        enlarge_points(state$tour_data$id[state$current_id])
    })
  })
}