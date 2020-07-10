# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# https://data.gov.sg/dataset/dengue-cases-central
# https://data.gov.sg/dataset/dengue-cases-north-east
# https://data.gov.sg/dataset/dengue-cases-south-east
# https://data.gov.sg/dataset/dengue-cases-south-west

import_kmls <- function(paths) {
  do.call("rbind", lapply(paths, rgdal::readOGR))
}

calc_centroids <- function(spdf) {
  spdf@data = spdf@data %>% 
    dplyr::bind_cols(as.data.frame(rgeos::gCentroid(spdf, byid = T))) %>% 
    dplyr::rename(cx = x,
                  cy = y)
  spdf
}

extract_labels <- function(spdf) {
  spdf@data$parea <-
    gsub(".*?<td>(.*?)</td>.*", "\\1", spdf@data$Description) %>% 
    tolower() %>% 
    tools::toTitleCase()
  spdf
}

extract_ncases <- function(spdf) {
  # spdf@data <- spdf@data %>% 
  #   tidyr::extract(Description, "ncases", ".*Cases : (\\d+).*", convert = T)
  spdf@data$ncases <-
    as.numeric(gsub(".*Cases : (\\d+).*", "\\1", spdf@data$Description))
  spdf
}

calc_indiv_coords <- function(spdf) {
  df = data.frame(matrix(ncol = 3, nrow = sum(spdf@data$ncases)))
  names(df) <- c("dup", "cx", "cy")
  
  i = 1L
  for (j in 1:nrow(spdf@data)) {
    for (k in 1:spdf@data[j, "ncases"]) {
      df[i, "dup"] = k
      df[i, "cx"] = spdf@data[j, "cx"]
      df[i, "cy"] = spdf@data[j, "cy"]
      i = i + 1L
    }
  }
  
  df
}

# Import ----
dengue_clusters <- import_kmls(c(
  "../data/data_gov_2/dengue-cases-central/dengue-cases-central-kml.kml",
  "../data/data_gov_2/dengue-cases-north-east/dengue-cases-north-east-kml.kml",
  "../data/data_gov_2/dengue-cases-south-east/dengue-cases-south-east-kml.kml",
  "../data/data_gov_2/dengue-cases-south-west/dengue-cases-south-west-kml.kml"
))

planning_areas <- import_kmls("../data/data_gov_2/master-plan-2019-planning-area-boundary-no-sea/planning-boundary-area.kml")

climate_stations <- readr::read_csv("../data/Station_Records.csv") %>% 
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
  dplyr::select(Station, Lat, Long)

# Transform ----
dengue_clusters <- dengue_clusters %>% 
  extract_ncases() %>% 
  calc_centroids()

dengue_cases <- calc_indiv_coords(dengue_clusters)

planning_areas <- planning_areas %>% 
  extract_labels() %>% 
  calc_centroids()

# Visualize ----
cases_pal <- leaflet::colorNumeric("Reds", dengue_clusters@data$ncases)

area_pal <- leaflet::colorFactor(RColorBrewer::brewer.pal(length(planning_areas), "Set3"), NULL)

dengue_clusters %>% 
  leaflet::leaflet() %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(data = planning_areas,
                       stroke = T,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.5,
                       fillColor = ~area_pal(parea),
                       weight = 0.5,
                       popup = ~as.character(parea)) %>%
  leaflet::addPolygons(stroke = T,
                       opacity = 5,
                       color = "black",
                       weight = 0.5,
                       smoothFactor = 0.5,
                       fillOpacity = 0.5,
                       fillColor = ~cases_pal(ncases),
                       label = ~as.character(ncases),
                       popup = ~as.character(ncases)) %>%
  leaflet::addCircleMarkers(data = dengue_cases,
                            lng = ~cx,
                            lat = ~cy,
                            radius = 5,
                            color = "red",
                            fillOpacity = 0.5,
                            clusterOptions = leaflet::markerClusterOptions()) %>%
  leaflet::addMarkers(data = climate_stations,
                      lng = ~Long,
                      lat = ~Lat,
                      popup = ~as.character(Station),
                      label = ~as.character(Station),
                      labelOptions = leaflet::labelOptions(noHide = F))

# Plot Dengue Clusters ----
real_dc <- import_kmls("../data/data_gov_1/dengue-clusters/dengue-clusters-kml.kml")

real_dc %>% 
  leaflet::leaflet() %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(stroke = T,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.5,
                       weight = 0.5,
                       popup = ~Description)
