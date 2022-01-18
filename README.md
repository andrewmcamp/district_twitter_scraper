# Scrape Twitter Feeds of School Districts
This (messy) code is broken into four parts:
1. ***scrape_district_websites.R*** - Load a data file obtained through the NCES Common Core of Data that includes many variables. The NCES ID and url are important for this project. Then, I load each district's page and extract any links to a Twitter account. The assumption is that these accounts will belong to the school district.
2. ***get_twitter_ids*** - The Twitter API uses a unique ID # for each user, so this code takes their handle (embeded in the url) and gets the unique ID #.
3. ***get_tweets*** - This code actually requests each users' tweets. It's currently set up to only get those posted after 8/1/2021 and only the 100 most recent tweets.
4. ***text_analysis*** - This code actually unpacks those tweets and creates the visualizations I posted.
