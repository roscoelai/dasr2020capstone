# get_mss_daily.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_mss_daily <- function(years, stations = c("Changi")) {
  #' Get Daily Records from Meteorological Service Singapore (MSS)
  #' 
  #' @description
  #' Available data ranges from Jan 1980 to May 2020.
  #' 
  #' This function will automatically calculate the epidemiological weeks.
  #' 
  #' @details http://www.weather.gov.sg/climate-historical-daily/
  #' 
  #' @param years A vector of years of interest.
  #' @param stations A vector of climate station names. Defaults to c("Changi").
  #' @return A table containing the combined historical daily records.
  #' @examples
  #' get_mss_daily(2014:2018)
  #' get_mss_daily(2012:2020, c("Changi", "Marine Parade", "Queenstown", "Sembawang"))
  
  dates = as.vector(t(outer(years, sprintf("%02d", 1:12), FUN = paste0)))
  
  # There's no data beyond May 2020 (at the moment), so remove the last 7
  #   months if 2020 is included
  if (2020 %in% years) {
    dates = dates[1:(length(dates) - 7)]
  }
  
  mappings = list(
    "Ang Mo Kio" = "109_",
    "Buangkok" = "55_",
    "Bukit Panjang" = "64_",
    "Changi" = "24_",
    "Jurong (West)" = "44_",
    "Khatib" = "122_",
    "Lower Peirce Reservoir" = "08_",
    "Marine Parade" = "113_",
    "Punggol" = "81_",
    "Queenstown" = "77_",
    "Seletar" = "25_",
    "Sembawang" = "80_",
    "Serangoon" = "36_",
    "Toa Payoh" = "88_",
    "Yishun" = "91_"
  )
  station_nums = sapply(stations, function(x) mappings[[x]])
  urls = paste0("http://www.weather.gov.sg/files/dailydata/DAILYDATA_S", 
                t(outer(station_nums, dates, FUN = paste0)), 
                ".csv")
  
  myreader = function(url) {
    tryCatch(
      readr::read_csv(url) %>% 
        # The "degree sign" in column headers are invalid multibyte characters
        # Data after Apr 2020 have slightly different column names
        # This would complicate joining the tables together
        # So, it might be better to manually label all column names
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
        # The "long dashes" (em dash?) representing missing values are invalid
        #   multibyte characters and are replaced with NA (by coercion)
        dplyr::mutate_at(dplyr::vars(-Station), as.numeric),
      error = function(e) { NA }
    )
  }
  
  dfs = lapply(urls, myreader)
  
  dplyr::bind_rows(dfs[!is.na(dfs)]) %>% 
    dplyr::mutate(Date = paste(Year, Month, Day, sep = "-"),
                  Epiweek = lubridate::epiweek(Date)) %>% 
    dplyr::select(Station, Epiweek, everything(), -Date)
}

df <- get_mss_daily(years = 2012:2020,
                    stations = c("Changi",
                                 "Marine Parade",
                                 "Queenstown",
                                 "Sembawang"))

# write.csv(df, "../results/weather_daily_2012_2020.csv", row.names = F)
