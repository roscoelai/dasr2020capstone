# import_mss_daily.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_mss_daily <- function(years, stations = NULL) {
  #' Historical Daily Weather Records
  #' 
  #' @description
  #' \href{http://www.weather.gov.sg/climate-historical-daily/}{Daily weather 
  #' records} from the Meteorological Service Singapore (MSS). 
  #' Available data ranges from January 1980 to June 2020. Only 19 of the 63 
  #' climate stations are recognized by this function, because these contain 
  #' more than just rainfall data. \href{http://www.weather.gov.sg/wp-content/
  #' uploads/2016/12/Station_Records.pdf}{List of stations, weather parameters 
  #' and periods of records}.
  #' 
  #' MSS is nice enough to have their data in .csv files, with a systematic 
  #' naming scheme. Data compilation becomes as simple as generating the 
  #' appropriate list of URLs.
  #' 
  #' @param years A vector of the years of interest.
  #' @param stations A vector of the climate station names.
  #' @return Combined daily weather records.
  #' @examples
  #' import_mss_daily(2012:2020, "Changi")
  #' import_mss_daily(2012:2020, c("Changi", "Clementi", "Khatib", "Newton"))
  
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
  
  # The URL to each .csv file has the following format:
  # - "<url_base><station number>_<YYYY><MM>.csv"
  # - Notice the station numbers given above contain the "_" suffix
  url_base = "http://www.weather.gov.sg/files/dailydata/DAILYDATA_S"
  
  # To enumerate all the URLs, take the Cartesian product of:
  # - station numbers
  # - years
  # - months (we'll always attempt to find all 12 months)
  #
  # Flatten the result into a vector, then prefix and suffix with `url_base` 
  #   and ".csv", respectively.
  
  # Base R
  urls = station_nums %>% 
    outer(years, FUN = paste0) %>% 
    outer(sprintf("%02d", 1:12), FUN = paste0) %>% 
    sort() %>%  # Flatten and arrange in alphabetical order
    paste0(url_base, ., ".csv")
  
  # Equivalent tidyverse approach (for reference)
  # urls = station_nums %>% 
  #   tidyr::crossing(years, sprintf("%02d", 1:12)) %>% 
  #   tidyr::unite("station_year_month", sep = "") %>% 
  #   dplyr::pull() %>% 
  #   paste0(url_base, ., ".csv")
  
  # We have a list of URLs, but some of them may not exist (some stations do 
  #   not have data for some months). Use tryCatch() to return a table for the 
  #   URLs that exist, and a NA for those that don't.
  #
  # Problems with multibyte characters and countermeasures:
  # - Some colnames contained the "degree sign" symbol which somehow made the 
  #   table contents inaccessible. Tables after April 2020 had slightly 
  #   different colnames.
  #   - Manually set the colnames for each table.
  # - Some tables contained the "em dash" symbol to indicate missing values.
  #   - They will be coerced to NA when the columns are type cast to numeric.
  #   - There will be warning messages.
  dfs = urls %>% 
    lapply(function(url) {
      tryCatch({
        df = readr::read_csv(url,
                             skip = 1,
                             col_names = c(
                               "Station",
                               "Year",
                               "Month",
                               "Day",
                               "Rainfall",
                               "Highest_30_min_rainfall",
                               "Highest_60_min_rainfall",
                               "Highest_120_min_rainfall",
                               "Mean_temp",
                               "Max_temp",
                               "Min_temp",
                               "Mean_wind",
                               "Max_wind"
                             ),
                             col_types = readr::cols_only(
                               "Station" = "c",
                               "Year" = "n",
                               "Month" = "n",
                               "Day" = "n",
                               "Rainfall" = "n",
                               "Mean_temp" = "n",
                               "Max_temp" = "n",
                               "Min_temp" = "n"
                             ))
        
        # Announce progress (UX is important! We can tolerate lower efficiency)
        message(paste(df[1, 1:3], collapse = "_"))
        
        df
      }, error = function(e) {
        NA
      })
    })
  
  dfs[!is.na(dfs)] %>% 
    dplyr::bind_rows() %>% 
    # Calculate daily temperature range
    dplyr::mutate(Temp_range = Max_temp - Min_temp,
                  .keep = "unused") %>% 
    # Calculate epidemiological years and weeks
    dplyr::mutate(Date = lubridate::ymd(paste(Year, Month, Day, sep = "-")),
                  Epiyear = lubridate::epiyear(Date),
                  Epiweek = lubridate::epiweek(Date),
                  .keep = "unused",
                  .after = Station) %>% 
    dplyr::arrange(Station, Date)
}

# Import START ----

mss_19stations <- import_mss_daily(years = 2012:2020)

mss_19stations %>%
  readr::write_csv("../data/mss/mss_daily_2012_2020_19stations_20200726.csv")

# Import END ----



# How to use START ----

mss_19stations <- readr::read_csv(
  "../data/mss/mss_daily_2012_2020_19stations_20200728.csv"
)

# Temporal: Aggregate all stations, from 2012-2020, by (year-)weeks
# - What (how many) values are being aggregating?
mss_19stations %>% 
  tidyr::pivot_longer(Rainfall:Temp_range) %>% 
  tidyr::drop_na() %>% 
  dplyr::count(Epiyear, Epiweek, name) %>% 
  dplyr::select(name, n) %T>% 
  { print(table(.)) } %>% 
  ggplot(aes(x = n, color = name)) +
  geom_histogram() +
  facet_grid(name ~ ., scales = "free")

# - Results
mss_19stations %>% 
  dplyr::group_by(Epiyear, Epiweek) %>% 
  dplyr::summarise(Mean_rainfall = mean(Rainfall, na.rm = T),
                   Med_rainfall = median(Rainfall, na.rm = T),
                   Mean_temp = mean(Mean_temp, na.rm = T),
                   Med_temp = median(Mean_temp, na.rm = T),
                   Mean_temp_rng = mean(Temp_range, na.rm = T),
                   Med_temp_rng = median(Temp_range, na.rm = T),
                   .groups = "drop")

# Spatial: Aggregate most recent fortnight, by stations
# - What (how many) values are being aggregating?
mss_19stations %>% 
  dplyr::filter(Epiyear == 2020) %>% 
  # Filter for the last 2 weeks
  dplyr::filter(Epiweek > max(Epiweek) - 2) %>% 
  tidyr::pivot_longer(Rainfall:Temp_range) %>% 
  tidyr::drop_na() %>% 
  dplyr::count(Station, name) %>% 
  dplyr::select(name, n) %T>% 
  { print(table(.)) } %>% 
  ggplot(aes(x = n, color = name)) +
  geom_histogram() +
  facet_grid(name ~ ., scales = "free")

# - Results
mss_19stations %>% 
  dplyr::filter(Epiyear == 2020) %>% 
  # Filter for the last 2 weeks
  dplyr::filter(Epiweek > max(Epiweek) - 2) %>% 
  dplyr::group_by(Station) %>% 
  dplyr::summarise(mean_rainfall = mean(Rainfall, na.rm = T),
                   med_rainfall = median(Rainfall, na.rm = T),
                   mean_temp = mean(Mean_temp, na.rm = T),
                   med_temp = median(Mean_temp, na.rm = T),
                   mean_temp_rng = mean(Temp_range, na.rm = T),
                   med_temp_rng = median(Temp_range, na.rm = T),
                   .groups = "drop") %>% 
  tidyr::drop_na()

# How to use END ----
