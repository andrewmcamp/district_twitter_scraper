# This converts cleaned URLs (so just the twitter handle)
#
#   TODO:
#     - Maybe also get the 100 most recent tweets at the same time?
#     - Refine timing to be as quick as possible w/o exceeding API limit

# ==================================================================== Preamble
# Loading Packages
library(tidyverse)
library(rvest)
library(httr)
library(jsonlite)
library(fst)
library(RCurl)

# Set working directory & loading data file
setwd("C:/Users/andre/Box Sync/Projects/District Social Media Scraper")
websites <- read_fst("data/scrapped_sites.fst")

# ======================================================== Doing the damn thing
# Initial setup for Twitter API
bearer_token <- "YOUR BEARER TOKN HERE"
headers <- c(`Authorization` = paste('Bearer', bearer_token))

# Counter
j <- 1

# Defining function
handle_to_id <- function(handle="andrewcamp_") {
  
  params <- list(`usernames` = handle)
  
  url_request <- "https://api.twitter.com/2/users/by"
  
  if (j %% 300 == 0) {
    Sys.sleep(500)
  } else {
    Sys.sleep(2)
  }
  
  j <<- j + 1
  
  tryCatch(
    {
      response <- httr::GET(url = url_request,
                            httr::add_headers(.headers = headers),
                            query = params)
    }, error = function(cond){
      message(paste("Failed to convert handle for",handle))
      return(NA)
    }
  )
  
  obj <- httr::content(response, as = "text")
  json_data <- fromJSON(obj, flatten = TRUE)[1] %>% as.vector() %>% unlist()
  
  
  if (length(json_data) == 3) {
    message(paste("Converting handle",handle,"ID #",j))
    return(json_data[1])
  } else {
    message(paste("Failed to convert handle",handle,"to id #",json_data[1]))
    return(NA)
  }
}

websites$twitterID <- lapply(websites$handle, handle_to_id) %>% unlist()
websites <- websites %>%
  filter(is.na(twitterID) == FALSE)

write_fst(websites, "data/converted_ids.fst")