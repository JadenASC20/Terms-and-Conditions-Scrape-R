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
