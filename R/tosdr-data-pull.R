rm(list = ls())

library(httr)
library(jsonlite)
library(tidyverse)
library(rvest)

cache_json <- function(URL, output_filename) {
  GET(URL)$content %>%
    # Translate raw byte result to stringified json
    rawToChar() %>%
    # Converts stringified json to list object
    fromJSON() %>% 
    write_json(file.path("data-raw", output_filename))
}

load_json <- function(URL, output_filename) {
  
  if(!file.exists(file.path("data-raw", output_filename))) {
    cache_json(URL, output_filename)
  }
  
  read_json(file.path("data-raw", output_filename))
}
#this function loads a json file like the points or services file


services_json <- load_json('https://edit.tosdr.org/api/v1/services', "services.json")
points_json <- load_json('https://edit.tosdr.org/api/v1/points', "points.json")

# Create dataframes from original json data
sample_points_df <- 
  map_df(points_json[[1]][1:100], data.frame)
sample_services_df <- map_df(services_json[[1]][1:100], data.frame)

# Clean points data
lower_case_text <- function(df) {
  df %>% 
    mutate(quoteText_clean = str_to_lower(quoteText))
}
clean_html_markup <- function(df) {
  df %>% 
    mutate(quoteText_clean = gsub("<.*?>", "", quoteText_clean))
}
clean_quote_text <- function(df) {
  df %>% 
    lower_case_text() %>% 
    clean_html_markup()
}
# TODO: Remove stop words
# TODO: Make a filter for "bad" quoteText
# TODO: Limit number of labels in the title column to a few of the more frequent ones
sample_points_df_clean <- clean_quote_text(sample_points_df)