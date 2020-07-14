# import_mss_daily.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_mss_daily <- function(years, stations = NULL) {
  #' Historical Daily Weather Records
  #' 
  #' @description
  #' Daily weather records from the Meteorological Service Singapore (MSS). 
  #' Data from January 1980 to June 2020 potentially available. This function 
  #' will combine data from a range of years, from a list of climate stations 
  #' (refer to the list below for recognized stations). Epidemiological years 
  #' and weeks will be calculated using available date information.
  #' 
  #' Recognized climate stations:
  #' \enumerate{
  #'   \item Admiralty
  #'   \item Ang Mo Kio
  #'   \item Changi
  #'   \item Choa Chu Kang (South)
  #'   \item Clementi
  #'   \item East Coast Parkway
  #'   \item Jurong (West)
  #'   \item Jurong Island
  #'   \item Khatib
  #'   \item Marina Barrage
  #'   \item Newton
  #'   \item Pasir Panjang
  #'   \item Pulau Ubin
  #'   \item Seletar
  #'   \item Sembawang
  #'   \item Sentosa Island
  #'   \item Tai Seng
  #'   \item Tengah
  #'   \item Tuas South
  #' }
  #' 
  #' Variables:
  #' \enumerate{
  #'   \item Daily_Rainfall_Total_mm
  #'   \item Highest_30_Min_Rainfall_mm
  #'   \item Highest_60_Min_Rainfall_mm
  #'   \item Highest_120_Min_Rainfall_mm
  #'   \item Mean_Temperature_degC
  #'   \item Maximum_Temperature_degC
  #'   \item Minimum_Temperature_degC
  #'   \item Mean_Wind_Speed_kmh
  #'   \item Max_Wind_Speed_kmh
  #' }
  #' 
  #' @details
  #' \href{http://www.weather.gov.sg/climate-historical-daily/}{MSS Daily Records}
  #' 
  #' \href{http://www.weather.gov.sg/wp-content/uploads/2016/12/Station_Records.pdf}{List of stations, weather parameters and periods of records}
  #' 
  #' @param years A vector of years of interest.
  #' @param stations A vector of climate station names.
  #' @return A table containing the combined daily records.
  #' @examples
  #' import_mss_daily(2012:2020, "Changi")
  #' import_mss_daily(2012:2020, c("Changi", "Clementi", "Khatib", "Newton"))
  
  # MSS is nice enough to have their data accessible as .csv files, and they 
  #   have a systematic naming scheme! That greatly simplifies collection of 
  #   data. From the list of stations, weather parameters and periods of 
  #   records, the following climate stations have been indicated to have 
  #   captured temperature and wind speed data, in addition to rainfall data 
  #   which was common to all stations. Their names are associated with their 
  #   numbers in the following vector.
  stations_lookup = c(
    "Admiralty" = "104_",
    "Ang Mo Kio" = "109_",
    "Changi" = "24_",
    "Choa Chu Kang (South)" = "121_",
    "Clementi" = "50_",
    "East Coast Parkway" = "107_",
    "Jurong (West)" = "44_",
    "Jurong Island" = "117_",
    "Khatib" = "122_",
    "Marina Barrage" = "108_",
    "Newton" = "111_",
    "Pasir Panjang" = "116_",
    "Pulau Ubin" = "106_",
    "Seletar" = "25_",
    "Sembawang" = "80_",
    "Sentosa Island" = "60_",
    "Tai Seng" = "43_",
    "Tengah" = "23_",
    "Tuas South" = "115_"
  )
  
  # Check that all provided station names are in the list, if not, exit and 
  #   print out the list (of names) for the user.
  mask = !(stations %in% names(stations_lookup))
  if (any(mask)) {
    stop("The following station names are not recognized:\n",
         paste(stations[mask], collapse = "\n"),
         "\n\nPlease select from the following:\n",
         paste(names(stations_lookup), collapse = "\n"))
  }
  
  # If no station names specified, take the full list
  if (is.null(stations)) {
    station_nums = stations_lookup
  } else {
    station_nums = stations_lookup[stations]
  }
  
  # The full URL to each .csv file follows a certain convention:
  # - The base URL is: "http://www.weather.gov.sg/files/dailydata/DAILYDATA_S"
  # - Format: "<base URL><station number>_<YYYY><MM>.csv"
  # - We need to enumerate all <station number>-<year>-<month> combinations
  url_base = "http://www.weather.gov.sg/files/dailydata/DAILYDATA_S"
  
  # We take the Cartesian product of the station numbers (derived from the 
  #   user-input station names), the user-input years, and the 12 months ("01" 
  #   to "12"), flatten the result into a vector, then prefix with the base URL 
  #   and suffix with ".csv" to get the URLs of the desired files.
  
  # Base R
  urls = station_nums %>% 
    outer(years, FUN = paste0) %>% 
    outer(sprintf("%02d", 1:12), FUN = paste0) %>% 
    sort() %>%  # Flatten and arrange in alphabetical order
    paste0(url_base, ., ".csv")  # Prefix with base URL, suffix with ".csv"
  
  # TODO: tidyverse-way
  # urls = station_nums %>% 
  #   tidyr::crossing(years, sprintf("%02d", 1:12)) %>% 
  #   tidyr::unite("station_year_month", sep = "") %>% 
  #   dplyr::pull() %>% 
  #   paste0(url_base, ., ".csv")  # Prefix with base URL, suffix with ".csv"
  
  # Now we (attempt to) read data from each URL into a list of tables:
  # It was noted that in some of the column headers, a variant of the "degree 
  #   sign" was used (for the unit degrees Celsius). These were recognized as 
  #   invalid multibyte characters, and somehow made the table contents 
  #   inaccessible. Furthermore, the column headers had slightly different 
  #   wordings after April 2020. Thus, it was decided that the columns names 
  #   would be manually set as each table was read in order to address the 
  #   problems as well as facilitate dplyr::bind_rows() downstream.
  # It was also found that the table might contain the "em dash" (long dash) 
  #   character, also recognized as an invalid multibyte character, to denote 
  #   missing values or empty cells. These would be converted to NA upon type 
  #   coercion using as.numeric().
  dfs = urls %>% 
    lapply(function(url) {
      tryCatch(
        readr::read_csv(url) %>% 
          setNames(., c("Station",
                        "Year",
                        "Month",
                        "Day",
                        "Daily_Rainfall_Total_mm",
                        "Highest_30_Min_Rainfall_mm",
                        "Highest_60_Min_Rainfall_mm",
                        "Highest_120_Min_Rainfall_mm",
                        "Mean_Temperature_degC",
                        "Maximum_Temperature_degC",
                        "Minimum_Temperature_degC",
                        "Mean_Wind_Speed_kmh",
                        "Max_Wind_Speed_kmh")) %>% 
          dplyr::mutate_at(dplyr::vars(-Station), as.numeric),
        error = function(e) { NA })
    })
  
  # Some of the URLs might point to files that do not exist. The list would 
  #   contain a NA for those positions. These have to be deselected before 
  #   applying dplyr::bind_rows().
  # The dates, epidemiological years, and epidemiological weeks are calculated 
  #   from the year, month, and day given for each row.
  dfs[!is.na(dfs)] %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(Date = lubridate::ymd(paste(Year, Month, Day, sep = "-")),
                  Epiyear = lubridate::epiyear(Date),
                  Epiweek = lubridate::epiweek(Date)) %>% 
    dplyr::select(Station, Epiyear, Epiweek, everything(), -Date) %>% 
    dplyr::arrange(Station, Year, Month, Day)
}

# import_mss_daily(years = 2012:2020) %>% 
#   readr::write_csv("../data/mss_daily_2012_2020_19stations_20200714.csv")

# Check completeness ----
weather <- readr::read_csv("../data/mss_daily_2012_2020_19stations_20200714.csv")

# From 2012 to 2019, find the climate stations with at least 52 weeks of data 
#   per year for 6 variables.
# Step 1: Find the stations with 52 weeks of data per year
# Step 2: Check if any of the candidates has less than 6 variables
wks_per_stn_yr_var <- weather %>% 
  dplyr::filter(Epiyear < 2020) %>% 
  dplyr::select(-matches("Highest")) %>% 
  tidyr::pivot_longer(cols = Daily_Rainfall_Total_mm:Max_Wind_Speed_kmh,
                      names_to = "Variable",
                      values_to = "Values") %>% 
  tidyr::drop_na() %>% 
  dplyr::group_by(Station, Epiyear, Epiweek, Variable) %>% 
  dplyr::count(name = "days") %>% 
  dplyr::group_by(Station, Epiyear, Variable) %>% 
  dplyr::count(name = "weeks")

c_stns <- setdiff(unique(weather$Station),
                  wks_per_stn_yr_var %>% 
                    dplyr::filter(weeks < 52) %>% 
                    .$Station %>% 
                    unique())

wks_per_stn_yr_var %>% 
  dplyr::filter(Station %in% c_stns) %>% 
  dplyr::group_by(Station, Epiyear) %>% 
  dplyr::count(name = "vars") %>% 
  dplyr::filter(vars < 6)

# Nothing is good

weather2 <- weather %>% 
  dplyr::filter(Station %in% c_stns) %>% 
  dplyr::select(-matches("Highest"))

# weather2 <- import_mss_daily(years = 2012:2020,
#                          stations = c("Ang Mo Kio",
#                                       "Changi",
#                                       "Pasir Panjang",
#                                       "Tai Seng"))
# 
# weather2 %>% 
#   dplyr::select(-matches("Highest")) %>% 
#   readr::write_csv("../data/mss_daily_2012_2020_4stations_20200714.csv")
