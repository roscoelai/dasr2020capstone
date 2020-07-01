# Get Historical Weather Records

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# singstat.gov.sg
# Air Temperature And Sunshine, Relative Humidity And Rainfall, Monthly
s_url <- "https://www.tablebuilder.singstat.gov.sg/publicfacing/api/csv/title/15306.csv"
s_rawdata <- readr::read_csv(url_s, na = c("", "na"), skip = 1, n_max = 10)

s_data <- s_rawdata %>% 
  tidyr::gather("year_month", "value", -Variables) %>% 
  dplyr::mutate(date = lubridate::ymd(paste(year_month, "01")),
                year = lubridate::year(date),
                month = lubridate::month(date),
                Variables = gsub("\\s", "_", Variables)) %>% 
  dplyr::select(-c(year_month, date)) %>% 
  dplyr::filter(dplyr::between(year, 2014, 2018)) %>% 
  tidyr::spread(Variables, value)

s_data

# weather.gov.sg
# About the same data, but daily instead of monthly
w_url <- "http://www.weather.gov.sg/files/dailydata/DAILYDATA_S24_"
w_urls <- paste0(w_url, t(outer(2014:2020, sprintf("%02d", 1:12), FUN = paste0)), ".csv")

w_reader <- function(s) {
  t = readr::read_csv(s)
  names(t) = iconv(names(t), "UTF-8", "UTF-8", sub = "")
  t
}

w_rawdata_list <- lapply(w_urls[1:12], w_reader)
w_data <- dplyr::bind_rows(w_rawdata_list)
tail(wdata)
