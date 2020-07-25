# zipcodes_to_geocodes.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggmap)
library(magrittr)

zipcodes_to_geocodes <- function(zipcodes) {
  #' Get Geo-location from Google Maps
  #' 
  #' @description
  #' Attempt to obtain the longitudes, latitudes, and addresses of the given 
  #' zipcodes using ggmap::geocode().
  #' 
  #' @param zipcodes A vector of zipcodes.
  #' @return Geo-location data of the associated zipcodes.
  
  # Prompt user to input API key
  ggmap::register_google(key = readline("Please enter Google API key: "))
  
  # Create an (almost) empty tibble to append results
  res = zipcodes %>% 
    # Remove duplicates to minimize number of requests
    .[!duplicated(.)] %>% 
    tibble::as_tibble() %>% 
    dplyr::rename(zip = value) %>% 
    dplyr::mutate(lon = NA_real_,
                  lat = NA_real_,
                  address = NA_character_)
  
  for (i in 1:nrow(res)) {
    result = tryCatch({
      ggmap::geocode(res$zip[i], output = "latlona", source = "google")
    }, warning = function(w) {
      w$message
    }, error = function(e) {
      NA
    })
    
    # If the registered key is invalid, there's no point continuing
    if (grepl("The provided API key is invalid", result[1], fixed = T)) {
      stop("A valid Google API key is required.")
    }
    
    # A useful result will have something, and will have names
    if (!is.na(result) && !is.null(names(result))) {
      res$lon[i] = result$lon
      res$lat[i] = result$lat
      res$address[i] = result$address
    }
    
    # Announce progress
    message(i, " of ", nrow(res), " (",round(i / nrow(res) * 100, 2), "%)")
  }
  
  res
}

# Process START ----

hcid_s <- readr::read_csv("../data/hci_scrape_raw_20200725.csv") %>% 
  dplyr::mutate(zip = sub(".*((?i)singapore\\s+\\d+).*", "\\1", add))

hcid_s2 <- hcid_s %>% 
  dplyr::left_join(zipcodes_to_geocodes(.$zip), by = "zip")

hcid_s2 %>% 
  dplyr::select(-id, -zip, -address) %>% 
  tidyr::drop_na() %>% 
  readr::write_csv("../data/hci_clinics_20200725.csv")

# Process END ----
