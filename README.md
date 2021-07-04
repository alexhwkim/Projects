# Titans Tech - WooliesX x UNSW Business Society Case Competition

NOTE
Must enter Twitter API token credentials as well as Google geocoding API credentials to run the code. The connection setup to the API is in the first few lines.

TWEET DATA SCRAPING
Tweets with a desired key term are ingested and the user profiles of such tweeters are generated. These two information tables are joined to make a final table with relevant tweets, then sorted in descending order of followers and following/followers ratio.
Next, a table of top current trending tweet terms is generated, used to check if any related search terms related to the brand are trending.

VISUALISATIONS
Frequency graph of two tweets
A frequency line plot of two different search terms are compared by a metric of days, weeks or months.

Geographical locations of tweets
Using the generated tweets/retweets of the desired keyword, a bar graph is created highlighting the number of tweeters/retweeters in each region of Australia.

Geolocation mapping of tweets
Using the latitude and longitude data inside the twitter parameters, a map of Australia is generated with data points plotted on the map, of the location of the tweets. This can be expanded to a global scale where necessary. 

Creating tweet network
A dataframe of the tweet/retweet network is created, using the screen names of the tweeters and retweeters
The out degree scores of the tweeters and retweeters in the dataframe of the network are calculated, in order to find the users who retweeted the most.
The in degree scores of the tweeters and retweeters are also calculated, in order to find the users whose posts were retweeted the most. 
The betweenness scores of the tweeters and retweeters are also calculated, in order to find who has more control over the twitter network. 

Twitter network plotting
The baseline twitter network plot is created, and we can check for any errors or mistakes before proceeding. 
The vertex size is next calculated based on the out degree scores of the users in the network, in order to get a better visualisation. In order to improve readability, the colours, arrow sizes are also changed. 

Sentiment analysis
Using a desired keyword, the sentiment of the tweets are analysed, and placed into a dataframe. Then the sentiment analysis scores are plotted onto a bar chart, in order to get an overall profile of the sentiments of the twitter network.
A bar chart with all the negative emotions summed up into “negative” and all the positive emotions summed up into “positive” is created, allowing us to graphically view the overall feeling of the twitter network. 
