# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# Import ----

# Some background story:
# - There are 2 general approaches for reading spatial data:
#   - sp-way -> rgdal::readOGR()
#   - sf-way -> sf::st_read()
# - The sp approach was used at first, but was abandoned chiefly because the sp 
#     classes (e.g. SpatialPolygonsDataFrame) had rather complex structures 
#     that impeded method chaining.
# - The objects being handled in the sf approach more closely resemble 
#     data.frames (at least superficially), making it easier to add or modify 
#     features. It also seems that sf is more modern.
#   - There are some attributes that have to be taken care of:
#     - Dimension: set to XY using sf::st_zm()
#     - Geographic CRS: set to World Geodetic Survey for 1984 (WGS84) using 
#         sf::`st_crs<-`("WGS84")

# - Polygons of cases
#   - Points of cases (centroids of polygons)
# - Planning areas
#   - Comes with populations
#   - Comes with breakdown by dwelling type
#   - Calculate areas
#   - Add cases in planning areas
#   - Add clinics in planning areas
#   - Determine climate station for planning areas
#   - (?) Weather data
#     - (?) For the past... month? fortnight?

# Reading from URLs is too slow - download the files and read from disk

# The polygons are (200 m) x (200 m) squares
read_200x200_polys_to_points <- function(filepaths) {
  filepaths %>% 
    lapply(sf::st_read) %>% 
    dplyr::bind_rows() %>% 
    dplyr::mutate(n = as.numeric(sub(".*: (\\d+).*", "\\1", Description))) %>%
    sf::st_centroid() %>%
    .[rep(1:nrow(.), .$n),] %>%
    dplyr::select(-Name, -Description, -n)
}

dengue_case_points <- read_200x200_polys_to_points(c(
  "../data/data_gov/20200717/denguecase-central-area.kml",
  "../data/data_gov/20200717/denguecase-northeast-area.kml",
  "../data/data_gov/20200717/denguecase-southeast-area.kml",
  "../data/data_gov/20200717/denguecase-southwest-area.kml"
))

aedes_hab_points <- read_200x200_polys_to_points(c(
  "../data/data_gov/20200717/breedinghabitat-central-area.kml",
  "../data/data_gov/20200717/breedinghabitat-northeast-area.kml",
  "../data/data_gov/20200717/breedinghabitat-northwest-area.kml",
  "../data/data_gov/20200717/breedinghabitat-southeast-area.kml",
  "../data/data_gov/20200717/breedinghabitat-southwest-area.kml"
))

clinic_points <- "../data/hci_clinics_geocoords_20200722.csv" %>% 
  readr::read_csv() %>% 
  tidyr::drop_na() %>% 
  # .[!apply(is.na(.), 1, any),] %>%  # Base R
  sf::st_as_sf(coords = c("lon", "lat")) %>% 
  sf::`st_crs<-`("WGS84")

planning_areas <- "../data/data_gov/plan-bdy-dwelling-type-2017.kml" %>% 
  sf::st_read() %>% 
  sf::st_zm() %>% 
  # Extract data from the HTML in the Description column
  dplyr::bind_cols(.$Description %>% 
                     lapply(function(x) {
                       xml2::read_html(x) %>% 
                         rvest::html_node("table") %>% 
                         rvest::html_table() %>% 
                         t() %>% 
                         `colnames<-`(.[1,]) %>% 
                         .[2,]
                     }) %>% 
                     dplyr::bind_rows()) %>% 
  dplyr::rename_all(tolower) %>% 
  dplyr::rename(plan_area = pln_area_n,
                pop = total) %>% 
  dplyr::mutate(plan_area = tools::toTitleCase(tolower(plan_area)),
                dplyr::across(pop:others, as.numeric),
                area_km2 = units::set_units(sf::st_area(.), km^2)) %>% 
  dplyr::select(-name, -description, -inc_crc, -fmel_upd_d)

weather_points <- "../data/mss_daily_2020_13stations_20200722.csv" %>% 
  readr::read_csv() %>% 
  # Judgment call
  dplyr::filter(Epiweek > 23) %>%
  dplyr::mutate(temp_rng = Maximum_Temperature_degC - Minimum_Temperature_degC) %>% 
  dplyr::group_by(Station) %>% 
  # Judgment call
  dplyr::summarise(mean_rainfall = mean(Daily_Rainfall_Total_mm, na.rm = T),
                   med_rainfall = median(Daily_Rainfall_Total_mm, na.rm = T),
                   mean_temp = mean(Mean_Temperature_degC, na.rm = T),
                   med_temp = median(Mean_Temperature_degC, na.rm = T),
                   mean_temp_rng = mean(temp_rng, na.rm = T),
                   med_temp_rng = median(temp_rng, na.rm = T)) %>% 
  dplyr::left_join(readr::read_csv("../data/Station_Records.csv"), by = "Station") %>% 
  dplyr::select(-matches("Period")) %>%
  sf::st_as_sf(coords = c("Long. (E)", "Lat.(N)")) %>% 
  sf::`st_crs<-`("WGS84")

# TODO: Relook at workflow to eliminate this reassignment
planning_areas <- planning_areas %>% 
  dplyr::bind_cols(list(planning_areas, weather_points) %>% 
                     Reduce(function(planning_areas, weather_points) {
                       # Calculate inverse distance weighted (IDW) averages
                       M = planning_areas %>% 
                         sf::st_centroid() %>% 
                         sf::st_distance(weather_points) %>% 
                         # units::set_units(km) %>% 
                         { 1 / (. ^ 2) }
                       
                       weather_data = weather_points %>% 
                         as.data.frame() %>%
                         dplyr::select(-Station, -geometry) %>% 
                         as.matrix()
                       
                       (M %*% weather_data / rowSums(M)) %>% 
                         tibble::as_tibble()
                     }, .))


# Transform ----
npts_in_polys <- function(points, polygons, colname) {
  sf::st_intersects(points, polygons) %>% 
    tibble::as_tibble() %>% 
    dplyr::rename(plan_area = col.id) %>% 
    dplyr::mutate(plan_area = polygons$plan_area[plan_area]) %>% 
    dplyr::group_by(plan_area) %>% 
    dplyr::count(name = colname)
}

joined_table <- list(
  npts_in_polys(dengue_case_points, planning_areas, "ncases"),
  npts_in_polys(aedes_hab_points, planning_areas, "nhabs"),
  npts_in_polys(clinic_points, planning_areas, "nclinics"),
  planning_areas
) %>% 
  Reduce(function(x, y) dplyr::left_join(x, y, by = "plan_area"), .) %>% 
  dplyr::mutate(popden = pop / area_km2,
                caseden = as.numeric(ncases / area_km2),
                label = htmltools::HTML(paste0(plan_area,
                                               "<br/>Cases: ",
                                               ncases,
                                               "<br/>CHAS Clinics: ",
                                               nclinics,
                                               "<br/>Population: ",
                                               pop,
                                               "<br/>Area: ",
                                               round(area_km2, 2)))) %>% 
  sf::st_as_sf()

# Visualize ----

# set.seed(336483)

# area_pal <- colors() %>% 
#   .[grep("gr(a|e)y", ., invert = T)] %>% 
#   # sample(nrow(planning_areas)) %>% 
#   sample(nrow(climate_stations)) %>% 
#   leaflet::colorFactor(NULL)

caseden_pal <- leaflet::colorNumeric("Reds", joined_table$caseden)

leaflet::leaflet(height = 700, width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(data = joined_table,
                       weight = 1,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.6,
                       # fillColor = ~area_pal(plan_area),
                       # fillColor = ~area_pal(stn),
                       fillColor = ~caseden_pal(caseden),
                       label = ~label,
                       popup = ~label) %>%
  # leaflet::addPolygons(data = dengue_polys,
  #                      weight = 0.3,
  #                      opacity = 0.5,
  #                      fillOpacity = 0.8,
  #                      fillColor = ~cases_pal(ncases),
  #                      label = ~as.character(ncases)) %>%
  leaflet::addCircleMarkers(data = dengue_case_points,
                            radius = 5,
                            color = "red",
                            fillOpacity = 0.5,
                            clusterOptions = leaflet::markerClusterOptions()) %>% 
  leaflet::addLabelOnlyMarkers(data = joined_table %>% 
                                 dplyr::select(geometry) %>% 
                                 dplyr::bind_cols(joined_table$plan_area) %>% 
                                 setNames(c("plan_area", "geometry")) %>% 
                                 sf::st_centroid(),
                               label =  ~plan_area,
                               labelOptions = leaflet::labelOptions(
                                 noHide = T,
                                 direction = "center",
                                 textOnly = T,
                                 style = list(
                                   "color" = "blue"
                                 )
                               ))
  # leaflet::addMarkers(data = climate_stations,
  #                     popup = ~Station,
  #                     label = ~Station) %>%
  {.}

# Model ----

joined_table %>% 
  dplyr::group_by(stn) %>% 
  dplyr::summarize(ncases = sum(ncases)) %>% 
  leaflet::leaflet() %>% 
  leaflet::addTiles() %>% 
  leaflet::addPolygons(label = ~stn)

# Modifiable areal unit problem (MAUP)
# Must be careful in how you frame the results
# Ecological fallacy
# Do not extend conclusions for one level of aggregation to another





# Convenience functions ----
quick_polys <- function(paths) {
  paths %>% 
    lapply(sf::st_read) %>% 
    dplyr::bind_rows() %>% 
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

quick_polys("../data/data_gov/singapore-residents-by-planning-area-and-type-of-dwelling-jun-2017-kml.kml")
quick_polys("../data/data_gov/plan-bdy-dwelling-type-2017.kml")
quick_polys("../data/data_gov/areas-with-high-aedes-population/areas-with-high-aedes-population-kml.kml")
