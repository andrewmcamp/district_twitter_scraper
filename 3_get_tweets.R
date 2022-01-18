# This script pulls the 100 most recent tweets from each user ID fed in
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
websites <- read_fst("data/converted_ids.fst")

websites <- websites %>%
  distinct(websites$twitterID, .keep_all = TRUE)

#websites <- websites[1:100, ] # Limiting df size for debugging

# ============================================================ Helper Functions
# Handy function for later
na.omit.list <- function(y) { return(y[!vapply(y, function(x) all(is.na(x)), logical(1))]) }

# Initial setup for Twitter API
bearer_token <- "YOUR BEARER TOKEN"
headers <- c(`Authorization` = paste('Bearer', bearer_token))

# Function to actually get the tweets; with counter
k <- 0
get_tweets <- function(userID = "1292509651280506881", 
                       n=100) {
  
  k <<- k + 1
  message(paste("Getting tweets for user",k))
  
  if (k %% 1450 == 0) {
    Sys.sleep(900)
    message("Resting for 15 minutes to avoid API limits")
  }
  
  # First step is to define the url endpoint
  url_request <- paste0("https://api.twitter.com/2/users/",userID,"/tweets")
  params = list(`tweet.fields` = "text,created_at",
                `exclude` = "retweets,replies",
                `start_time` = "2021-08-01T00:00:00+00:00",
                `max_results` = 100)
  
  tryCatch(
    {
      response <- httr::GET(url = url_request,
                            httr::add_headers(.headers = headers),
                            query = params)
    }, error = function(cond){
      Sys.sleep(30)
      response <- httr::GET(url = url_request,
                            httr::add_headers(.headers = headers),
                            query = params)
    }
  )
  
  obj <- httr::content(response, as = "text")
  
  if (obj == "{\"meta\":{\"result_count\":0}}") {
    return(NA)
  } else{
    data <- as.data.frame(fromJSON(obj, flatten = TRUE)[1])
    colnames(data) <- c("time","tweetID","text")
    data$userID <- userID
  }
  return(data)

}


# ========================================== Running those functions & Cleaning
data <- lapply(websites$twitterID, get_tweets) %>%
  na.omit.list() %>%
  bind_rows()

# Loading NCES ID Data
nces <- read_csv("data/raw/nces_ccd_data.csv") %>%
  filter(`Agency Type [District] 2019-20` == "1-Regular local school district that is NOT a component of a supervisory union" |
           `Agency Type [District] 2019-20` == "7-Independent Charter District") %>%
  distinct(`Web Site URL [District] 2019-20`, .keep_all = TRUE) %>%
  mutate(url = tolower(`Web Site URL [District] 2019-20`),
         ncesID = as.numeric(`Agency ID - NCES Assigned [District] Latest available year`)) %>%
  select(url, ncesID)

# Final cleaning and merging
data <- data %>%
  #filter(is.na(data[6]) == TRUE) %>%
  select(time,tweetID,text,userID) %>%
  mutate(time = as.Date(time)) %>%
  left_join(websites, by = c("userID" = "twitterID")) %>%
  select(time, tweetID, userID, handle, url, text) %>%
  left_join(nces)


write_fst(data, "data/unpacked_tweets.fst")
rm(list = ls())