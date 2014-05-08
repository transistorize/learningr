library('RCurl')
library('stringr')

# base data URL for Arsenal stats, pull from espnfc page
team <- "Arsenal"
baseurl <- "http://www.espnfc.com/team/fixtures/_/id/359/season" #2001/league/eng.1/arsenal
seasons <- 2001:2012

# build all the URLs and fetch each season's web page
mod_name <- str_replace_all(tolower(team), " ", "-")
urls <- sapply(seasons, function(s) { return ( paste(baseurl, s,"league/eng.1", mod_name, sep="/") ); })
raw_data <- sapply(urls, getURL, .encoding="UTF-8")

# optional: write raw HTML data to local working directory
io <- file("rawdata_arsenal.txt")
cat(raw_data, file=io)
close(io)

# cleanup
rm("raw_data", "io")
