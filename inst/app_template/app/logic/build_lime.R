library(randomForest)
library(tidyverse)
library(DALEXtra)
library(lime)

dataset_scaled <- readRDS(here::here("app/data/dataset_scaled.rds"))
rf_model <- readRDS(here::here("app/data/rf_model.rds"))

w_rf_exp <- DALEX::explain(
  model = rf_model,
  data = dataset_scaled,
  y = dataset_scaled$cluster == "A"
)

model_type.dalex_explainer <- DALEXtra::model_type.dalex_explainer
predict_model.dalex_explainer <- DALEXtra::predict_model.dalex_explainer

model_type.randomForest.formula <- function(x, ...) "classification"
predict_model.randomForest.formula <- function(x, newdata, type, ...) {
  library(randomForest)
  res <- predict(x, newdata = newdata, ...)
  return(res)
}

# library(furrr)
# library(progressr)
# plan(multisession)

lime_vals <- list()
for (i in seq_len(nrow(dataset_scaled))) {
  print(i)
  obs <- dataset_scaled[i, ]
  lime_vals[[i]] <- predict_surrogate(
      explainer = w_rf_exp,
      new_observation = obs,
      n_features = 2,
      n_permutations = 100,
      type = "lime"
    ) |> mutate(index = i)
}

lime_vals_df <- lime_vals |> list_rbind()
# with_progress({
#   p <- progressor(steps = nrow(dataset_scaled))
#   lime_vals <- future_map(seq_len(nrow(dataset_scaled)), function(i) {
#     library(randomForest)
#     model_type.dalex_explainer <- DALEXtra::model_type.dalex_explainer
#     predict_model.dalex_explainer <- DALEXtra::predict_model.dalex_explainer

#     model_type.randomForest <- function(x, ...) "classification"
#     predict_model.randomForest <- function(x, newdata, type, ...) {
#       library(randomForest)
#       res <- predict(x, newdata = newdata, ...)
#       return(res)
#     }
#     obs <- dataset_scaled[i, ]
#     w_lime <- predict_surrogate(
#       explainer = w_rf_exp,
#       new_observation = obs,
#       n_features = 3,
#       n_permutations = 100,
#       type = "lime"
#     ) |> mutate(index = i)
#     p()
#   }) |> list_rbind()
# })

saveRDS(lime_vals_df, here::here("app/data/lime_vals.rds"))
