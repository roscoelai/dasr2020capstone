# get_dos_monthly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_dos_monthly <- function() {
  #' Get Monthly Weather Records from Singapore Department of Statistics (DOS)
  #' 
  #' @description
  #' Air Temperature And Sunshine, Relative Humidity And Rainfall, Monthly.
  #' 
  #' It's just a single file. But it's wide form, need to tidy.
  #' 
  #' @details https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv
  #' 
  #' @return A table containing the combined historical monthly records.
  #' @examples
  #' get_dos_monthly()
  url = "https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv"
  
  readr::read_csv(url, na = c("", "na"), skip = 1, n_max = 10) %>% 
    tidyr::gather("year_month", "value", -Variables) %>% 
    dplyr::mutate(date = lubridate::ymd(paste(year_month, "01")),
                  year = lubridate::year(date),
                  month = lubridate::month(date),
                  Variables = gsub("\\s", "_", Variables)) %>% 
    dplyr::select(-c(year_month, date)) %>% 
    tidyr::spread(Variables, value) %>% 
    setNames(., c("Year",
                  "Month",
                  "24_Hours_Mean_Relative_Humidity_percent",
                  "Air_Temperature_Absolute_Extremes_Maximum_degC",
                  "Air_Temperature_Absolute_Extremes_Minimum_degC",
                  "Air_Temperature_Means_Daily_Maximum_degC",
                  "Air_Temperature_Means_Daily_Minimum_degC",
                  "Bright_Sunshine_Daily_Mean_hour",
                  "Highest_Daily_Rainfall_Total_mm",
                  "Minimum_Relative_Humidity_percent",
                  "Number_Of_Rainy_Days",
                  "Total_Rainfall_mm"))
}

s_data <- get_dos_monthly()

dplyr::glimpse(s_data)

# write.csv(s_data, "../results/weather_monthly_1975_2020.csv", row.names = F)
