library(randomForest)
library(kernelshap)
library(tidyverse)

dataset_scaled <- readRDS(here::here("app/data/dataset_scaled.rds"))
rf_model <- readRDS(here::here("app/data/rf_model.rds"))

shap_vals <- permshap(
  rf_model,
  dataset_scaled |> select(x:z),
  bg_X = dataset_scaled
)

saveRDS(shap_vals, here::here("app/data/shap_vals.rds"))
