get_mss_daily <- function(years) {
  #' Get Daily Records from Meteorological Service Singapore (MSS)
  #' 
  #' @description
  #' The Changi station (S24) is hard-coded here.
  #' 
  #' Available data ranges from Jan 1980 to May 2020.
  #' 
  #' @details http://www.weather.gov.sg/climate-historical-daily/
  #' 
  #' @param years A vector of years of interest.
  #' @return A table containing the combined historical daily records.
  #' @examples
  #' get_mss_daily(2014:2018)
  #' get_mss_daily(2014:2020)
  urls = paste0("http://www.weather.gov.sg/files/dailydata/DAILYDATA_S24_", 
                t(outer(years, sprintf("%02d", 1:12), FUN = paste0)), 
                ".csv")
  
  # There's no data beyond May 2020 (at the moment), so remove the last 7
  #   months if 2020 is included
  if (2020 %in% years) {
    urls = urls[1:(length(urls) - 7)]
  }
  
  myreader <- function(s) {
    readr::read_csv(s) %>% 
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
      #   multibyte characters and are replaced with NA (by coersion)
      dplyr::mutate_at(dplyr::vars(-Station), as.numeric)
  }
  
  dplyr::bind_rows(lapply(urls, myreader))
}

w_data <- get_mss_daily(years = 2014:2020)

dplyr::glimpse(w_data)

write.csv(w_data, "../results/weather_daily_2014_2020.csv", row.names = F)
