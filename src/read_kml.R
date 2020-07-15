# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# - Polygons of cases
#   - Points of cases (centroids of polygons)
# - Planning areas
#   - Sizes of planning areas
#   - Populations in planning areas
#   - Clinics in planning areas
#   - Cases in planning areas
#   - Climate station for planning areas

# TODO:
# - Assign population age groups to planning areas
# - Assign housing types to planning areas

# Import ----

# Reading from URLs is too slow - download the files and read from disk

dengue_polys <- c(
  "../data/data_gov/20200709/dengue-cases-central/dengue-cases-central-kml.kml",
  "../data/data_gov/20200709/dengue-cases-north-east/dengue-cases-north-east-kml.kml",
  "../data/data_gov/20200709/dengue-cases-south-east/dengue-cases-south-east-kml.kml",
  "../data/data_gov/20200709/dengue-cases-south-west/dengue-cases-south-west-kml.kml"
) %>% 
  lapply(sf::st_read) %>% 
  dplyr::bind_rows() %>% 
  tibble::as_tibble() %>%
  tidyr::extract(Description, "ncases", ".*Cases : (\\d+).*", convert = T) %>%
  sf::st_as_sf() %>% 
  sf::st_zm()

dengue_points <- dengue_polys %>% 
  sf::st_centroid() %>% 
  .[rep(1:nrow(.), .$ncases),] %>% 
  dplyr::select(-Name, -ncases)

planning_areas <- 
  paste0("../data/data_gov/master-plan-2014-planning-area-boundary-no-sea/",
         "MP14_PLNG_AREA_NO_SEA_PL.kml") %>% 
  sf::st_read() %>% 
  tibble::as_tibble() %>% 
  tidyr::extract(Description, "area_km2", ".*Area<.*?<td>(.*?)<.*") %>% 
  dplyr::mutate(Name = tools::toTitleCase(tolower(Name)),
                area_km2 = as.numeric(area_km2) / 1e6) %>% 
  dplyr::rename(plan_area = Name) %>% 
  sf::st_as_sf() %>% 
  sf::st_zm()

# We might want more stations, and explore how to aggregate their data
climate_stations <- readr::read_csv("../data/Station_Records.csv") %>% 
  dplyr::filter(Station %in% c("Ang Mo Kio",
                               "Changi",
                               "Pasir Panjang",
                               "Tai Seng")) %>% 
  dplyr::select(Station, matches("Lat|Long")) %>% 
  sf::st_as_sf(coords = c("Long. (E)", "Lat.(N)")) %>% 
  sf::`st_crs<-`("wgs84")

# Find nearest stations
planning_areas$stn <- planning_areas %>% 
  sf::st_centroid() %>% 
  sf::st_distance(climate_stations) %>% 
  apply(1, FUN = which.min) %>% 
  climate_stations$Station[.]

populations <- 
  paste0("../data/data_gov/",
         "resident-population-by-planning-area-subzone-age-group-and-sex-2015/",
         "resident-population-by-planning-area-age-group-and-sex.csv") %>% 
  readr::read_csv() %>% 
  dplyr::rename(sex = level_1,
                age_group = level_2,
                plan_area = level_3,
                pop = value) %>% 
  dplyr::filter(sex == "Total" & 
                  age_group == "Total" & 
                  plan_area != "Total") %>% 
  dplyr::mutate(plan_area = gsub("- Total", "", plan_area)) %>% 
  dplyr::select(-year, -sex, -age_group)

chas_points <- "../data/data_gov/chas-clinics/chas-clinics-kml.kml" %>% 
  sf::st_read() %>% 
  dplyr::select(-Name, -Description) %>% 
  sf::st_zm()

# Transform ----

# Check Coordinate Reference Systems
# sf::st_crs(dengue_points)
# sf::st_crs(planning_areas)

count_pts_in_polys <- function(points, polygons, colname) {
  sf::st_intersects(points, polygons) %>% 
    tibble::as_tibble() %>% 
    dplyr::rename(plan_area = col.id) %>% 
    dplyr::mutate(plan_area = polygons$plan_area[plan_area]) %>% 
    dplyr::group_by(plan_area) %>% 
    dplyr::count(name = colname)
}

ncases_in_areas <- count_pts_in_polys(dengue_points, planning_areas, "ncases")
nclinics_in_areas <- count_pts_in_polys(chas_points, planning_areas, "nclinics")

joined_table <- ncases_in_areas %>% 
  dplyr::inner_join(nclinics_in_areas, by = "plan_area") %>% 
  dplyr::inner_join(planning_areas, by = "plan_area") %>% 
  dplyr::inner_join(populations, by = "plan_area") %>% 
  dplyr::mutate(label = htmltools::HTML(paste0(plan_area,
                                               "<br/>Cases: ",
                                               ncases,
                                               "<br/>CHAS Clinics: ",
                                               nclinics,
                                               "<br/>Population: ",
                                               pop,
                                               "<br/>Area: ",
                                               round(area_km2, 2),
                                               "<br/>Climate station: ",
                                               stn))) %>% 
  sf::st_as_sf()

# Visualize ----
set.seed(336483)

area_pal <- colors() %>% 
  .[grep("gr(a|e)y", ., invert = T)] %>% 
  # sample(nrow(planning_areas)) %>% 
  sample(nrow(climate_stations)) %>% 
  leaflet::colorFactor(NULL)

# area_cases_pal <- leaflet::colorNumeric("Reds", joined_table$ncases)
cases_pal <- leaflet::colorNumeric("Reds", dengue_polys$ncases)

leaflet::leaflet(height = 700, width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(data = joined_table,
                       weight = 1,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.5,
                       # fillColor = ~area_pal(plan_area),
                       fillColor = ~area_pal(stn),
                       # fillColor = ~area_cases_pal(ncases),
                       label = ~label,
                       popup = ~label) %>%
  leaflet::addPolygons(data = dengue_polys,
                       weight = 0.3,
                       opacity = 0.5,
                       fillOpacity = 0.8,
                       fillColor = ~cases_pal(ncases),
                       label = ~as.character(ncases)) %>%
  leaflet::addCircleMarkers(data = dengue_points,
                            radius = 5,
                            color = "red",
                            fillOpacity = 0.5,
                            clusterOptions = leaflet::markerClusterOptions()) %>%
  leaflet::addMarkers(data = climate_stations,
                      popup = ~Station,
                      label = ~Station) %>%
  {.}



# Model ----

joined_table %>% 
  dplyr::group_by(stn) %>% 
  dplyr::summarize(ncases = sum(ncases)) %>% 
  leaflet::leaflet() %>% 
  leaflet::addTiles() %>% 
  leaflet::addPolygons(label = ~stn)

# Modifiable aerial unit problem (MAUP)
# Must be careful in how you frame the results
# Ecological fallacy
# Do not extend conclusions for one level of aggregation to another





# Convenience functions ----
quick_polys <- function(paths) {
  paths %>% 
    sf::st_read() %>% 
    sf::st_zm() %>% 
    leaflet::leaflet(width = "100%") %>% 
    leaflet::addTiles() %>% 
    leaflet::addPolygons(popup = ~Description,
                         weight = 1)
}

quick_points <- function(paths) {
  paths %>% 
    sf::st_read() %>% 
    sf::st_zm() %>% 
    leaflet::leaflet(width = "100%") %>%
    leaflet::addTiles() %>%
    leaflet::addCircleMarkers(radius = 5,
                              color = "red",
                              fillOpacity = 0.5,
                              popup = ~Description,
                              clusterOptions = leaflet::markerClusterOptions())
}

quick_polys("../data/data_gov_3/master-plan-2014-planning-area-boundary-no-sea/MP14_PLNG_AREA_NO_SEA_PL.kml")
quick_polys("../data/data_gov_1/dengue-clusters/dengue-clusters-kml.kml")
quick_points("../data/data_gov_2/chas-clinics/chas-clinics-kml.kml")
