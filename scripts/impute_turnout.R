


#' ---
#' title: "Imputing turnout at ANC-level using precinct data"
#' output: html_document
#' ---

#+ setup, warning=FALSE, message=FALSE, echo=FALSE, results='hide'

library(tidyverse)
library(sf)
library(lwgeom)
library(magrittr)

knitr::opts_chunk$set(echo=FALSE, results='hide')

#path <- getwd()
wd <- unlist(strsplit(getwd(), "/"))
wd <- wd[length(wd)]
prefix <- ifelse(wd=="scripts", "../", "")


# read in data on voter registrations and ballots cast by precinct/anc/year
regs <- read.csv(paste(prefix, "cleaned_data/2012_2018_ballots_precinct.csv", sep=""),
         header=TRUE, sep=",")

#' We'd like to get data on voter turnout to contextualize data on e.g. down-ballot roll-off for ANC elections. Roll-off can be calculated (post-2012) from ANC-level data on ballots cast and undervotes, but registrations are only available in the election data at the precinct level, so we need to think about how to aggregate from precinct to ANC.
#+


#' # Look at registration/ballot data
#' ### Registration / ballot data:
#'
#' - Data at precinct level
#' - Broken out by ANC based on precinct/ANC overlaps in election data
#+ echo=FALSE, results='show'

#print(as_tibble(regs[order(regs$precinct),]))
regs %>% as_tibble %>% print(n=5)

# Make table of # ANCs corresponding to each precinct
regs %<>% mutate(anc.full = paste(as.character(ward), as.character(anc), sep=""))
count <- regs %>% group_by(precinct) %>% summarize(ancs = length(unique(anc.full)))

# print some stuff


#' ### How many precincts cross ANC's?
#'
#' - About half of precincts fall in more than one ANC
#' - so we'll have to do some figuring to aggregate data up from precinct to ANC
#+ results='show'
count %>% group_by(ancs) %>% summarize(precincts = length(unique(precinct))) %>%
    data.frame %>% print


#' ### How many ANCs share precincts with neighbors?
#'
#' - notate precincts which cross ANCs as 'duplicitous'
#+

# Merge data on 'duplicitous' precincts w/ registration data
#   and collapse from contest-level to ANC x precinct x year
collapsed <- count %>%
        mutate(duplicitous = (ancs > 1)) %>%
	inner_join(regs, by=c("precinct")) %>%
	rename(voters = registered_voters) %>%
	select(anc.full, precinct, year, duplicitous, voters, ballots)

#+ results='show'
collapsed %>% print(n=5)

#' 
#' - count duplicitous precincts by ANC
#+ results='show'
count.anc <- collapsed %>% group_by(anc.full) %>%
            mutate(count.tot = length(unique(precinct))) %>%
            filter(duplicitous) %>%
            group_by(anc.full) %>%
            summarize(count.dup = length(unique(precinct)),
	            count.tot = unique(count.tot))
            
count.anc %>% print(n=5)


#' # Quick validity check 
#' ### Using a map of ward 1 ANCs/precincts
#' ![](../raw_data/Ward1.pdf)
# <embed src=../raw_data/Ward1.pdf width=400 height=400 />
#' from ward 1 map, we know:
#' 
#' - pct 39 -> ANC 1A, 1D, 1C (trivially)
#' - 36 -> 1A 1B
#' - 37 -> 1B + 1 block of 1A
#'   
#+ results='show'
ward1 <- regs %>% filter(ward == 1 & year == 2012) %>%
            group_by(precinct) %>%
	    summarize(ancs = reduce(unique(anc.full), paste))
ward1 %>% filter(nchar(ancs) > 2) %>% data.frame %>% print

#' so at this point we could just toss precincts crossing ANCs (and lose around 40% of the data)  
#' or we could do a naive average  
#' or we could give them weighted averages based on GIS data....  
#'   

#' # GIS Data
#' ### Read in shapefiles
#+ echo=TRUE
precinct.shapes <- st_read(paste(prefix, "raw_data/precinct_shapes_2012/Voting_Precinct__2012.shp", sep=""))
anc.shapes <- st_read(paste(prefix, "raw_data/anc_2013/Advisory_Neighborhood_Commissions_from_2013.shp", sep=""))


#' ### Compute intersections between ANC & precinct shapes
#+ echo=TRUE
overlap <- st_intersection(anc.shapes, precinct.shapes) %>%
        mutate(over.area = st_area(.) %>% as.numeric()) %>%
	rename(.anc = NAME, .precinct = NAME.1) %>%
	select(.anc, .precinct, over.area)

#+
# parse ANC & precinct identifiers better
overlap %<>%
        mutate(anc.full =
	    regmatches(.anc, regexpr("[[:digit:]][[:alpha:]]$", .anc))) %>%
	mutate(precinct =
	    regmatches(.precinct, regexpr("[[:digit:]]+", .precinct)))
overlap %<>% select(anc.full, precinct, over.area)
#+ results='show'
overlap %>% print(n=5)

#'   
#' ### How many entries do we get in the overlap dataset?
#+ results='show'
print(nrow(overlap))
#' ### How many did we start with in the election data grouped by anc x pct?
#+ results='show'
print(nrow(collapsed) / 4)





#' These aren't wildly off, so it's clearly only including shapes with intersections -- it just might be counting some trivial ones  
#'   
#' ### How many of the intersections in 'overlap' are nontrivial?  
#+ results='show'
print(nrow(overlap[overlap$over.area > 10,]))

#' what are the units? it's like 7-digit numbers... sq meters, feet, lat/lon minutes???
#+ results='show'
summary(overlap$over.area)
#hist(overlap$over.area, breaks=200)


# Well... we could start by restricting it to ones noted in 'collapsed'

# how do we test??
# plot shapes
#   plot questionable (small) overlaps
# cross-ref 'overlap' with 'collapsed'

# note there are different types of geometries in the 'overlap' set
# in the originals it's just polygons
# in 'overlap' -- polygon, multipolygon, geometrycollection (point; linestr...)


# 0. get relative areas of precincts in diff ANCs

#' # Compute relative areas of intersections w/r/t precincts  
#' ### Get precinct total areas
#+ echo=TRUE
precinct.areas <- precinct.shapes %>%
            mutate(area = st_area(.) %>% as.numeric(),
                precinct = regmatches(NAME, regexpr("[[:digit:]]+", NAME)))
precinct.areas <- tibble(precinct=precinct.areas$precinct,
                            prec.area=precinct.areas$area)

#' ### Merge with overlap areas
#+ echo=TRUE
overlap %<>% inner_join(precinct.areas, by=c("precinct"))

#' ### Compute relative area of ANC x pct as [area of overlap] / [precinct area]
#+ echo=TRUE
overlap %<>% mutate(rel.area = over.area / prec.area)

#+ results='show'
#head(overlap)
hist(overlap$rel.area, breaks=20)


#' # Check against ward 1 map again
#' Expect:
#' 
#' - 36 -> 1A 1B
#' - 39 -> 1A 1D (1C)
#' - 37 -> 1A 1B
#+ results='show'
ward1 <- overlap[regexpr("1", overlap$anc.full) > 0,] %>%
               filter(rel.area > .01) %>%
               group_by(precinct) %>%
	       summarize(ancs = reduce(unique(anc.full), paste),
	           min.area = min(over.area)) %>%
	       filter(regexpr(" ", ancs)>0)
ward1 <- tibble(precinct=ward1$precinct, ancs=ward1$ancs, min.area=ward1$min.area)
ward1 %>% data.frame %>% print

#' Matches election data at 1% relative area cutoff (to toss noise)  
#+

#' ### Cross-reference with registration data
#+ echo=TRUE, results='show'
overlap %<>% mutate(precinct = as.integer(precinct))
crossref <- full_join(overlap, collapsed, by=c("anc.full", "precinct"))

crossref %<>% data.frame %>% select(-geometry)
crossref %>% as_tibble %>% print(n=5)

#' ### Any precinct-ANC combos from voting data missing from GIS data?
#+ results='show'
hanging.vote <- crossref %>% filter(is.na(rel.area), year==2012)
print(nrow(hanging.vote))
print(hanging.vote)

#' ### Are any precinct-ANC combos from GIS data missing from voting data?
#'
#' - filtering at 5% relative area
#+ results='show'
hanging.gis <- crossref %>% filter(is.na(duplicitous), rel.area > .05)
hanging.gis %>% as_tibble %>% print(n=5)

#' - We're matching up well!

#+

#' # Compute turnout
#' ## Weighting ambiguous precincts by goegraphic overlap
#+ echo=TRUE, results='show'

#' ### Drop GIS data which didn't match any election data
#+ echo=TRUE
crossref %<>% filter(!is.na(duplicitous))

#' ### Fix hanging vote data
#' 
#' - First drop duplicitous precincts w/ missing GIS
#' - Then set rel.area to 1 if missing (having retained only non-duplicitous precincts)
#+ echo=TRUE
crossref %<>% filter(!(is.na(rel.area) & duplicitous))
crossref %<>% mutate(rel.area = ifelse(is.na(rel.area), 1, rel.area))

#' - Recompute 'duplicitous' after dropping
#+ echo=TRUE
crossref %<>% group_by(precinct, year) %>%
                mutate(duplicitous = length(unique(anc.full))>1)
#' - Make sure newly nonduplicitous obs have area 1
#'   - by renormalizing relative area w/r/t precinct
#+ echo=TRUE
crossref %<>% group_by(precinct, year) %>%
                mutate(norm.area = over.area / sum(over.area))

#' - How much did this change relative areas?
#+ results='show'
summary(crossref$norm.area - crossref$rel.area)


#' ### Aggregate with weighting
#+ echo=TRUE
crossref %<>% mutate(voters = voters * norm.area, ballots = ballots * norm.area)

reg.fixed <- crossref %>% group_by(anc.full, year) %>%
               summarize(voters = round(sum(voters)),
	           ballots = round(sum(ballots)),
		   duplicitous = sum(duplicitous))

reg.fixed %<>% mutate(turnout = ballots / voters)

#+
write.table(reg.fixed, file=paste(prefix, "cleaned_data/2012_2018_imputedTurnout_anc.csv", sep=""), sep=",", append=FALSE, quote=FALSE, row.names=FALSE, col.names=TRUE)




#+
#' ## Recompute turnout by dropping ANC-crossing precincts
#+ echo=TRUE
reg.fixed.drop <- collapsed %>% filter(!duplicitous) %>%
                    group_by(anc.full, year) %>%
		    summarize(voters = round(sum(voters)),
		           ballots = round(sum(ballots)))

reg.fixed.drop %<>% mutate(turnout = ballots / voters)

#write.table(reg.fixed.drop, file=paste(prefix, "cleaned_data/2012_2018_imputedTurnoutDrop_anc.csv", sep=""), sep=",", append=FALSE, quote=FALSE, row.names=FALSE, col.names=TRUE)












#+


# Try to exit before test code if we're running a straight Rscript...
if(sys.nframe() == 0L){
    quit(save='no')
}


#' # Testing Imputed Turnout

#' Now that we have turnout estimates, draw in the election data for some testing

#+
#' ## Merge together dropped and geo-weighted turnout estimates with election data
#'
#' - losing some ANCs which had no fully contained precincts:
#+ merge, results='show'

reg.fixed.drop %<>% select(anc.full, year, turnout) %>%
                    rename(turnout.drop = turnout)


reg.fixed %<>% full_join(reg.fixed.drop, by=c("anc.full", "year"))


reg.fixed %>% filter(is.na(turnout) | is.na(turnout.drop)) %>% print(n=5)



#+
election.data <- read.csv(file="../cleaned_data/2012_2018_ancElection_contest.csv", sep=",", header=TRUE)

election.data %<>% mutate(anc.full = paste(ward,anc,sep="")) %>%
                  group_by(anc.full, year) %>%
                  summarize(actual.ballots = sum(smd_ballots)) %>%
		  select(anc.full, year, actual.ballots)

ballot.check <- reg.fixed %>%
                  inner_join(election.data, by=c("anc.full", "year")) %>%
                  mutate(error = ballots - actual.ballots,
		      rel.error = error / actual.ballots)


#' # Compare estimated ballots with post-2012 actual ballots

#+ check, results='show'
ballot.check %>% filter(year != 2012) %>%
              ggplot(aes(rel.error)) %>%
              + geom_histogram(binwidth=.05) %>%
              + labs(title="Distribution of Relative Error in Estimating Ballots") %>%
              print

#+ plots, results='show'
ballot.check %>% filter(year != 2012) %>%
            ggplot() %>%
            + geom_point(aes(actual.ballots, ballots,
	                colour=factor(duplicitous))) %>%
	    + labs(title="How well does our estimate correspond to recorded ballots?") %>%
            print

#' ### Which ANCs have particularly off estimates?
#+ results='show'
ballot.check %>% filter(abs(rel.error) > .25) %>%
    select(anc.full, year, duplicitous, ballots, actual.ballots, rel.error) %>%
    print(n=15)

#' ### How does est. precinct size (as registered voters) relate to est. turnout?
#+ results='show'
ballot.check %<>% mutate(outlier = abs(rel.error)>.25)

ballot.check %>% ggplot() %>%
                + geom_point(aes(voters, turnout, colour=factor(outlier))) %>%
                print

#' ### How closely do our two measure of turnout track?
#+ results='show'
ballot.check %>% ggplot() %>%
                + geom_point(aes(turnout, turnout.drop, colour=factor(outlier))) %>%
                print

#' ### Which ANCs have the greatest discrepancy between turnout and turnout.drop?
#+ results='show'
ballot.check %<>% mutate(turnout.diff = turnout - turnout.drop)
ballot.check <- ballot.check[order(ballot.check$turnout.diff),] 
ballot.check %>% select(anc.full, year, voters, duplicitous, turnout.diff) %>%
    print(n=10)


