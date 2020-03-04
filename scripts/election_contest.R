
#' ---
#' title: "Collapsing ANC Election Data to Contest Level"
#' output: html_document
#' ---

#+ setup, warning=FALSE, message=FALSE, echo=FALSE, results='hide'
knitr::opts_chunk$set(echo=FALSE, results='hide')

# Cleaning DC election data from 2012-2018
# collapses and reshapes data such that each SMD election is an observation


library(tidyverse)
library(magrittr)
library(skimr)

#path <- getwd()
wd <- unlist(strsplit(getwd(), "/"))
wd <- wd[length(wd)]
prefix <- ifelse(wd == "scripts", "../", "")

#+ load

years <- c("2012", "2014", "2016", "2018")

all.data <- NULL
all.regs <- NULL

for(year in years){

    data <- read.table(file=paste(prefix, "raw_data/", year, ".csv", sep=""), header=TRUE, sep=",")

    print(paste("starting year", year))
    print(colnames(data))

    ### Wrangle column name inconsistencies

    # first, reassign colnames as lowercase
    colnames(data) <- tolower(colnames(data))

    # fix names
    data <- rename(data, contest_name = matches("contest_?name"), precinct = matches("precinct"),
                        ward = matches("ward"))

    # drop
    data <- select(data, -matches("election"), -matches("contest_?(id|number)"), -matches("party"))
    head(data)


    # add year
    data$year <- rep(year, dim(data)[1])

    print("dropped irrelevant columns (rows/cols)")
    print(dim(data))


    ### Drop non-ANC obs

    reg <- "[[:digit:]][[:upper:]][[:digit:]]{2}"
    #print(str(data$contest_name))
    #print(grep(reg, data$contest_name, fixed=FALSE))

    # keep ANC obs and vote / registration totals (by precinct)
    keepers <- grep(reg, data$contest_name)
    keepers <- c(keepers, grep("total", tolower(data$contest_name)))
    data <- data[keepers,]

    print("dropped non-ANC obs (rows/cols)")
    print(dim(data))


    ##### Reshape precinct-level totals to columns

    # Filter and reshape
    totals <- data[grep("- TOTAL", data$contest_name),] %>% select(contest_name, precinct, votes)
    totals %<>% spread(contest_name, votes)
    totals %<>% rename(registered_voters = matches("REGISTER"), ballots = matches("BALLOT"))

    # take totals out of data
    data <- data[-grep("- TOTAL", data$contest_name),]

    # merge
    data <- inner_join(data, totals, by="precinct")



    ### Fix Names

    # reformat contest name to be just 6B04 e.g.
    data$contest_name <- regmatches(data$contest_name, regexpr(reg, data$contest_name))

    # break out to ANC and smd fields (and ward to check the above anomaly)
    data$anc <- regmatches(data$contest_name, regexpr("[[:alpha:]]", data$contest_name))
    data$smd <- regmatches(data$contest_name, regexpr("[[:digit:]]{2}$", data$contest_name))
    data$ward_check <- regmatches(data$contest_name, regexpr("^[[:digit:]]", data$contest_name))

    # some years have whitespace in candidate names
    data$candidate <- strwrap(data$candidate)
    # some names have commas, which will not read in properly
    data$candidate <- str_remove(data$candidate, ",")


    print(paste("year done", year, "(rows/cols)"))
    print(dim(data))

    # If this is the first iteration, initialize with header
    if(is.null(all.data)) all.data <- data[0,]

    # append to other years, tidystyle
    all.data <- bind_rows(all.data, data)

}

# rename
data <- all.data

#' # Where do we see ward discrepancies?
#'
#' - ward_check comes from the full SMD designation ("2B01" e.g.)
#' - ward is from the initial data
#+ results='show'
ward_test <- data %>% filter(ward_check != ward)
ward_test %>% group_by(ward, anc, smd) %>% summarize(ward_check = unique(ward_check)) %>% data.frame %>% print

# <embed src='../raw_data/ANC02_3G.pdf' width=400 height=400 />
#' ![](../raw_data/ANC02_3G.pdf)
#' 
#' - we see ANC 3G SMDs 1-4 are in ward 4, which agrees with maps
#' - also seeing 6D04... which is accurate but ignorable -- looks like it includes a section of hain's point that's in ward 2.

#+ results='show'
ward_test %>% group_by(contest_name) %>% summarize(votes = sum(votes)) %>% data.frame %>% print

#' this is seeing the vacuous part of 6D04, cool
#+ echo=TRUE
data %<>% filter(!(contest_name=="6D04" & ward==2))

#' ### Recode all of ANC 3G to Ward 3
#'
#' - We currently don't work with any ward-level data
#' - And this is the naming convention used by shapefules in impute_turnout.R
#+ echo=TRUE
data %<>% mutate(ward=ifelse(contest_name %in% c("3G01", "3G02", "3G03", "3G04"), 3, ward))

#+
data %<>% select(-ward_check)


### Export I (Precinct-level Registration Data)

# hang onto registration & ballot data to wrangle elsewhere!
regs <- data %>% select(precinct, ward, anc, contest_name,
                             registered_voters, ballots, year)
# collapse away from candidate lvl
regs %<>% group_by(precinct, ward, anc, year) %>%
                summarize(registered_voters = unique(registered_voters),
                          ballots = unique(ballots))

write.table(regs,
            file=paste(prefix, "cleaned_data/2012_2018_ballots_precinct.csv", sep=""),
            append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)

# Drop registration data from contest data
# the SMD-level ballot data is still there in the form of over/under votes entered as candidates
data %<>% select(-ballots, -registered_voters)


#### Collapsing / Reshaping

#+
## Collapse #1 (collapse out precincts)
# propogate up NAs in ballots using max(), we don't need that data at each ANC
data.cand <- data %>% group_by(contest_name, candidate, year) %>%
                 summarize(votes = sum(votes),
                           anc=unique(anc), ward=unique(ward),
                           smd=unique(smd))

#+

# Deal with over/under votes, which are entered as candidates in 2014-18
# Filter, reshape, & merge so we have over/under as variables
ind <- grep("^(over|under) ?votes$", tolower(data.cand$candidate))
not_ind <- setdiff(seq(nrow(data.cand)), ind)
over.under <- data.cand[ind,]
# drop
data.cand <- data.cand[not_ind,]
# generalize strings
over.under$candidate <- tolower(over.under$candidate)
# reshape
over.under %<>% spread(candidate, votes)
# rename; keep
over.under %<>% rename(over_votes = "over votes", under_votes = "under votes") %>%
             select(contest_name, over_votes, under_votes, year)
# pull back in
data.cand %<>% left_join(over.under, by=c("contest_name", "year"))




#' # Peek at Candidate-Level Data

#+ cand_lvl, echo=TRUE, results='show'

data.cand %>% ungroup %>% skim_without_charts


#+ tidy



### Tidy things up

# sort for easier sanity checking
data.cand <- data.cand[order(data.cand$year, data.cand$contest_name),]

# sort columns so they actually make sense
sorted_names <- c("contest_name", "year", "ward", "anc", "smd")
# tack on any leftovers on the end so you're not dropping
sorted_names <- c(sorted_names, setdiff(colnames(data.cand), sorted_names))
data.cand %<>% select(sorted_names)


### Export II (Candidate Level)

write.table(data.cand,
            file=paste(prefix, "cleaned_data/2012_2018_ancElection_candidate.csv",
                       sep=""),
            append=FALSE, quote=FALSE, sep=",", row.names=FALSE, col.names=TRUE)


### Collapse to Contest-Lvl

# keep: SMD ANC votes, ward ANC votes, # official candidates, winner name, winner %, write-in %
#   ward totals (2), anc/ward/smd/yr,
data.cont <- data.cand %>% group_by(contest_name, year) %>%
                        summarize(smd_anc_votes = sum(votes),
                                  explicit_candidates = n() - 1,
                                  over_votes = unique(over_votes),
                                  under_votes = unique(under_votes),
                                  anc=unique(anc), smd=unique(smd),
                                  ward=unique(ward), winner=candidate[which.max(votes)],
                                  winner_votes=max(votes),
                                  write_in_votes=votes[grep("write.*in",tolower(candidate))])

# now we can make use of over/under if they exist
data.cont %<>% mutate(smd_ballots = smd_anc_votes + over_votes + under_votes)


#' # Peek at contest-level data
#+ contest_level, echo=TRUE, results='show'

data.cont %>% ungroup %>% skim_without_charts

#+

### Export III

# sort
sorted_names <- c("contest_name", "year", "ward", "anc", "smd", "smd_ballots", "smd_anc_votes",
        "explicit_candidates", "winner", "winner_votes", "write_in_votes")
sorted_names <- c(sorted_names, setdiff(colnames(data.cont), sorted_names))
data.cont %<>% select(sorted_names)


write.table(data.cont,
            file=paste(prefix, "cleaned_data/2012_2018_ancElection_contest.csv",
                       sep=""), append=FALSE, quote=FALSE, sep=",", row.names=FALSE,
            col.names=TRUE)



