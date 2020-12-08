rm(list = ls())

library(httr)
library(jsonlite)
library(tidyverse)
library(rvest)


#### Pull Data ---------------------------------------------------------------------------------------------------
json_data <-
  # Gets data from tosdr api
  GET("https://tosdr.org/api/1/all.json")$content %>% 
  # Translate raw byte result to stringified json
  rawToChar() %>% 
  # Converts stringified json to list object
  fromJSON()

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
