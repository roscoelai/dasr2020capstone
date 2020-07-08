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
  #' (refer to the list below for recognized stations). Epidemiological weeks 
  #' will be calculated using available date information.
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
  #' @param years A vector of years of interest.
  #' @param stations A vector of climate station names. Defaults to "Changi".
  #' @return A table containing the combined daily records.
  #' @examples
  #' get_mss_daily(2012:2020, c("Changi", "Clementi", "Khatib", "Newton"))
  
  stations_vec = c(
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
  
  # List URLs with all climate station number-year-month combinations
  base_url = "http://www.weather.gov.sg/files/dailydata/DAILYDATA_S"
  station_nums = stations_vec[match(stations, names(stations_vec))]
  year_months = as.vector(t(outer(years, sprintf("%02d", 1:12), FUN = paste0)))
  station_year_months = t(outer(station_nums, year_months, FUN = paste0))
  
  urls = paste0(base_url, station_year_months, ".csv")
  
  dfs = urls %>% 
    lapply(function(url) {
      tryCatch(
        readr::read_csv(url) %>% 
          # Invalid multibyte characters "degree sign" in column headers
          # Different column names after Apr 2020
          # Manually label column names to facilitate row binding
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
          # Invalid multibyte characters "em dash" as (missing) values
          # Coerced to NA
          dplyr::mutate_at(dplyr::vars(-Station), as.numeric),
        error = function(e) { NA })
    })
  
  dfs[!is.na(dfs)] %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(Epiweek = lubridate::epiweek(paste(Year,
                                                     Month,
                                                     Day,
                                                     sep = "-"))) %>% 
    dplyr::select(Station, Epiweek, everything())
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
#           "../results/mss_daily_2012_2020_14stations_20200708.csv", 
#           row.names = F)
