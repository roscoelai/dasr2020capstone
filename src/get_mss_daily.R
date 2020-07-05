# get_mss_daily.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_mss_daily <- function(years, stations = c("Changi")) {
  #' Get Daily Records from Meteorological Service Singapore (MSS)
  #' 
  #' @description
  #' Available data ranges from Jan 1980 to May 2020. 
  #' Epidemiological weeks will be calculated automatically.
  #' 
  #' @details http://www.weather.gov.sg/climate-historical-daily/
  #' 
  #' @param years A vector of years of interest.
  #' @param stations A vector of climate station names. Defaults to c("Changi").
  #' @return A table containing the combined historical daily records.
  #' @examples
  #' get_mss_daily(2014:2018)
  #' get_mss_daily(2012:2020, c("Changi", "Marine Parade", "Sembawang"))
  
  # All combinations of the given years and the 12 months
  dates = as.vector(t(outer(years, sprintf("%02d", 1:12), FUN = paste0)))
  
  # Remove the last 7 months if 2020 is included (no data after May 2020)
  if (2020 %in% years) {
    dates = dates[1:(length(dates) - 7)]
  }
  
  mappings = list(
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
    
    # "Boon Lay (East)" = "86_",
    # "Buangkok" = "55_",
    # "Bukit Panjang" = "64_",
    # "Lower Peirce Reservoir" = "08_",
    # "Marine Parade" = "113_",
    # "Punggol" = "81_",
    # "Queenstown" = "77_",
    # "Semakau Island" = "102_",
    # "Serangoon" = "36_",
    # "Toa Payoh" = "88_",
    # "Yishun" = "91_"
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
    # Calculate epidemiological weeks (for joining with other datasets)
    dplyr::mutate(Date = paste(Year, Month, Day, sep = "-"),
                  Epiweek = lubridate::epiweek(Date)) %>% 
    dplyr::select(Station, Epiweek, everything(), -Date)
}

# df <- get_mss_daily(years = 2012:2020,
#                     stations = c("Changi",
#                                  "Marine Parade",
#                                  "Queenstown",
#                                  "Sembawang"))

df <- get_mss_daily(years = 2012:2020,
                    stations = c("Admiralty",
                                 "Ang Mo Kio",
                                 "Changi",
                                 "Choa Chu Kang (South)",
                                 "Clementi",
                                 "East Coast Parkway",
                                 "Jurong (West)",
                                 "Jurong Island",
                                 "Khatib",
                                 "Marina Barrage",
                                 "Newton",
                                 "Pasir Panjang",
                                 "Pulau Ubin",
                                 "Seletar",
                                 "Sembawang",
                                 "Sentosa Island",
                                 "Tai Seng",
                                 "Tengah",
                                 "Tuas South"))

# write.csv(df, 
#           "../results/weather_daily_19stations_2012_2020.csv", 
#           row.names = F)

df %>% 
  dplyr::select(-Highest_30_Min_Rainfall_mm,
                -Highest_60_Min_Rainfall_mm,
                -Highest_120_Min_Rainfall_mm,
                -Mean_Wind_Speed_kmh,
                -Max_Wind_Speed_kmh) %>% 
  dplyr::group_by(Station) %>% 
  dplyr::summarise(nRain = dplyr::n() - sum(is.na(Daily_Rainfall_Total_mm)),
                   nMeanT = dplyr::n() - sum(is.na(Mean_Temperature_degC)),
                   nMaxT = dplyr::n() - sum(is.na(Maximum_Temperature_degC)),
                   nMinT = dplyr::n() - sum(is.na(Minimum_Temperature_degC))) %>% 
  dplyr::rowwise() %>% 
  dplyr::mutate(maxnT = max(nMeanT, nMaxT, nMinT),
                nRT = min(nRain, maxnT)) %>% 
  dplyr::arrange(desc(nRT)) %>% 
  dplyr::filter(!(Station %in% c("Jurong Island",
                                 "Tuas South",
                                 "Pulau Ubin",
                                 "Sentosa Island",
                                 "Seletar")))
