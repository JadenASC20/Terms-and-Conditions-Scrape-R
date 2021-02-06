rm(list = ls())

library(httr)
library(jsonlite)
library(tidyverse)
library(rvest)


#### Pull Data ---------------------------------------------------------------------------------------------------
# TODO: Adding caching to the loading of data!
force_load <- FALSE

json_keys <-
  # Gets data from tosdr api
  GET("https://raw.githubusercontent.com/tosdr/tosdr.org/master/api/1/all.json")$content %>% 
  # Translate raw byte result to stringified json
  rawToChar() %>% 
  # Converts stringified json to list object
  fromJSON() %>% 
  # Get JSON keys which has the names of the urls that tosdr has analyzed
  names() %>% 
  # Format the text of the keys to match a json file name that could plausibly work for the new API
  str_remove("tosdr/review/") %>% 
  str_remove("\\..+$") %>% 
  str_remove("https://") %>% 
  str_remove("http://") %>% 
  str_c(".json") %>% 
  unique()

# Remove the first 3 json keys as they have nothing to do with potential API endpoints
json_keys <- json_keys[-c(1:3)]

# Logs any errors that occur during json pull from tosdr api
log_json_pull_error <- function(endpoint, code, message) {
  fname <- file.path("data-raw", "json-pull-errors.csv")
  # If file does not exist then create the file and write the header columns
  if (!file.exists(fname))
    writeLines("endpoint,error_code,error_message", fname)
  
  # Write the endpoint that failed, the error code, and the error message to this log file
  data.frame(endpoint = endpoint,
             error_code = code,
             error_message = message,
             stringsAsFactors = FALSE) %>% 
    write_csv(fname, append = TRUE)
  invisible()
}

json_list <-
  # Apply this function to every potential json filename on the api
  map(json_keys, function(json_endpoint) {
    # tryCatch means we are trying the following block of code
    tryCatch({
      json_data <-
        GET(paste0("https://api.tosdr.org/v1/service/", json_endpoint))$content %>% 
        # Translate raw byte result to stringified json
        rawToChar() %>% 
        # Converts stringified json to list object
        fromJSON()
      # If there is no error object in the returned json then just return the json that was pulled from the api
      if (is.null(json_data$error)) {
        json_data
      } else {
      # Otherwise, log the error that was returned from the API
        log_json_pull_error(json_endpoint, json_data$code, json_data$message)
      }
    }, error = function(e) {
      # Log error if one occurs
      log_json_pull_error(json_endpoint, "Scripting Error", e$message)
    })
  })

# Name the values of our returned json scrape based on the json endpoints hit
names(json_list) <- json_keys
# Remove empty json values that correspond to failed data pulls
json_list_clean <- json_list[lengths(json_list) != 0]


# Old Code --------------------------
url_data <-
  # map_df loops through a list and then combines the results of each loop into a data.frame
  # see ?map_df for examples and more info
  # Loop through key names of resulting json_data list object from api pull
  map_df(names(json_data), function(nm) {
    # If the key name has a certain pattern that indicates it has data that we need
    if (str_detect(nm, "review/.+")) {
      # Access that data by its key name and then pull down its documents object, which has the urls for all the terms & conditions
      json_data[[nm]]$documents %>% 
        # Ensure that documents object is a data.frame
        as.data.frame() %>% 
        # Index the resulting urls from the documents data.frame with a clean parent_site column
        mutate(parent_site = str_remove(nm, ".*review/"))
    }
  })

# Similar code for talking points from the tosdr api pull
points_data <-
  map_df(names(json_data), function(nm) {
    if (str_detect(nm, "review/.+")) {
      json_data[[nm]]$points %>% 
        as.data.frame() %>% 
        mutate_all(as.character) %>% 
        mutate(parent_site = str_remove(nm, ".*review/"))
    }
  })


#### Clean Data ---------------------------------------------------------------------------------------------------

# TODO For Jaden, create a ratings data for each site in a similar way to the above data parsing 
# Loop through the keys of the json_data object and find and organize the ratings data #
# rating_data <- 
#   map_df(names(json_data), function(nm) {
#     
#   })

# TODO For Jaden, loop through the url_data data.frame and pull down the text of each terms & conditions #
# Create a function that cleans the html text
clean_tnc_html_text <- function(text) {
  # Write in cleaning code
  # This is where the stringr package and all its str_ functions can come in handy
}
# Initiate a new empty column to store the text of the terms & conditions
url_data$text <- NA
# Loop through each row of the url_data data.frame
for (row_num in 1:nrow(url_data)) {
  # Pull down and store the scraped text
  # url_data[row_num, "text"] <-
}
