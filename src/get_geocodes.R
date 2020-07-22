# get_geocodes.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggmap)
library(magrittr)

get_geocodes <- function(zipcodes) {
  ggmap::register_google(key = readline("Please enter Google API key: "))
  
  df = zipcodes %>% 
    tibble::as_tibble() %>% 
    dplyr::rename(zip = value) %>% 
    dplyr::mutate(lon = NA_real_,
                  lat = NA_real_,
                  address = NA_character_)
  
  for (i in 1:nrow(df)) {
    result = tryCatch({
      ggmap::geocode(df$zip[i], output = "latlona", source = "google")
    }, warning = function(w) {
      w$message
    }, error = function(e) {
      NA
    })
    
    if (grepl("The provided API key is invalid", result[1], fixed = T)) {
      stop("A valid Google API key is required.")
    }
    
    if (!is.na(result) && !is.null(names(result))) {
      df$lon[i] = result$lon
      df$lat[i] = result$lat
      df$address[i] = result$address
    }
    
    message(i, " of ", nrow(df), " (",round(i / nrow(df) * 100, 2), "%)")
  }
  
  df
}

# Import ----
df <- readr::read_csv("../results/scrape_hci_nodup_20200721.csv") %>%
  dplyr::mutate(zip = sub(".*((?i)singapore\\s+\\d+).*", "\\1", add))

# Transform ----
geocoords <- get_geocodes(df$zip)

# Save
geocoords %>% 
  readr::write_csv("../results/hci_df_20200722.csv")

# Load
geocoords <- readr::read_csv("../results/hci_geocoords_20200722.csv")

# Check
all(df$zip == geocoords$zip)

df %>% 
  dplyr::select(-zip) %>% 
  dplyr::bind_cols(geocoords)

# Save again (?)


