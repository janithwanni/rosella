library(iml)
library(counterfactuals)
library(randomForest)
library(tidyverse)
dataset_scaled <- readRDS(here::here("vis_xai_unify/dataset_scaled.rds"))
rf_model <- readRDS(here::here("vis_xai_unify/rf_model.rds"))

predictor_rf <- iml::Predictor$new(
  rf_model,
  data = dataset_scaled,
  type = "prob"
)

w_classif <- counterfactuals::NICEClassif$new(
  predictor_rf
)

library(furrr)
library(progressr)
plan(multisession)

with_progress({
  p <- progressor(steps = nrow(dataset_scaled))
  cfvals <- future_map(seq_len(nrow(dataset_scaled)), function(i) {
    library(randomForest)
    obs <- dataset_scaled[i, ]
    new_cls <- ifelse(obs$cluster == "A", "B", "A")
    w_cf <- w_classif$find_counterfactuals(
      x_interest = obs, desired_class = new_cls, desired_prob = c(0.5, 1)
    )
    p()
    w_cf$data |> mutate(index = i)
  }) |> list_rbind()
})

saveRDS(cfvals, here::here("vis_xai_unify/counter_facts.rds"))
