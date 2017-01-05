#' Get Odds
#'
#' @param sportname The sport name for which to retrieve the fixutres
#' @param leagueIds integer vector of leagueids.
#' @param since numeric This is used to receive incremental updates.
#' Use the value of last from previous fixtures response.
#' @param isLive boolean if TRUE retrieves ONLY live events
#' @param oddsformat default AMERICAN, see API manual for more options
#' @param tableformat 
#' \itemize{
#' \item 'clean' default should return each contestant records, other formats kept to keep style in line with GetOdds
#' \item 'long' for a single record for each spread/total on an event, 
#' \item 'wide' for all lines as one record, 
#' \item 'subtables' all lines for spreads/totals stored as nested tables
#' } 
#' @param force boolean if FALSE, functions using cached data will use the values since the last force
#' @return data.frame of odds
#' @export
#' @import httr
#' @import data.table
#' @importFrom jsonlite fromJSON
#' @examples
#' \donttest{
#' SetCredentials("TESTAPI","APITEST")
#' AcceptTermsAndConditions(accepted=TRUE)
#' GetOdds (sportname="Badminton", leagueIds=191545,,isLive=0)}
#'
GetSpecialOdds <-
  function(sportid,
           leagueids = NULL,
           since = NULL,
           oddsformat = 'AMERICAN',
           tableFormat = 'clean',
           force=TRUE){
    CheckTermsAndConditions()
    
    ## retrieve sportid
    if(missing(sportid)) {
      cat('No Sports Selected, choose one:\n')
      ViewSports()
      sportid <- readline('Selection (id): ')
    }
    
    r <- 
      sprintf('%s/v1/odds/special', .PinnacleAPI$url) %>%
      modify_url(query = list(sportId = sportid,
                              leagueIds = if(!is.null(leagueids)) paste(leagueids,collapse=',') else NULL,
                              since = since)) %>%
      httr::GET(add_headers(Authorization= authorization(),
                      "Content-Type" = "application/json")) %>%
      content(type="text") 
    
    
    # If no rows are returned, return empty data.frame
    if(identical(r, '')) return(data.frame())
    
    r %>%
      jsonlite::fromJSON(flatten = TRUE) %>%
      as.data.table %>%
      with({
        
        if(all(sapply(.,is.atomic))) .
        expandListColumns(.)
      }) %>%
      with({
        if(tableFormat == 'long')      SpreadsAndTotalsLong(.)
        else if(tableFormat == 'wide')      SpreadsAndTotalsWide(.)
        else if(tableFormat == 'subtables') .
        else if(tableFormat == 'clean') expandListColumns(.)
        else stop("Undefined value for tableFormat, options are 'mainlines','long','wide', and 'subtables'")
      }) %>%
      as.data.frame()
  }

