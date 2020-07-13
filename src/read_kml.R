# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

# Import ----
import_kmls <- function(paths) {
  sf::st_zm(do.call("rbind", lapply(paths, sf::st_read)))
}

# https://data.gov.sg/dataset/dengue-cases-central
# https://data.gov.sg/dataset/dengue-cases-north-east
# https://data.gov.sg/dataset/dengue-cases-south-east
# https://data.gov.sg/dataset/dengue-cases-south-west
dengue_clusters <- import_kmls(c(
  "../data/data_gov_2/dengue-cases-central/dengue-cases-central-kml.kml",
  "../data/data_gov_2/dengue-cases-north-east/dengue-cases-north-east-kml.kml",
  "../data/data_gov_2/dengue-cases-south-east/dengue-cases-south-east-kml.kml",
  "../data/data_gov_2/dengue-cases-south-west/dengue-cases-south-west-kml.kml"
))

planning_areas <- 
  import_kmls("../data/data_gov_2/master-plan-2019-planning-area-boundary-no-sea/planning-boundary-area.kml")

climate_stations <- readr::read_csv("../data/Station_Records.csv")

# Transform ----
repeat_markers <- function(polygon_df) {
  df0 = sf::st_centroid(polygon_df)
  df0$ncases = as.numeric(df0$ncases)
  df1 = data.frame(matrix(ncol = 2, nrow = sum(df0$ncases)))
  names(df1) = c("geometry", "dup")
  
  i = 1L
  for (j in 1:nrow(df0)) {
    for (k in 1:df0$ncases[j]) {
      df1[i, "dup"] = k
      df1[i, "geometry"] = df0[j, "geometry"]
      i = i + 1L
    }
  }
  
  sf::st_as_sf(df1)
}

dengue_clusters <- dengue_clusters %>% 
  dplyr::mutate(ncases = gsub(".*Cases : (\\d+).*", "\\1", Description) %>% 
                  as.numeric())

planning_areas <- planning_areas %>% 
  dplyr::mutate(area_name = gsub(".*?<td>(.*?)</td>.*", "\\1", Description) %>% 
                  tolower() %>% 
                  tools::toTitleCase())

dengue_cases <- repeat_markers(dengue_clusters)

climate_stations <- climate_stations %>% 
  dplyr::filter(Station %in% c("Admiralty",
                               "Ang Mo Kio",
                               "Changi",
                               "Choa Chu Kang (South)",
                               "Clementi",
                               "East Coast Parkway",
                               "Khatib",
                               "Newton",
                               "Pasir Panjang",
                               "Tai Seng")) %>% 
  dplyr::mutate(Station = paste(Station, "Climate Station")) %>% 
  dplyr::rename(Lat = `Lat.(N)`,
                Long = `Long. (E)`) %>% 
  dplyr::select(Station, Lat, Long) %>%
  sf::st_as_sf(x = ., coords = c("Long", "Lat"))

# Visualize ----

cases_pal <- leaflet::colorNumeric("Reds", as.numeric(dengue_clusters$ncases))

area_pal <- colors() %>% 
  .[grep("gr(a|e)y", ., invert = T)] %>% 
  sample(nrow(planning_areas)) %>% 
  leaflet::colorFactor(NULL)

dengue_clusters %>% 
  leaflet::leaflet(width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(data = planning_areas,
                       stroke = T,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.25,
                       fillColor = ~area_pal(area_name),
                       weight = 0.5,
                       popup = ~as.character(area_name)) %>%
  leaflet::addPolygons(stroke = T,
                       weight = 0.3,
                       opacity = 0.5,
                       # color = "red",
                       # smoothFactor = 0.5,
                       fillOpacity = 0.8,
                       fillColor = ~cases_pal(as.numeric(ncases)),
                       label = ~as.character(ncases),
                       popup = ~Description) %>%
  leaflet::addCircleMarkers(data = dengue_cases,
                            radius = 5,
                            color = "red",
                            fillOpacity = 0.5,
                            clusterOptions = leaflet::markerClusterOptions()) %>%
  leaflet::addMarkers(data = climate_stations,
                      popup = ~as.character(Station),
                      label = ~as.character(Station)) %>%
  {.}

# Plot Dengue Clusters ---- From NEA/Data.gov.sg
quick_leaf <- function(paths) {
  import_kmls(paths) %>% 
    leaflet::leaflet(width = "100%") %>% 
    leaflet::addTiles() %>% 
    leaflet::addPolygons(popup = ~Description,
                         weight = 1)
}

quick_leaf("../data/data_gov_1/dengue-clusters/dengue-clusters-kml.kml")
