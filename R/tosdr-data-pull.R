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
# updated_at, is_comprehensively_reviewed, rating, documents.text, documents.url, 
# documents.updated_at, documents.service_id, documents.reviewed
# service_id: all_json_data$paypal$parameters$document[[1]]$service_id
# entire json in points


services_json <- load_json('https://edit.tosdr.org/api/v1/services', "services.json")
points_json <- load_json('https://edit.tosdr.org/api/v1/points', "points.json")

