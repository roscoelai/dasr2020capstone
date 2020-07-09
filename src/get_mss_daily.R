# get_mss_daily.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_mss_daily <- function(years, stations = "Changi") {
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
  #' @param stations A vector of climate station names. Defaults to "Changi".
  #' @return A table containing the combined daily records.
  #' @examples
  #' get_mss_daily(2012:2020, c("Changi", "Clementi", "Khatib", "Newton"))
  
  # MSS is nice enough to have their data accessible as .csv files, and they 
  #   have a systematic naming scheme! That greatly simplifies collection of 
  #   data. From the list of stations, weather parameters and periods of 
  #   records, the following climate stations have been indicated to have 
  #   captured temperature and wind speed data, in addition to rainfall data 
  #   which was common to all stations. Their names are associated with their 
  #   numbers in the following vector.
  stations_lookup = c(
    "Admiralty" = 104,
    "Ang Mo Kio" = 109,
    "Changi" = 24,
    "Choa Chu Kang (South)" = 121,
    "Clementi" = 50,
    "East Coast Parkway" = 107,
    "Jurong (West)" = 44,
    "Jurong Island" = 117,
    "Khatib" = 122,
    "Marina Barrage" = 108,
    "Newton" = 111,
    "Pasir Panjang" = 116,
    "Pulau Ubin" = 106,
    "Seletar" = 25,
    "Sembawang" = 80,
    "Sentosa Island" = 60,
    "Tai Seng" = 43,
    "Tengah" = 23,
    "Tuas South" = 115
  )
  
  # The full URL to each .csv file follows a certain convention:
  # - The base URL is: "http://www.weather.gov.sg/files/dailydata/DAILYDATA_S"
  # - Format: "<base URL><station number>_<YYYY><MM>.csv"
  # - We need to enumerate all <station number>-<year>-<month> combinations
  
  # Station numbers:
  # We find the station numbers from the user-input station names using the 
  #   look-up vector given above.
  station_nums = stations %>% 
    match(., names(stations_lookup)) %>%  # Find index positions of matches
    stations_lookup[.]  # Retrieve cognate station numbers
  
  # Year-month combinations:
  # We will enumerate all user-input years with all 12 months by taking the 
  #   Cartesian product of the user-input years with a vector of 12 months 
  #   (from "01" to "12", with leading zeroes). Some stations might not have 
  #   data for certain months (so the .csv file does not exist), but we'll 
  #   handle that using tryCatch().
  year_months = years %>% 
    outer(sprintf("%02d", 1:12),  # Use sprintf() to left pad with "0"
          FUN = paste0) %>%  # Cartesian product using paste0()
    sort()  # Flatten and arrange in chronological order
  
  # Station number-year-month combinations:
  # We now take the Cartesian product of the station numbers and the year-month 
  #   combinations, remembering the underscore ("_") between the station number 
  #   and the year.
  station_year_months = station_nums %>% 
    outer(year_months, FUN = paste, sep = "_") %>% 
    sort()  # This would also order by station number, but that's fine
  
  # TODO: Try out tidyr::crossing()
  
  # Full URLs list:
  # We simply prefix with the base URL and suffix with ".csv"
  urls = paste0("http://www.weather.gov.sg/files/dailydata/DAILYDATA_S",
                station_year_months,
                ".csv")
  
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
    dplyr::select(Station,
                  Epiyear,
                  Epiweek,
                  Date,
                  everything(),
                  -Year,
                  -Month,
                  -Day) %>% 
    dplyr::arrange(Station, Date)
}

# weather <- get_mss_daily(years = 2012:2020,
#                          stations = c("Admiralty",
#                                       "Ang Mo Kio",
#                                       "Changi",
#                                       "Choa Chu Kang (South)",
#                                       "Clementi",
#                                       "East Coast Parkway",
#                                       "Jurong (West)",
#                                       "Khatib",
#                                       "Marina Barrage",
#                                       "Newton",
#                                       "Pasir Panjang",
#                                       "Sembawang",
#                                       "Tai Seng",
#                                       "Tengah"))
# 
# write.csv(weather,
#           "../results/mss_daily_2012_2020_14stations_20200709.csv",
#           row.names = F)
