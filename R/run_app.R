#' @title Spin up a Shiny app 
#' @description This function calls the shiny app contained within the `inst` folder
#' @param data dataset to be given
#' @param model model function to be given
#' @export
run_app <- function(data, model, .xai_folder = NULL) {
  # check if model is a function
  if(is.null(.xai_folder)) {
    # find default xai folder
    cli::cli_inform("Can not find {.var .xai_folder}")
  }
  app_location <- system.file("app_template/", package = "rosella")
  # copy the app folder into the base folder
  if(!dir.exists(here::here("shiny"))) {
    cli::cli_inform("Creating folder `shiny` in {here::here()}")
    dir.create(here::here("shiny"))
  }
  file.copy(app_location, here::here("shiny"), recursive = TRUE)
  withr::with_dir(here::here("shiny", "app_template"), {
    system2("R", "-e 'print(getwd());rhino::app()'")
  })
}