library(kultarr)
library(randomForest)
library(tidyverse)

dataset <- readRDS(here::here("vis_xai_unify/dataset_scaled.rds"))
rf_model <- readRDS(here::here("vis_xai_unify/rf_model.rds"))

model_func <- function(model, data) {
  return(predict(model, data))
}

progressr::with_progress({
    final_bounds <- make_anchors(
        rf_model,
        dataset = dataset,
        cols = dataset |> select(x:z) |> colnames(),
        instance = seq_len(nrow(dataset)),
        model_func = model_func,
        class_col = "cluster",
        verbose = FALSE,
        seed = 145,
        n_games = 20,
        n_epochs = 50
    )
})

# sanity fix
# final_bounds <- final_bounds |> replace_na(list(x = 0, y = 0, z = 0))

saveRDS(final_bounds, here::here("vis_xai_unify/anchors_bounds.rds"))
