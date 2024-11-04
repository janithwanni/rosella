library(tidyverse)
library(randomForest)

dataset <- readRDS(here::here("vis_xai_unify/dataset.rds"))
dataset_scaled <- dataset |> mutate(across(x:z, \(x) scale(x)[, 1]))


rf_model <- randomForest(cluster ~ x + y + z, data = dataset_scaled)
saveRDS(rf_model, here::here("vis_xai_unify/rf_model.rds"))

dataset_scaled$preds <- predict(rf_model, newdata = dataset_scaled)
saveRDS(dataset_scaled, here::here("vis_xai_unify/dataset_scaled.rds"))