library('XML')
library('stringr')
library('plyr')

# base data URL for Arsenal stats, pull from espnfc page
team <- "Arsenal"
seasons <- 2001:2012
# read the raw data into memory
io <- file("rawdata_arsenal.txt")
rawString <- readLines(io)

# helper method to force the empty string to NA
forceEmptyToNA <- function(node) {
  val = xmlValue(node)
  if(is.na(val) || val == "") {
    NA
  } else {
    val
  }
}

# attempt to parse the data. Be careful of HTML format.
tables <- readHTMLTable(rawString, elFun=forceEmptyToNA, header=TRUE, stringsAsFactors=FALSE, as.data.frame=TRUE, trim=TRUE)

# sanity check
stopifnot(length(tables) == length(seasons))

#cleanup
close(io)
rm("rawString", "io")

# assign season to each data frame in the list
names(tables) <- seasons

# score is a vector of our goals, opponents goals
scoreWins <- function(score) {
  goals <- score[1]
  oppGoals <- score[2]
  
  if (is.na(goals) || is.na(oppGoals)) {
    result <- NA  #ignore postponed games
  } else if (goals == oppGoals) {
    result <- "D"
  } else if (goals > oppGoals) {
    result <- "W"
  } else {
    result <- "L"
  }
  return(result)  
}

# clean up the data to include score columns as numbers, wins/losses and opponents from Arsenal's point of view, etc
cleanup <- function(teamName, season, df) {
  # make row 1 the true name of the cols
  names(df) <- df[1,]
  ndf <- (df[-1,])
  
  # extract the Score column, and convert it to two columns of numbers
  scores <- do.call(rbind, str_split(str_extract(ndf$Score, "\\d+-\\d+"), "-"))
  class(scores) <- "numeric"
  
  # assign scores to temp names for legibility
  ndf$HomeGoals <- scores[,1]
  ndf$AwayGoals <- scores[,2] 
  
  # propagate the season as its own column
  ndf$Season <- rep(season, nrow(ndf))
  
  # was the team visiting or not
  ndf$Visiting <- ndf$Away == teamName
  
  # categorize the opponent and goals based on the Home column
  ndf$Opponent <- ifelse(ndf$Home == teamName, ndf$Away, ndf$Home)
  ndf$Goals <- ifelse(ndf$Home == teamName, ndf$HomeGoals, ndf$AwayGoals)
  ndf$OppGoals <- ifelse(ndf$Home == teamName, ndf$AwayGoals, ndf$HomeGoals)
  
  # score the match using the scoreWins method as a factor
  ndf$WinLoss <- as.factor(apply(ndf[,c("Goals", "OppGoals")], 1, scoreWins))
  
  # parse the attendance number
  ndf$Attendance <- str_replace(ndf$Attendance, ",", "")
  class(ndf$Attendance) <- "numeric"  #may emit warnings
  
  # remove redundant data now using negative indexes
  drops <- c("HomeGoals", "AwayGoals", "Home", "Away", "Score")
  return(ndf[,!(names(ndf) %in% drops)])
}

# use custom for loop to have the season index
# iterate through each season's table and clean it up
for (season in seasons) {
  index <- as.character(season) 
  df <- tables[[index]] 
  tables[[index]] <- cleanup(team, season, df)
}

# merge all the data frames in the list to one massive data frame
mergeAll <- function (x,y) { return(merge(x,y, all=TRUE, sort=FALSE)); }
arsenal <- Reduce(mergeAll, tables)

#save all our work for easy future access
save(arsenal, file="arsenal.rda") 
