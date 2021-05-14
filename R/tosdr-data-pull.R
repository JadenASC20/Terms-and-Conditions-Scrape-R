rm(list = ls())

library(httr)
library(jsonlite)
library(tidyverse)
library(rvest)

# cache_json saves the JSON associated with URL to output_filename
# URL: string
# output_filename: string
cache_json <- function(URL, output_filename) {
  GET(URL)$content %>%
    # Translate raw byte result to stringified json
    rawToChar() %>%
    # Converts stringified json to list object
    fromJSON() %>% 
    write_json(file.path("data-raw", output_filename))
}

# load_json checks if a JSON file named output_filename exists
# if it does not, then it calls cache_json
# then it reads in the resulting JSON
# URL: string
# output_filename: string
load_json <- function(URL, output_filename) {
  
  if(!file.exists(file.path("data-raw", output_filename))) {
    cache_json(URL, output_filename)
  }
  
  read_json(file.path("data-raw", output_filename))
}

write_out_json_load_error <- function(service_url, error) {
  message(service_url, error)
  error_df <-
    data.frame("url" = service_url,
               "error" = error)
  filename <- file.path("data-raw", "json-errors.csv")
  should_append <- file.exists(filename)
  write.csv(error_df, file = filename, append = should_append)
}

#this function loads a json file like the points or services file
get_all_services_JSON <- function() {
  
  all_services_json <- load_json("https://api.tosdr.org/all-services/v1/", "all_services.json")
  all_services_json_clean <- all_services_json[[3]][[2]]
  
  json_list <- list() # to store results of load_json
  for (i in 1:length(all_services_json_clean)) {
    service_slug <- all_services_json_clean[[i]]$slug
    service_name_json <- paste("https://api.tosdr.org/rest-service/v1/", service_slug, ".json", sep = "")
    json_list[[service_slug]] <- 
      tryCatch({
        load_json(service_name_json, paste(service_slug, ".json", sep = ""))   
      },
      catch = function(error) {
        write_out_json_load_error(service_name_json, error)
        NA
      })
  }
  
  return(json_list)
}

all_json_data <- get_all_services_JSON()

# Data Retrieval -------------------------------------------------------------------
# updated_at, is_comprehensively_reviewed, rating, documents.text, documents.url, 
# documents.updated_at, documents.service_id, documents.reviewed
# service_id: all_json_data$paypal$parameters$document[[1]]$service_id
# entire json in points
na_if_null <- function(val) {
  if (is.null(val))
    NA
  else
    val
}

list_of_overall_dfs <- list()
list_of_point_dfs <- list()
# Given a json object pulled down from tosdr
# Create a data.frame from it
retrieve_overall_data_from_json <- function(json) {
  json_data <- json$parameters
  metadata <- json_data$`_source`
  slug <- metadata$slug[[1]]
  data.frame(
    slug = slug,
    rating = metadata$rating[[1]],
    created_at = metadata$created_at[[1]],
    updated_at = metadata$updated_at[[1]],
    is_comprehensively_reviewed = metadata$is_comprehensively_reviewed[[1]]
  )
}
retrieve_points_data_from_json <- function(json, slug) {
  json_data <- json$parameters
  points <- json_data$points
  map_df(points, function(point) {
    case <- point$case
    data.frame(
      slug = slug,
      point_id = point$id,
      needs_moderation = point$needsModeration,
      quote_text = point$quote %>% na_if_null(),
      case_id = case$id,
      title = case$title,
      classification = case$classification,
      score = case$score,
      created_at = case$created_at,
      updated_at = case$updated_at
    )
  })
}

for (json in all_json_data) {
  slug <- json$parameters$`_source`$slug[[1]]
  list_of_overall_dfs[[slug]] <- retrieve_overall_data_from_json(json)
  list_of_point_dfs[[slug]] <- retrieve_points_data_from_json(json, slug)
}
overall_df <- 
  map_df(list_of_overall_dfs, function(df) {
    df
  })
points_df <-
  map_df(list_of_point_dfs, function(df) {
    df
  })

# Data Cleaning -------------------------------------------------------------------
strip_html_tags <- function(html_string) {
  return(gsub("<.*?>", "", html_string))
}
remove_html_tags <- function(df) {
  df %>% 
    mutate(quote_text = strip_html_tags(quote_text))
}
keep_points_that_dont_need_moderation <- function(df) {
  df %>% 
    filter(!needs_moderation)
}
remove_non_alphanumeric_chars <- function(df) {
  df %>% 
    mutate(quote_text = str_remove_all(quote_text, "[^[:alnum:] ]"))
}
remove_empty_quote_text_points <- function(df) {
  df %>% 
    filter(!is.na(quote_text)) %>% 
    filter(str_trim(quote_text) != "")
}
lowercase_text <- function(df) {
  df %>%
    mutate(quote_text = tolower(quote_text))
}

clean_data <- function(df) {
  df %>% 
    remove_html_tags() %>% 
    keep_points_that_dont_need_moderation() %>% 
    remove_non_alphanumeric_chars() %>%
    remove_empty_quote_text_points() %>%
    lowercase_text
}

clean_points_df <- clean_data(points_df)


# Vectorize quote text
# See: https://cran.r-project.org/web/packages/superml/vignettes/Guide-to-CountVectorizer.html
library(superml)
library(glmnet)

cfv <- CountVectorizer$new(max_features=10000, remove_stopwords=FALSE)
cf_mat <- cfv$fit_transform(clean_points_df$quote_text)

# Classify good vs. bad
# See: https://cran.r-project.org/web/packages/text2vec/vignettes/text-vectorization.html

idx = (clean_points_df$classification == "good") | (clean_points_df$classification == "bad")
X = cf_mat[idx, ]
y = clean_points_df$classification[idx]

glmnet_classifier = cv.glmnet(
  x = X,
  y = y,
  family = 'binomial',
  alpha = 1,  # L1 penalty
  type.measure = "auc",
  nfolds = 4,
  thresh = 1e-3,  # high value is less accurate, but has faster training
  maxit = 1e3,
)

# In-sample
train_predictions = predict(glmnet_classifier, X, type = 'response')[, 1]
hist(train_predictions[y == "bad"])
hist(train_predictions[y == "good"])
