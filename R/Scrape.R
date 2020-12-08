# Clear the environment
rm(list=ls())

# Loads libraries
library(tidyverse)
library(rvest)
library(urltools)

get_search_result_links <- function(search_page) {
  search_page %>% 
    html_nodes(".b_caption") %>%
    html_nodes(".b_attribution") %>% 
    html_nodes("cite") %>% 
    html_text()
}

filter_search_result <- function(link) {
  # TODO: crawler would search template in a thesaurus and any similar words would register
  # in the conditional statement
  
  # this code helps figure out the difference between if AND and if OR
  # 1. link has no sample, but has a template
  # 2. link has sample but not template
  # 3. link has sample and template
  # 4. link has neither sample nor template
  
  # AND - &
  # 1: false AND true -> false
  # 2: true AND false -> false
  # 3: true AND true -> true
  # 4: false AND false -> false
  
  # OR - |
  # 1: false OR true -> true
  # 2: true OR false -> true
  # 3: true OR true -> true
  # 4: false OR false -> false
  
  # TODO: Add it to condition
  # TODO: Filter out how-to articles and improve the filter in general
  if (!str_detect(link, "sample") & !str_detect(link, "template")) {
    link <- ifelse(!str_detect(link, "http"), paste0("http://", link), link)
    # TODO: Look up R packages that clean html documents
    return(read_html(link) %>% 
             html_node("body") %>% 
             html_text()
           # TODO: Find regular expressions for html tags
           # str_remove_all(regular expression for html tags) %>% 
           # str_remove_all(regular expression for javascript...)
    )
    # TODO: Get rid of html tags, css, javascript
    # Figure out whether the link points to an actual set of terms and conditions
    # If it does save it
    # makes a list of the values and saves them as numbers
  } else {
    return(NA)
  }
}

save_search_results <- function(bing_search, search_results) {
  search_result_links <- get_search_result_links(bing_search)
  for (link in search_result_links) {
    try({
      
      result <- filter_search_result(link)
      if (!is.na(result)) {
        search_results[[length(search_results) + 1]] <- result
      }
    })
  }
  return(search_results)
}

last_result_number <- function(last_result) {
  last_result %>%
    html_nodes("#b_tween") %>%
    html_nodes(".sb_count") %>%
    html_text()
}

### Initialize variables for the loop ###
page_incrementor <- 0
search_results <- list()
base_URL <- "https://www.bing.com/search?q=terms+and+conditions"
bing_search <- read_html(base_URL)
while (page_incrementor <= 75) {
  if (page_incrementor == 0) {
    search_results <- save_search_results(bing_search, search_results)
    page_incrementor <- 5
  } else {
    URL <- paste0(base_URL, "&first=", page_incrementor)
    bing_search <- read_html(URL)
    search_results <- save_search_results(bing_search, search_results)
    # find last number
    page_max <- 
      as.numeric(str_match(last_result_number(bing_search), "\\-(\\d+) ")[2])
    page_incrementor <- page_max + 1
  }
}

#nodes detects the html tags (ex. a)
#attribute detects the html attributes (ex. href in a)
#to access a class use a . before the class name when gathering the attribute

# Read the link from each href






# TODO: Get a list of the links for the first 10 pages
# TODO: For each page i, find the link for page i, and go through scraping process

# TODO: Go to link and scrape the text from the terms and conditions
# Store it
# TODO: Go to the next page of results and do it all over


# **potential feature: search for website TOS in queue**
# TODO: Write out the steps for a program that goes through every page of search results, goes to each hyperlink in the search results, and saves the text from the page

# Example Pseudo-code for Making Pizza #
# Collect 1/h pound of dough, jar of tomato sauce, and 1/2 ounce of mozzarella cheese
# Roll the pizza dough into a 30 cm radius ball
# Flatten the ball out into a circle 1cm thick and 60cm wide
# Pour tomato sauce over the entire surface area of the dough circle
# Sprinkle the mozzarella cheese over the entire surface area of the dough circle
# Place the dough, with the tomato sauce and mozzarella cheese on top, into a 450 degree oven
# Wait 15 minutes
# Take pizza out of oven with oven mits
# Wait 5 minutes to cool
# Eat entire pizza
