Terms:
------

Ward - division of the district, 1-8

ANC - Advisory Neighborhood Commission. Subdivision of ward identified
by letter, e.g. 5D. Around 5-10 commissioners serve on an ANC.

SMD - “Single-member district”; subdivision of ANC from which a single
ANC commissioner is elected

Format for cleaned\_data filenames:
-----------------------------------

&lt;year(s)&gt;\_&lt;content&gt;\_&lt;aggregation level&gt;.csv

e.g.

2018\_ancElection\_commissioners\_contest.csv is data from 2018
comprising both ANC Elections and subsequently incumbent commissioners,
aggregated at the contest level

Pipeline
--------

Commands to run the data processing steps are given in ./Makefile

To make a given target, run ‘make &lt;target&gt;’ (with filepaths
relative to the directory holding the Makefile)  
e.g. to create 2012\_2018\_ancElection\_contest.csv, run ‘make
cleaned\_data/2012\_2018\_ancElection\_contest.csv’

To create all processed data, run ‘make process’

### 2012-2018 Election, contest-level

    ## [1] "../cleaned_data/2012_2018_ancElection_contest.csv"
    ## # A tibble: 1,184 x 13
    ##    contest_name  year  ward anc     smd smd_ballots smd_anc_votes
    ##    <fct>        <int> <int> <fct> <int>       <int>         <int>
    ##  1 1A01          2012     1 A         1          NA           398
    ##  2 1A01          2014     1 A         1         333           239
    ##  3 1A01          2016     1 A         1         722           651
    ##  4 1A01          2018     1 A         1         465           415
    ##  5 1A02          2012     1 A         2          NA           738
    ##  6 1A02          2014     1 A         2         616           422
    ##  7 1A02          2016     1 A         2        1089           872
    ##  8 1A02          2018     1 A         2         859           763
    ##  9 1A03          2012     1 A         3          NA           442
    ## 10 1A03          2014     1 A         3         413            51
    ##    explicit_candidates winner                 winner_votes write_in_votes
    ##                  <int> <fct>                         <int>          <int>
    ##  1                   1 LISA KRALOVIC                   374             24
    ##  2                   2 MARVIN L. JOHNSON               168              5
    ##  3                   2 Valerie Baron                   400              5
    ##  4                   2 Layla Bonnot                    260             10
    ##  5                   2 VICKEY A. WRIGHT-SMITH          432             11
    ##  6                   1 JOSUE SALMERON                  399             23
    ##  7                   1 Vickey A. Wright-Smith          823             49
    ##  8                   2 Teresa A. Edmondson             387              8
    ##  9                   1 STEVE SWANK                     406             36
    ## 10                   1 WRITE-IN                         51             51
    ##    over_votes under_votes
    ##         <int>       <int>
    ##  1         NA          NA
    ##  2          0          94
    ##  3          0          71
    ##  4          1          49
    ##  5         NA          NA
    ##  6          0         194
    ##  7          1         216
    ##  8          0          96
    ##  9         NA          NA
    ## 10          0         362
    ## # … with 1,174 more rows

-   contest\_name - ANC identifier
-   smd\_anc\_votes - how many votes were cast in the election for this
    ANC commissioner
-   explicit\_candidates - how many official candidates were registered
-   ward\_ballots - ignore
-   over\_votes - number of ballots not counted due to multiple votes
    for ANC commissioner
-   under\_votes - number of ballots with no vote for ANC comm.
-   ward\_anc\_votes - ignore
-   anc
-   smd
-   ward - these are just contest\_name broken out
-   year
-   winner
-   winner\_votes
-   write\_in\_votes
-   smd\_ballots - number of ballots cast that could have included votes
    for this ANC election, even if they didnt

For details on the cleaning process (and recoding of ANC 3G), see
visualization/election\_contest.pdf (or run ‘make
visualization/election\_contest.pdf’)

### 2012-2018 Elections, candidate-level

    ## [1] "../cleaned_data/2012_2018_ancElection_candidate.csv"
    ## # A tibble: 2,797 x 9
    ##    contest_name  year  ward anc     smd candidate              votes
    ##    <fct>        <int> <int> <fct> <int> <fct>                  <int>
    ##  1 1A01          2012     1 A         1 LISA KRALOVIC            374
    ##  2 1A01          2012     1 A         1 WRITE-IN                  24
    ##  3 1A02          2012     1 A         2 ALEXANDER GALLO          295
    ##  4 1A02          2012     1 A         2 VICKEY A. WRIGHT-SMITH   432
    ##  5 1A02          2012     1 A         2 WRITE-IN                  11
    ##  6 1A03          2012     1 A         3 STEVE SWANK              406
    ##  7 1A03          2012     1 A         3 WRITE-IN                  36
    ##  8 1A04          2012     1 A         4 LAINA AQUILINE           430
    ##  9 1A04          2012     1 A         4 SENTAMU KIREMERWA        120
    ## 10 1A04          2012     1 A         4 WRITE-IN                  18
    ##    over_votes under_votes
    ##         <int>       <int>
    ##  1         NA          NA
    ##  2         NA          NA
    ##  3         NA          NA
    ##  4         NA          NA
    ##  5         NA          NA
    ##  6         NA          NA
    ##  7         NA          NA
    ##  8         NA          NA
    ##  9         NA          NA
    ## 10         NA          NA
    ## # … with 2,787 more rows

### 2012-2018 Elections, ANC-level

    ## [1] "../cleaned_data/2012_2018_ancElection_anc.csv"
    ## # A tibble: 160 x 9
    ##     ward  year anc   num_candidates votes vote_norm engagement
    ##    <int> <int> <fct>          <dbl> <dbl>     <dbl>      <dbl>
    ##  1     1  2012 A               1.58  482.     0.791     NA    
    ##  2     1  2012 B               1.25  544.     0.900     NA    
    ##  3     1  2012 C               1.5   642.     0.827     NA    
    ##  4     1  2012 D               1.4   560.     0.795     NA    
    ##  5     1  2014 A               1.33  296.     0.852      0.636
    ##  6     1  2014 B               1.5   319      0.764      0.738
    ##  7     1  2014 C               1     460      0.963      0.645
    ##  8     1  2014 D               1.2   427.     0.840      0.720
    ##  9     1  2016 A               1.25  642.     0.874      0.768
    ## 10     1  2016 B               1.08  722.     0.944      0.690
    ##    prop_uncontested prop_empty
    ##               <dbl>      <dbl>
    ##  1            0.5            0
    ##  2            0.917          0
    ##  3            0.625          0
    ##  4            0.6            0
    ##  5            0.667          0
    ##  6            0.5            0
    ##  7            1              0
    ##  8            0.8            0
    ##  9            0.75           0
    ## 10            0.917          0
    ## # … with 150 more rows

-   ward, year, anc – as above
-   num\_candidates – average number of registered candidates
-   votes - average number of votes for winning candidates in ANC
-   vote\_norm - average of ratio between winner votes and ballots cast
    (not total ANC votes)
-   engagement - average of ratio between total ANC votes and ballots
    cast

### 2012-2018 imputed turnout, ANC-level

    ## [1] "../cleaned_data/2012_2018_imputedTurnout_anc.csv"
    ## # A tibble: 160 x 6
    ##    anc.full  year voters ballots duplicitous turnout
    ##    <fct>    <int>  <int>   <int>       <int>   <dbl>
    ##  1 1A        2012  18174   10209           3   0.562
    ##  2 1A        2014  18046    6474           3   0.359
    ##  3 1A        2016  18606   11624           3   0.625
    ##  4 1A        2018  19391    8793           3   0.453
    ##  5 1B        2012  18219   10836           2   0.595
    ##  6 1B        2014  18508    6847           2   0.370
    ##  7 1B        2016  19855   13192           2   0.664
    ##  8 1B        2018  21054    9577           2   0.455
    ##  9 1C        2012  14568    9079           0   0.623
    ## 10 1C        2014  13420    5908           0   0.440
    ## # … with 150 more rows

produced by impute\_turnout.R by taking \_ballots\_precinct.csv and
apportioning precinct-level ballot and registration counts among ANCs
based on geographic overlap.

-   voters – imputed registered voters in ANC
-   ballots – imputed ballots cast in ANC
-   duplicitous – number of precincts which cross this ANCs boundary
-   turnout – ballots / voters

Turnout data without imputation is available by uncommenting the line
that saves ‘reg.fixed.drop’ in impute\_turnout.R; however this data
drops something like half of precincts.

For some evaluation of the imputed data, run ‘make
visualization/imputed\_turnout.html’

### 2012-2018 ballot totals, precinct-level

    ## [1] "../cleaned_data/2012_2018_ballots_precinct.csv"
    ## # A tibble: 816 x 6
    ##    precinct  ward anc    year registered_voters ballots
    ##       <int> <int> <fct> <int>             <int>   <int>
    ##  1        1     6 C      2012              5687    3063
    ##  2        1     6 C      2014              5562    1686
    ##  3        1     6 C      2016              6694    4137
    ##  4        1     6 C      2018              6736    2813
    ##  5        1     6 E      2012              5687    3063
    ##  6        1     6 E      2014              5562    1686
    ##  7        1     6 E      2016              6694    4137
    ##  8        1     6 E      2018              6736    2813
    ##  9        2     2 A      2012               916     827
    ## 10        2     2 A      2014              1350     320
    ## # … with 806 more rows

### 2018 Elections and Incumbent Commissioners, contest-level

    ## [1] "../cleaned_data/2018_ancElection_commissioners_contest.csv"
    ## # A tibble: 297 x 20
    ##    contest_name  year  ward anc     smd smd_ballots smd_anc_votes
    ##    <fct>        <int> <int> <fct> <int>       <int>         <int>
    ##  1 1A01          2018     1 A         1         465           415
    ##  2 1A02          2018     1 A         2         859           763
    ##  3 1A03          2018     1 A         3         567           446
    ##  4 1A04          2018     1 A         4         689           544
    ##  5 1A05          2018     1 A         5         566           496
    ##  6 1A06          2018     1 A         6         902           757
    ##  7 1A07          2018     1 A         7         833           680
    ##  8 1A08          2018     1 A         8        1044           941
    ##  9 1A09          2018     1 A         9         721           609
    ## 10 1A10          2018     1 A        10         848           747
    ##    explicit_candidates winner              winner_votes write_in_votes
    ##                  <int> <fct>                      <int>          <int>
    ##  1                   2 Layla Bonnot                 260             10
    ##  2                   2 Teresa A. Edmondson          387              8
    ##  3                   1 Zach Rybarczyk               437              9
    ##  4                   1 Matthew Goldschmidt          515             29
    ##  5                   1 Christine Miller             478             18
    ##  6                   1 Angelica Castanon            725             32
    ##  7                   1 Jen Bundy                    652             28
    ##  8                   1 Kent C. Boese                914             27
    ##  9                   1 Michael Wray                 573             36
    ## 10                   1 Rashida Brown                727             20
    ##    over_votes under_votes commissioner_name   match vacant switcharoo
    ##         <int>       <int> <fct>               <lgl> <lgl>  <lgl>     
    ##  1          1          49 Layla Bonnot        TRUE  FALSE  FALSE     
    ##  2          0          96 Teresa A. Edmondson TRUE  FALSE  FALSE     
    ##  3          0         121 Zach Rybarczyk      TRUE  FALSE  FALSE     
    ##  4          0         145 Matthew Goldschimdt TRUE  FALSE  FALSE     
    ##  5          0          70 Christine Miller    TRUE  FALSE  FALSE     
    ##  6          0         145 Angelica Castañon   TRUE  FALSE  FALSE     
    ##  7          0         153 Jen Bundy           TRUE  FALSE  FALSE     
    ##  8          1         102 Kent C. Boese       TRUE  FALSE  FALSE     
    ##  9          0         112 Michael Wray        TRUE  FALSE  FALSE     
    ## 10          0         101 Rashida Brown       TRUE  FALSE  FALSE     
    ##    substantive_write_in absent empty
    ##    <lgl>                <lgl>  <lgl>
    ##  1 FALSE                FALSE  FALSE
    ##  2 FALSE                FALSE  FALSE
    ##  3 FALSE                FALSE  FALSE
    ##  4 FALSE                FALSE  FALSE
    ##  5 FALSE                FALSE  FALSE
    ##  6 FALSE                FALSE  FALSE
    ##  7 FALSE                FALSE  FALSE
    ##  8 FALSE                FALSE  FALSE
    ##  9 FALSE                FALSE  FALSE
    ## 10 FALSE                FALSE  FALSE
    ## # … with 287 more rows

produced by merge\_incumbents.R

The first part of this dataset is just from
2012\_2018\_ancElection\_contest.csv, but years before 2018 are filtered
out.

-   commissioner\_name – name of commissioner who occupied the seat
    following the 2018 election
-   match - do the name of election winner and commissioner match?
    (subsequence-based similarity over .5)
-   vacant - seat is vacant following election
-   switcharoo - seat is recorded occupied by a person other than
    election winner
-   substantive\_write\_in - write-in winner becomes named commissioner
-   absent - named election winner with seat subsequently recorded
    vacant
-   empty - write-in winner; seat vacant
