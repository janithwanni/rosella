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
    observeEvent
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
)

box::use(
  app/logic/utils[get_scale_factor],
)

#' @export 
ui <- function(id) {
  ns <- NS(id)
  tags$div(
    class = "plot-carousel",
    tags$div(
      class = "card-container",
      "To be built",
      plotOutput(ns("lime_importances"))
    ),
    tags$div(
      class = "card-container",
      "To be built"
    )
  )
}

#' @export 
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    output$lime_importances <- renderPlot({
    })

    observeEvent(list(state$current_id, state$xai_selected), {
      req(!is.null(state$current_id), state$xai_selected == "cfact")
      # TODO: implement changes to be made to the detourr object
    })
  })
}