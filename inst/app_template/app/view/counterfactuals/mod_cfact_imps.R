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
    HTML,
    renderUI,
    uiOutput,
    reactiveVal
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
    clear_enlarge,
    displayScatter2dOutput,
    shinyRenderDisplayScatter2d,
    detour,
    tour_aes,
    tour_path,
    show_scatter
  ],
  tourr[grand_tour],
  glue[glue_safe, glue],
  shiny.semantic[multiple_radio, form],
)

box::use(
  app/logic/cfact_utils[
    plot_dim_diffs,
    calc_dim_diffs,
    load_counterfact_data
  ],
  app/logic/utils[get_scale_factor, init_par_coord_plot],
  app/logic/constants[green, orange],
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  tags$div(
    class = "plot-carousel",
    tags$div(
      class = "card-container",
      plotOutput(ns("cfact_importances")),
    ),
    tags$div(
      class = "card-container",
      tags$div(
        class = "svg-container",
        HTML("
          <svg 
            id='cf-parcoord' 
            class='svg-content-responsive' 
            viewBox='0 0 400 400' 
            preserveAspectRatio='xMinYMin meet'>
          </svg>
        "),
        tags$script(
          glue(
            "Shiny.setInputValue(
              '{{ns(\"\")}cf_parcoord_rendered', {is_rendered: true}, {priority: 'event'}
            )",
            .open = "{{"
          )
        )
      )
    ),
    tags$div(
      class = "card-container",
      tags$div(
        class = "detour-widget-container",
        id = "cfvecs-container",
        displayScatter2dOutput(
          ns("detourr_cfvecs_out"),
          width = "100%",
          height = "400px"
        ),
        uiOutput(ns("cfvec_cls_picker_ui"))
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    counterfact_data <- load_counterfact_data()
    dim_diffs <- calc_dim_diffs(counterfact_data)
    ns <- session$ns

    output$cfact_importances <- renderPlot({
      req(!is.null(state$current_id))
      plot_dim_diffs(
        dim_diffs |> filter(id == state$current_id)
      )
    })

    output$detourr_cfvecs_out <- shinyRenderDisplayScatter2d({
      req(!is.null(input$cf_vecs_cls_selected))
      # it's a hail mary screw race conditions
      session$sendCustomMessage("about-to-render-cfvec-detour", list(
        id = ns("detourr_cfvecs_out"),
        ns = ns("")
      ))
      detour(state$tour_data,
        tour_aes(projection = c(x:z), colour = cls_color, label = id)
      ) |>
        tour_path(grand_tour(2), fps = 30) |>
        show_scatter(
          palette = c(green, orange),
          alpha = 0.7,
          axes = TRUE,
          center = FALSE,
          size = 0.4
        )
    })

    observeEvent(list(input$cfvec_detour_rendered, input$cf_vecs_cls_selected), {
      print(input$cfvec_detour_rendered)
      print(input$cf_vecs_cls_selected)
      req(
        input$cfvec_detour_rendered$is_rendered == TRUE,
        !is.null(input$cf_vecs_cls_selected)
      )
      cf_rows <- counterfact_data |>
        filter(cluster == input$cf_vecs_cls_selected) |>
        select(x = cx, y = cy, z = cz)
      tour_rows <- state$tour_data |>
        filter(cluster == input$cf_vecs_cls_selected) |>
        select(x:z)
      point_data <- rbind(tour_rows, cf_rows)

      color_data <- c(
        rep(ifelse(
          input$cf_vecs_cls_selected == "A", orange, green
        ), nrow(tour_rows)),
        rep(ifelse(
          input$cf_vecs_cls_selected == "A", green, orange
        ), nrow(cf_rows))
      )

      edge_data <- data.frame(
        from = seq(1, nrow(tour_rows)),
        to = seq((nrow(tour_rows) + 1), (nrow(cf_rows) + nrow(tour_rows)))
      )
      display_scatter_proxy(ns("detourr_cfvecs_out")) |>
        clear_points() |>
        clear_edges() |>
        clear_highlight() |>
        clear_enlarge() |>
        add_points(
          point_data,
          scale_attr = list("scaled:center" = rep(0, 3)),
          scale_factor = get_scale_factor(state$tour_data),
          colour = color_data
        ) |>
        add_edges(edge_data)
    })

    output$cfvec_cls_picker_ui <- renderUI({
      form(
        multiple_radio(ns("cf_vecs_cls_selected"), label = "Cluster",
          choices = c(
            "A", "B"
          ),
          choices_value = c("A", "B"),
          selected = "A",
          position = "inline"
        )
      )
    })

    observeEvent(input$cf_parcoord_rendered, {
      req(input$cf_parcoord_rendered == TRUE)
      init_par_coord_plot(
        session,
        data = dim_diffs |> select(id, x = dx, y = dy, z = dz, color = cls_color),
        svg_id = "cf-parcoord",
        message_id = "setup-cf-par-coord"
      )
    })

    observeEvent(list(state$current_id, state$xai_selected), {
      req(state$xai_selected == "cfact")
      if (is.null(state$current_id)) {
        session$sendCustomMessage("toggle-highlight-cf-path", list(
          highlight = FALSE
        ))
        display_scatter_proxy(state$detour_id) |>
          clear_points() |>
          clear_edges() |>
          clear_highlight() |>
          clear_enlarge()
      }
      req(!is.null(state$current_id))
      session$sendCustomMessage("toggle-highlight-cf-path", list(
        highlight = TRUE,
        id = state$current_id
      ))
      display_scatter_proxy(state$detour_id) |>
        clear_points() |>
        clear_edges() |>
        clear_highlight() |>
        clear_enlarge() |>
        add_points(
          rbind(
            dim_diffs |>
              filter(id == state$current_id) |>
              select(cx:cz) |>
              rename(x = cx, y = cy, z = cz),
            dim_diffs |>
              filter(id == state$current_id) |>
              select(x:z)
          ),
          scale_attr = list("scaled:center" = rep(0, 3)),
          scale_factor = get_scale_factor(state$tour_data),
          colour = c(
            dim_diffs |>
              filter(id == state$current_id) |>
              pull(cf_target_color) |>
              unique(),
            dim_diffs |>
              filter(id == state$current_id) |>
              pull(cls_color) |>
              unique()
          )
        ) |>
        add_edges(data.frame(from = c(1), to = c(2))) |>
        enlarge_points(state$tour_data$id[state$current_id])
    })
  })
}