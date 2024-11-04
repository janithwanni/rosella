box::use(
  shiny[
    bootstrapPage,
    div,
    moduleServer,
    NS,
    renderUI,
    tags,
    plotOutput,
    renderPlot,
    req,
    isolate,
    HTML,
    uiOutput,
    observeEvent,
    renderText,
    textOutput
  ],
  shiny.semantic[slider_input],
  detourr[
    display_scatter_proxy,
    add_points,
    add_edges,
    highlight_points,
    enlarge_points,
    clear_points,
    clear_edges,
    clear_highlight,
    clear_enlarge
  ],
  geozoo[cube.iterate],
  tibble[tibble],
  dplyr[select],
  ggplot2[ggplot, aes, geom_bar, theme_minimal, labs, theme, element_text],
  glue[glue],
)

box::use(
  app/logic/utils[
    get_scale_attributes,
    get_scale_factor
  ],
  app/logic/anchor_utils[
    load_anchor_data,
    get_bounds,
    get_anchor,
    get_obs_in_bounds,
    init_anchor_plot,
    init_trajectory_plot
  ],
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  tags$div(
    class = "plot-carousel",
    tags$div(
      class = "card-container",
      plotOutput(ns("anchor_importances")),
    ),
    tags$div(
      class = "card-container",
      tags$div(
        class = "svg-container",
        HTML("<svg 
          id='anchor' 
          class='svg-content-responsive' 
          viewBox='0 0 400 400' 
          preserveAspectRatio='xMinYMin meet'></svg>
        "),
      )
    ),
    tags$div(
      class = "card-container",
      id = "trajectory-container",
      tags$div(
        class = "svg-container",
        HTML("
        <svg 
          id='trajectory' 
          class='svg-content-responsive' 
          viewBox='0 0 400 400' 
          preserveAspectRatio='xMinYMin meet'>
        ")
      ),
      tags$div(
        class = "game-slider-container",
        uiOutput(ns("game_slider_output"))
      )
    )
  )
}

#' @export
server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    saved_results <- load_anchor_data()
    saved_anchors <- saved_results$final_anchor
    reward_history <- saved_results$reward_history
    ns <- session$ns

    output$anchor_importances <- renderPlot({
      req(state$current_id != -1)
      bounds <- get_bounds(state$tour_data$id[state$current_id], saved_anchors, state$tour_data)
      dists <- bounds |> select(x:z) |> as.matrix() |> apply(2, \(x) x[2] - x[1])
      tibble(imps = dists, vars = factor(c("x", "y", "z"))) |>
        ggplot(aes(x = imps, y = vars)) +
        geom_bar(stat = "identity") +
        theme_minimal() +
        labs(
          x = "Variable",
          y = "Length of box",
          title = "Dimensions of box along dimensions",
          subtitle = "Longer lengths mean less important",
          caption = glue(
            "Precision: {unique(bounds$prec)}, 
            Coverage: {unique(bounds$cover)}, 
            Reward: {unique(bounds$reward)}"
          )
        ) +
        theme(plot.caption = element_text(hjust = 0))
    })

    output$game_slider_output <- renderUI({
      req(state$xai_selected == "anchor")
      init_anchor_plot(session, reward_history, isolate(state$tour_data$cls_color))
      init_trajectory_plot(session, reward_history)
      slider_opts <- range(reward_history$game)
      tags$div(
        tags$div(
          class = "ui pointing below label",
          "Current game: ", textOutput(ns("game_num"), inline = TRUE)
        ),
        slider_input(
          ns("game_slider"),
          min = slider_opts[1],
          max = slider_opts[2],
          value = slider_opts[2],
          step = 1,
          class = "ticked"
        )
      )
    })

    output$game_num <- renderText({input$game_slider})

    observeEvent(input$game_slider, {
      req(
        !is.null(input$game_slider),
        !is.null(state$current_id)
      )
      session$sendCustomMessage("animate-trajectory", list(
        id = state$current_id,
        game = input$game_slider,
        ns = session$ns("")
      ))
    })

    observeEvent(input$anchor_mouseover, {
      # TODO: check if this id matches with the dataset id
      state$hover_id <- input$anchor_mouseover$data$id
      print("received anchor_mouseover")
      print(input$anchor_mouseover$data$id)
    }, ignoreNULL = FALSE)

    observeEvent(input$anchor_mouseclick, {
      # TODO: check if this id matches with the dataset id
      # TODO: we might have to replicate this logic everywhere, refactor to R6 class
      anchor_click <- input$anchor_mouseclick$data$id
      if (!is.null(state$current_id)) {
        state$last_id <- state$current_id
      } else {
        state$last_id <- anchor_click
      }
      state$current_id <- anchor_click
      print("received anchor_mouseclick")
      print(input$anchor_mouseclick$data$id)
    }, ignoreNULL = FALSE)

    observeEvent(list(state$current_id, state$xai_selected), {
      req(state$xai_selected == "anchor")
      print("aha the current id changed")
      print(state$current_id)

      if (!is.null(state$current_id)) {
        bounds <- get_bounds(state$tour_data$id[state$current_id], saved_anchors, state$tour_data)
        box_to_send <- get_anchor(bounds)
        cube_box <- cube.iterate(p = 3)
        display_scatter_proxy(state$detour_id) |>
          clear_points() |>
          clear_edges() |>
          clear_highlight() |>
          clear_enlarge() |>
          add_points(
            box_to_send,
            scale_attr = list("scaled:center" = rep(0, 3)),
            scale_factor = get_scale_factor(state$tour_data),
            colour = state$tour_data$cls_color[state$current_id],
            size = 0.8,
            alpha = 0.8
          ) |>
          add_edges(
            edge_list = cube_box$edges
          ) |>
          highlight_points(
            get_obs_in_bounds(
              bounds,
              state$tour_data
            )
          ) |>
          enlarge_points(
            state$tour_data$id[state$current_id]
          )
      } else {
        print(state$detour_id)
        display_scatter_proxy(state$detour_id) |>
          clear_points() |>
          clear_edges() |>
          clear_highlight() |>
          clear_enlarge()

      }

      session$sendCustomMessage("animate-trajectory", list(
        id = state$current_id,
        game = input$game_slider
      ))
      session$sendCustomMessage("pulse-anchor", list(
        id = state$current_id,
        ns = session$ns("")
      ))
    }, ignoreNULL = FALSE)

    observeEvent(state$hover_id, {
      print("aha hover id changed")
      print(state$hover_id)
      session$sendCustomMessage("pulse-anchor", list(
        id = state$hover_id,
        ns = session$ns("")
      ))
    }, ignoreNULL = FALSE)

    # update the trajectory plot
    observeEvent(input$game_slider, {
      req(
        !is.null(input$game_slider),
        !is.null(state$current_id)
      )
      session$sendCustomMessage("animate-trajectory", list(
        id = state$current_id,
        game = input$game_slider,
        ns = session$ns("")
      ))
    })
  })
}