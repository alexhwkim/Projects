library(rtweet)
library(httpuv)
library(dplyr)
library(reshape) 
library(ggplot2)
library(data.table)
library(tidytext)
library(maps)
library(igraph)
library(qdapRegex)
library(qdap)
library(tm)
library(syuzhet)


# Enter Twitter API Tokens
# Appname
appname <- "Titans Tech-Klaus"

# API key
key <- "tjAnEPZAkAjh712YEU4ySdKcK"

# API Secret
secret <- "oCadnJdhwr1NVWRM1xyoajl5yf8XwZojL1TBgaNx1DNCfmEEx2"

twitter_token <- create_token(
  app = appname,
  consumer_key = key,
  consumer_secret = secret,
  access_token = "1406931689385848834-Htg0WpINI3iy3u30K6voyChipYl5cx",
  access_secret = "NG0nfeqglYQHSSwhGunCMZ5BHGPTzuDp8B9RtY17X42i9")


# ---- TWITTER DATA SCRAPING ----
# Get tweets by Australians with specified search term
# Paramter result_type can be changed to popular, recent or mixed
woolies_tweets <- search_tweets("woolies", n = 18000, include_rts = FALSE, lang = "en",
                                country = "Australia", result_type = "recent")
# Filter out accounts with 0 followers as bot removal
woolies_tweets <- woolies_tweets[woolies_tweets$followers_count>0,]
woolies_users <- users_data(woolies_tweets)
# Filter out accounts created in the last 2 weeks as bot removal
woolies_users <- woolies_users %>%
  filter(woolies_users$account_created_at <= "2021-06-13")
# Filter tweets that are from individuals from Australians cities/town 
aus_cities <- read.csv("auscities.csv")
woolies_users <- subset(woolies_users, location == "Australia" |
                          location %in% aus_cities$city |
                          location %in% aus_cities$state)


# Sort users by the Marketing golden ratio: following/follower ratio
woolies_user_df <- woolies_users %>% 
  group_by(screen_name) %>% 
  summarize(follower = mean(followers_count), 
            friend = mean(friends_count))
woolies_user_df$ratio <- woolies_user_df$follower/woolies_user_df$friend
# Add a tweet column to the user data table
influencer_tweets <- inner_join(woolies_user_df, woolies_tweets,by="screen_name")
influencer_tweets <- influencer_tweets %>% 
  select(screen_name, follower, friend, ratio, location, text)
# Sort results by descending follower count
influencer_tweets <- arrange(influencer_tweets, desc(follower))
influencer_tweets

# Find twitter trends by city, or Australia as a whole
auscity_tw_trends <-get_trends("Sydney")
# Calculate total number of tweets
auscity_tw_trends <- auscity_tw_trends %>% 
  group_by(trend) %>% 
  summarize(tweet_vol = mean(tweet_volume))
# Sort tweets in descending order
auscity_tw_trends <- arrange(auscity_tw_trends, desc(tweet_vol))
auscity_tw_trends


# ---- VISUALISATIONS ----
# Time series analysis of the frequency of two tweets
tweet_1 <- search_tweets("supermarket" , n = 18000, include_rts = FALSE)

tweet1_graph <- ts_plot(tweet_1,  by = "days" , color = "blue")
tweet_1 <- ts_data(tweet_1, by = 'days')
names(tweet_1) <- c("time" , "supermarket")

tweet_2 <- search_tweets("grocer" , n = 18000, include_rts = FALSE) 
tweet_2 <- ts_data(tweet_2, by = 'days')
names(tweet_2) <- c("time" , "grocer")

merged_df <- merge(tweet_2, tweet_1, by = "time" , all = TRUE)
melt_df <- reshape::melt(merged_df, na.rm = TRUE, id.vars = "time")

ggplot(data = melt_df, aes(x = time, y = value, col = variable)) + 
  geom_line(lwd = 0.8)


# Filter data from above for only twitter users with over 1k followers
woolies_tweets_best <- woolies_tweets[woolies_tweets$followers_count > 1000,]

# Create table of geographical locations of the tweets
# Only within Australia
woolies_tweets %>%
  count(location, sort = TRUE) %>%
  mutate(location = reorder(location, n)) %>%
  top_n(20) %>%
  ggplot(aes(x = location, y = n)) +
  geom_col() +
  coord_flip() +
  labs(x = "Count",
       y = "Location",
       title = "Where Twitter users are from - unique locations ")

# Geolocation data of tweets
pol_coord <- lat_lng(woolies_tweets)
# Omit NA values
pol_geo <- na.omit(pol_coord[, c("lat", "lng")])
# Plot a map of Australia with the tweet areas
map(database = "world", regions = "Australia", fill = T, 
    col = "light yellow", bg = 'light blue')
with(pol_coord, points(lng, lat, pch = 20, cex = 1, col = 'blue'))

# Graph based data structure visualisations
# Create data frame for the tweet network
wtwt_df <- woolies_tweetsbest[, c("screen_name", "retweet_screen_name")]
head(wtwt_df, 10)
wtwt_df_new <- wtwt_df[complete.cases(wtwt_df), ]
# Convert to matrix
wtwt_matrix <- as.matrix(wtwt_df_new)
# Create the retweet network
retweet_network <- graph_from_edgelist(el = wtwt_matrix, directed = T)
print.igraph(retweet_network)

# Calculate out degree scores to find users who retweeted most
out_degree <- degree(retweet_network, mode = c("out"))
# Sort users in desc order of out deg scores
out_deg_sorted <- sort(out_degree, decreasing = T)
# View top 10 users
out_deg_sorted[1:10]

# Calculate in degree scores, for users who posts were retweeted most
in_degree <- degree(retweet_network, mode = c("in"))
# Sort users in desc order
in_deg_sorted <- sort(in_degree, decreasing = T)
# View top 10 users
in_deg_sorted[1:10]

# Calculate betweeness
# Nodes with higher betweeness have higher control over twitter network
between_nw <- betweenness(retweet_network, directed = T)
# Sort in order of desc betweeness scores
between_nw_sort <- between_nw %>%
  sort(decreasing = T) %>%
  round()
# View top 10
between_nw_sort[1:10]

# Create BASE TWITTER NETWORK plot
set.seed(1234)
plot.igraph(retweet_network)

# Set vertex size based on out degree of the twitter network users
vertex_sz <- (out_degree * 2) + 20
# Assign vertex_sz to vertex size attribute and plot network
# Adds additional formatting
set.seed(1234)
plot(retweet_network, asp = 1,
     vertex.size = vertex_sz,
     vertex.color = "lightblue",
     edge.arrow.size = 0.25,
     edge.color = "black",
     vertex.label.cex = 0.8,
     vertex.label.color = "black", 
     vertex.frame.color = "grey")
# View vertex attributes, i.e the twitter user names
vertex_attr(retweet_network)

# Extracting actual twitter text
# Search for Australian tweets about lockdown, exclude retweets
lock.twt <- search_tweets("lockdown", n = 18000, include_rts = F, lang = 'en',  result_type = "recent")
lock.twt <- subset(lock.twt, location == "Australia" |
                        location %in% aus_cities$city |
                        location %in% aus_cities$state)

# Create data frame with just text, makes it easy to read twitter text
woolies_tweets_text <- lock.twt$text
head(woolies_tweets_text, 10)
# Remove urls from text
woolies_tweets_text_edit <- rm_twitter_url(woolies_tweets_text)
head(woolies_tweets_text_edit, 10)
# Remove special characters
woolies_tweets_read <- gsub("[^A-Za-z]", " ", woolies_tweets_text_edit)
head(woolies_tweets_read)


# Sentiment analysis(sa): Looks at sentiment of lockdown tweets
sa_value <- get_nrc_sentiment(lock.twt$text)
# View sentiment scores
sa_value[1:5, 1:7]
# Calculate sum of scores
sa_scores <- colSums(sa_value[,])
sa_scores_df <- data.frame(sa_scores)
sa_scores_final <- cbind(sentiment=row.names(sa_scores_df), 
                         sa_scores_df, row.names = NULL)
# Plot the sentiment scores
ggplot(data = sa_scores_final, aes(x = sentiment, y = sa_scores, 
                                   fill = sentiment)) + 
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Create new plot with ONLY negative and positive column
# Find data with only negative emotions
neg.df <- sa_scores_final[sa_scores_final$sentiment %in% 
                            c("anger", "disgust", 
                              "fear", "sadness", "negative"), ]
# Find data with only positive emotions
pos.df <- sa_scores_final[sa_scores_final$sentiment %in% 
                            c("anticipation", "joy", 
                              "positive", "surprise", "trust"), ]
# Sum the sa scores columns
neg.val <- sum(neg.df$sa_scores)
pos.val <- sum(pos.df$sa_scores)
# Create the new dataframe with negative and positive values
Sentiment <- c("Negative", "Positive")
sa.score <- c(neg.val, pos.val)
neg.pos.df <- data.frame(Sentiment, sa.score)
print(neg.pos.df)

# Plot the sentiment scores, only negative and positive scores
ggplot(data = neg.pos.df, aes(x = Sentiment, y = sa.score, 
                              fill = Sentiment)) + 
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
