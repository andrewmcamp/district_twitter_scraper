# Scrape Twitter Feeds of School Districts
This (messy) code is broken into four parts:
1. ***scrape_district_websites.R*** - Load a data file obtained through the NCES Common Core of Data that includes many variables. The NCES ID and url are important for this project. Then, I load each district's page and extract any links to a Twitter account. The assumption is that these accounts will belong to the school district.
2. ***get_twitter_ids*** - The Twitter API uses a unique ID # for each user, so this code takes their handle (embeded in the url) and gets the unique ID #.
3. ***get_tweets*** - This code actually requests each users' tweets. It's currently set up to only get those posted after 8/1/2021 and only the 100 most recent tweets.
4. ***text_analysis*** - This code actually unpacks those tweets and creates the visualizations I posted.

The data file ***nces_ccd_data.csv*** in this repository is only slightly cleaned from the CCD to remove unusual characters and a few lines of notes.
The data file ***scrapped_sites.fst*** in this repository is the result of the ***scrape_district_websites.R*** file which can take a long time to run.

I would include other intermediary data files, but don't think the API terms of use allow me to as individual accounts are identified.

The other thing necessary to get the code running is a bearer token. This can be obtained by creating an account at developer.twitter.com. Different "levels" have different limits on the pacing and amount of requests that can be made. I submitted the project for the academic API and was approved in a day or so. This code might not work if your project isn't on the "Academic" level.
