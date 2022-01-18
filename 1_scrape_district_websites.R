# This script scrapes district websits for links to (presumably their) Twitter
# page. It takes a while, but seems to work without hickups.
#
#   TODO:
#     - Scrape for other social media (like FB).
#     - Try to capture announcements/news.

# ==================================================================== Preamble
# Loading Packages
library(tidyverse)
library(rvest)
library(httr)
library(jsonlite)
library(fst)
library(parallel)
library(RCurl)

# Set working directory
setwd("C:/Users/andre/Box Sync/Projects/District Social Media Scraper")

# ============================================================== Load NCES Data
# Reading from file downloaded from CCD
nces <- read_csv("data/raw/nces_ccd_data.csv") %>%
  filter(`Agency Type [District] 2019-20` == "1-Regular local school district that is NOT a component of a supervisory union" |
           `Agency Type [District] 2019-20` == "7-Independent Charter District") %>%
  distinct(`Web Site URL [District] 2019-20`, .keep_all = TRUE) %>%
  mutate(url = tolower(`Web Site URL [District] 2019-20`),
         ncesID = as.numeric(`Agency ID - NCES Assigned [District] Latest available year`))

# Getting just URLs; fixing oddballs that are actually email addresses
websites <- nces %>%
  filter(is.na(url) == FALSE,
         is.na(ncesID) == FALSE,
         grepl("@", url) == FALSE) %>%
  select(url)

#websites <- websites[1:1000 ,] # Limit size for debugging (if needed)

# =============================== Scraping Twitter URLs from District Web Pages
# This function cleans twitter urls to return just usernames
clean_twitter_url <- function(url=NA) {

  # First step is to cut off anything before where the username should be
  length = as.integer(nchar(url))
  start_pos = as.integer(str_locate(url, "twitter.com/")[2] + 1)
  name <- substr(url, start = start_pos, stop = length)

  # Next, anything after a forward slash (which might link to a tweet)
  slash_pos = as.integer(str_locate(name, "/")[1])
  if (is.na(slash_pos) == FALSE) {
    name <- substr(name, 1, (slash_pos)-1)
  }

  # Finally, cut anything after a question mark (which might be a parameter)
  qmark_pos = as.integer(str_locate(name, "\\?")[1])
  if (is.na(qmark_pos) == FALSE) {
    name <- substr(name, 1, (qmark_pos)-1)
  }

  # convert to nice lowercase so things are easy (breezy beautiful)
  name <- name %>%
    tolower()

  # passing the cleaned name back to source
  return(name)

}

# This function opens districts' websites and extracts links to twitter pages
get_twitter <- function(url="https://google.com") {

  tryCatch(
    {
        page <- as.vector(read_html(url, verbose = TRUE)) # Reading "url"

        links <- page %>%
          html_nodes("a") %>%
          html_attr("href") # Extracting any links in page

        links <- links[grepl("twitter.com", links)] # Extracting any link w/ "twitter"
        links <- links[order(nchar(links), links)] # Sorting by length and crossing fingers
        rtn <- links[1] # Extracting shortest link (hopefully school's twitter page)

        return(rtn) # Returning user handle

    },
    error = function(cond){
      return(NA)
    })

}

# Setting up parallel processing
cl <- makeCluster(detectCores(), type='PSOCK')

loadpkg <- function() {
  library(tidyverse)
  library(rvest)
  library(RCurl)
}

clusterCall(cl,loadpkg)


# Running the district site scrape function
system.time(
  websites$handle <- clusterApply(cl, websites$url, get_twitter) %>% unlist()
)


# Closing out cluster
stopCluster(cl = cl)
closeAllConnections()

websites <- websites %>%
  filter(is.na(handle) == FALSE )

websites$handle <- lapply(websites$handle, clean_twitter_url) %>% unlist()

# Writing scraped files to data file
write_fst(websites, "data/scrapped_sites.fst")