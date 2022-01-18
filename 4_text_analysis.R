# This script performs some rudimentary analyses on the scraped tweets
#
#   TODO:


# ==================================================================== Preamble
# Loading Packages
library(tidyverse)
library(tidytext)
library(fst)

# Set working directory & loading data file
setwd("C:/Users/andre/Box Sync/Projects/District Social Media Scraper")
data <- read_fst("data/unpacked_tweets.fst")

# There are some common words not in the stop words file I wanted to remove.
# These words were ones I didn't think were very informative and wouldn't be
# "biases" to appear in one semester more than the other. Still an assumption.
jargon <- c("january", "2022", "amp", "day", "jan", "monday", "friday",
            "school", "schools", "students", "pm", "2021", "December",
            "girls", "boys", "basketball", "varsity", "de", "team",
            "game", "king", "tuesday")

total_districts <- nrow(data %>% distinct(userID))

districts_2021 <- nrow(data %>% 
                         filter(time < as.Date("2022-01-01")) %>%
                         distinct(userID))

districts_2022 <- nrow(data %>%
                         filter(time >= as.Date("2022-01-01")) %>%
                         distinct(userID))

# ============================================== Converting into tidytex format
# First removing emojis, hashtags, and punctuation etc.
data$text <- gsub("[^A-Za-z0-9 ]", "", data$text)

# histogram of tweets over time
data %>%
  mutate(year = (time >= as.Date("2022-01-01"))) %>%
  ggplot(aes(x=time, fill = year)) +
  geom_histogram(bins = 24, show.legend = FALSE) +
  theme_minimal() +
  xlab("Time") +
  ylab("# of Tweets") +
  ggtitle("Frequency of Tweets Over Time") +
  labs(caption = paste("Tweets scraped from",total_districts,
                       "public school district twitter accounts.",
                       "Data from 8/1/2021 - 1/17/2022."))
ggsave("output/tweets_by_time.png", dpi = 600)

# Top words by semester
# 2022 So Far
data %>%
  filter(time >= as.Date("2022-01-01")) %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% jargon) %>%
  anti_join(stop_words) %>%
  select(tweetID, word) %>%
  count(word, sort = TRUE) %>%
  head(n = 10) %>%
  mutate(word = tools::toTitleCase(word)) %>%
  ggplot(aes(x = n, 
             y = factor(word, level = rev(word)))) +  
  geom_col(show.legend = FALSE,
           color = "#00BFC4",
           fill = "#00BFC4") +
  theme_minimal() +
  labs(y=NULL, x="# of Mentions",
       title = "Top Words in School Districts' Tweets - 2022 (so far)",
       caption = paste("Tweets scraped from",districts_2022,
                       "public school district twitter accounts.",
                       "Data from 1/1/2022 - 1/17/2022."))
ggsave("output/words_2022.png", dpi = 600)

# Fall 2021
data %>%
  filter(time < as.Date("2022-01-01")) %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% jargon) %>%
  anti_join(stop_words) %>%
  select(tweetID, word) %>%
  count(word, sort = TRUE) %>%
  head(n = 10) %>%
  mutate(word = tools::toTitleCase(word)) %>%
  ggplot(aes(x = n, 
             y = factor(word, level = rev(word)))) + 
  geom_col(show.legend = FALSE, 
           color = "#F8776D", 
           fill = "#F8776D") +
  theme_minimal() +
  labs(y=NULL, x="# of Mentions",
       title = "Top Words in School Districts' Tweets - Fall 2021",
       caption = paste("Tweets scraped from",districts_2021,
                       "public school district twitter accounts.",
                       "Data from 8/1/2021 - 12/31/2021."))
ggsave("output/words_2021.png", dpi = 600)

