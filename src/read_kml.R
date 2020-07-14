# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# This is getting messy:
# 1. Import and combine polygons of cases
# 2. Transform to points of cases (use centroids of polygons)
#     - Use points for leaflet::markerClusterOptions()
# 3. Import planning areas
# 4. Assign counts of points to planning areas
# 5. Filter out planning areas with no counts
# 6. Import climate station positions
# 7. Plot planning areas, polygons of cases, points of cases, climate stations

# TODO:
# - Assign climate stations to planning areas
# - Assign populations to planning areas
# - Assign number of clinics to planning areas

# Get dengue cases ----

dengue_polys <- c(
  # https://data.gov.sg/dataset/dengue-cases-central
  # https://data.gov.sg/dataset/dengue-cases-north-east
  # https://data.gov.sg/dataset/dengue-cases-south-east
  # https://data.gov.sg/dataset/dengue-cases-south-west
  
  "../data/data_gov_2/dengue-cases-central/dengue-cases-central-kml.kml",
  "../data/data_gov_2/dengue-cases-north-east/dengue-cases-north-east-kml.kml",
  "../data/data_gov_2/dengue-cases-south-east/dengue-cases-south-east-kml.kml",
  "../data/data_gov_2/dengue-cases-south-west/dengue-cases-south-west-kml.kml"
) %>% 
  lapply(sf::st_read) %>% 
  dplyr::bind_rows() %>% 
  tibble::as_tibble() %>%
  tidyr::extract(Description, "n", ".*Cases : (\\d+).*", convert = T) %>%
  sf::st_as_sf() %>% 
  sf::st_zm()

dengue_points <- dengue_polys %>% 
  sf::st_centroid() %>% 
  .[rep(1:nrow(.), .$n),] %>% 
  dplyr::select(-Name, -n)

planning_areas <- 
  paste0("../data/data_gov_2/master-plan-2019-planning-area-boundary-no-sea/",
         "planning-boundary-area.kml") %>% 
  sf::st_read() %>% 
  tibble::as_tibble() %>% 
  tidyr::extract(Description, "plan_area", ".*?<td>(.*?)</td>.*") %>% 
  dplyr::mutate(plan_area = tools::toTitleCase(tolower(plan_area))) %>% 
  sf::st_as_sf() %>% 
  sf::st_zm()

# Points within area ----

# Check Coordinate Reference Systems
# sf::st_crs(dengue_points)
# sf::st_crs(planning_areas)

planning_areas <- sf::st_intersects(dengue_points, planning_areas) %>% 
  tibble::as_tibble() %>% 
  dplyr::rename(Name = col.id) %>% 
  dplyr::mutate(Name = paste0("kml_", Name)) %>% 
  dplyr::group_by(Name) %>% 
  dplyr::count() %>% 
  dplyr::inner_join(planning_areas, by = "Name") %>% 
  dplyr::mutate(label = htmltools::HTML(paste0(plan_area, ":<br/>", n))) %>% 
  sf::st_as_sf()

climate_stations <- readr::read_csv("../data/Station_Records.csv") %>% 
  dplyr::filter(Station %in% c("Ang Mo Kio",
                               "Changi",
                               "Pasir Panjang",
                               "Tai Seng")) %>% 
  dplyr::select(Station, matches("Lat|Long")) %>% 
  sf::st_as_sf(coords = c("Long. (E)", "Lat.(N)"))

# Visualize ----

cases_pal <- leaflet::colorNumeric("Reds", dengue_polys$n)

set.seed(336483)

area_pal <- colors() %>% 
  .[grep("gr(a|e)y", ., invert = T)] %>% 
  sample(nrow(planning_areas)) %>% 
  leaflet::colorFactor(NULL)

leaflet::leaflet(height = 700, width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(data = planning_areas,
                       weight = 1,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.5,
                       fillColor = ~area_pal(plan_area),
                       label = ~label,
                       popup = ~label) %>%
  leaflet::addPolygons(data = dengue_polys,
                       weight = 0.3,
                       opacity = 0.5,
                       fillOpacity = 0.8,
                       fillColor = ~cases_pal(n),
                       label = ~as.character(n)) %>%
  leaflet::addCircleMarkers(data = dengue_points,
                            radius = 5,
                            color = "red",
                            fillOpacity = 0.5,
                            clusterOptions = leaflet::markerClusterOptions()) %>%
  leaflet::addMarkers(data = climate_stations,
                      popup = ~Station,
                      label = ~Station) %>%
  {.}



# Plot Dengue Clusters (From NEA/Data.gov.sg) ----
quick_leaf <- function(paths) {
  paths %>% 
    sf::st_read() %>% 
    leaflet::leaflet(width = "100%") %>% 
    leaflet::addTiles() %>% 
    leaflet::addPolygons(popup = ~Description,
                         weight = 1)
}

quick_leaf("../data/data_gov_1/dengue-clusters/dengue-clusters-kml.kml")
