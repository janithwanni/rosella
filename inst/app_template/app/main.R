box::use(
  shiny[
    req,
    bootstrapPage,
    div,
    moduleServer,
    NS,
    renderUI,
    tags,
    uiOutput,
    radioButtons,
    actionButton,
    reactiveValues,
    observeEvent,
    reactive,
    includeScript
  ],
  reactable[
    reactableOutput,
    renderReactable,
    reactable,
    colDef,
    colFormat,
    getReactableState,
    updateReactable
  ],
  dplyr[filter, select],
  tibble[tibble],
  detourr[
    displayScatter2dOutput,
    shinyRenderDisplayScatter2d,
    detour,
    tour_aes,
    tour_path,
    show_scatter
  ],
  tourr[grand_tour],
  shiny.semantic[multiple_radio, semanticPage, form],
)

box::use(
  app/logic/utils[
    load_tour_data,
    filter_saved_points_table
  ],
  app/logic/anchor_utils[get_anchor, get_bounds],
  app/logic/constants[green, orange],
  app/view/anchors/mod_anchor_imps,
  app/view/counterfactuals/mod_cfact_imps,
  app/view/lime/mod_lime_imps,
  app/view/shap/mod_shap_imps,
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  semanticPage(
    tags$div(
      class = "main-container",
      tags$script(src = "static/js/lib/popper.min.js"),
      tags$script(src = "static/js/lib/tippy-bundle.umd.js"),
      tags$script(src = "static/js/lib/d3.v7.js"),
      tags$script(src = "static/js/config.js"),
      tags$script(src = "static/js/globals.js"),
      tags$script(src = "static/js/d3_utils.js"),
      tags$script(src = "static/js/components/anchors/trajectory.js"),
      tags$script(src = "static/js/components/anchors/scatterplot.js"),
      tags$script(src = "static/js/components/par_coord.js"),
      tags$script(src = "static/js/components/counterfactuals/callbacks.js"),
      tags$script(src = "static/js/components/shap/callbacks.js"),
      tags$div(
        class = "title",
        tags$h3("XAI explorer")
      ),
      tags$div(
        class = "saved-points-container",
        "Saved points",
        reactableOutput(ns("saved_points")),
        tags$div(
          class = "controls-container",
          actionButton(ns("save_btn"), "Save current selection"),
          actionButton(ns("clear_all"), "Clear all")
        )
      ),
      tags$div(
        class = "detour-widget-container",
        displayScatter2dOutput(
          ns("detourr_out"),
          width = "100%",
          height = "500px"
        )
      ),
      tags$div(
        class = "xai-selector-container",
        form(
          multiple_radio(ns("xai_selected"), label = "XAI method",
            choices = c(
              "Anchors",
              "Counterfactual",
              "SHAP",
              "LIME"
            ),
            choices_value = c("anchor", "cfact", "shap", "lime"),
            selected = "anchor",
            position = "inline"
          )
        )
      ),
      tags$div(
        class = "plot-output-container",
        uiOutput(ns("plot_outputs"))
      )
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # setup_data
    tour_data <- load_tour_data()
    # define state
    state <- reactiveValues(
      selected_ids = c(),
      current_id = NULL,
      last_id = NULL,
      hover_id = NULL,
      detour = list(
        points = NULL,
        edges = NULL,
        highlight = NULL,
        enlarge = NULL
      ),
      tour_data = tour_data,
      saved_points_table = NULL,
      xai_selected = NULL,
      detour_id = ns("detourr_out")
    )

    output$detourr_out <- shinyRenderDisplayScatter2d({
      detour(tour_data,
        tour_aes(projection = c(x:z), colour = cls_color, label = id)
      ) |>
        tour_path(grand_tour(2), fps = 30) |>
        show_scatter(
          palette = c(green, orange),
          alpha = 0.7,
          axes = TRUE,
          center = FALSE
        )
    })

    output$saved_points <- renderReactable({
      reactable(
        filter_saved_points_table(tour_data, c()),
        columns = list(
          id = colDef(),
          x = colDef(format = colFormat(digits = 4)),
          y = colDef(format = colFormat(digits = 4)),
          z = colDef(format = colFormat(digits = 4)),
          cluster = colDef(style = function(value) {
            return(list(background = ifelse(value == "A", orange, green), color = "white"))
          })
        ),
        selection = "single",
        onClick = "select"
      )
    })

    output$plot_outputs <- renderUI({
      req(input$xai_selected)
      state$xai_selected <- input$xai_selected
      if (input$xai_selected == "anchor") {
        return(mod_anchor_imps$ui(ns("anchor_imp")))
      }

      if (input$xai_selected == "cfact") {
        return(mod_cfact_imps$ui(ns("cfact_imp")))
      }

      if (input$xai_selected == "lime") {
        return(mod_lime_imps$ui(ns("lime_imp")))
      }

      if (input$xai_selected == "shap") {
        return(mod_shap_imps$ui(ns("shap_imp")))
      }
    })

    observeEvent(input$detourr_out_detour_click, {
      detour_click <- input$detourr_out_detour_click
      if (!is.null(detour_click) && detour_click == -1) detour_click <- NULL
      if (!is.null(state$current_id)) {
        state$last_id <- state$current_id
      } else {
        state$last_id <- detour_click
      }
      state$current_id <- detour_click
    }, ignoreNULL = FALSE)

    observeEvent(state$current_id, {
      req(!is.null(state$current_id))
    })

    observeEvent(input$save_btn, {
      state$selected_ids <- c(state$selected_ids, state$current_id)
      saved_points_table <- filter_saved_points_table(tour_data, state$selected_ids)
      state$saved_points_table <- saved_points_table
      updateReactable(
        "saved_points",
        data = saved_points_table,
        selected = c(nrow(saved_points_table))
      )
    })

    observeEvent(getReactableState("saved_points", "selected"), {
      table_ids <- state$saved_points_table[["id"]]
      state$current_id <- table_ids[getReactableState("saved_points", "selected")]
    })

    mod_anchor_imps$server("anchor_imp", state)
    mod_cfact_imps$server("cfact_imp", state)
    mod_lime_imps$server("lime_imp", state)
    mod_shap_imps$server("shap_imp", state)
  })
}
