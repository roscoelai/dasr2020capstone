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

# Reading from URLs is too slow - download the files and read from disk


# - Polygons of cases
#   - Points of cases (centroids of polygons)
# - Planning areas
#   - Comes with populations
#   - Comes with breakdown by dwelling type
#   - Calculate areas
#   - Add cases in planning areas
#   - Add clinics in planning areas
#   - Determine climate station for planning areas

# TODO:
# - Clinics
#   - http://hcidirectory.sg/hcidirectory/

# The squares are (200 m) x (200 m)
dengue_polys <- c(
  "../data/data_gov/20200715/denguecase-central-area.kml",
  "../data/data_gov/20200715/denguecase-northeast-area.kml",
  "../data/data_gov/20200715/denguecase-southeast-area.kml",
  "../data/data_gov/20200715/denguecase-southwest-area.kml"
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

# We might want more stations, and explore how to aggregate their data
climate_stations <- readr::read_csv("../data/Station_Records.csv") %>% 
  # dplyr::filter(Station %in% c("Ang Mo Kio",
  #                              "Changi",
  #                              "Pasir Panjang",
  #                              "Tai Seng")) %>%
  dplyr::filter(Station %in% c("Ang Mo Kio",
                               # "Admiralty",
                               "Changi",
                               "Choa Chu Kang (South)",
                               "Clementi",
                               "East Coast Parkway",
                               # "Jurong Island",
                               # "Khatib",
                               "Marina Barrage",
                               "Newton",
                               "Pasir Panjang",
                               # "Tuas South"
                               "Tai Seng")) %>%
  dplyr::select(Station, matches("Lat|Long")) %>% 
  sf::st_as_sf(coords = c("Long. (E)", "Lat.(N)")) %>% 
  sf::`st_crs<-`("WGS84")

clinics <- readr::read_csv("../results/clinics_geocoords_20200722.csv") %>% 
  .[!apply(is.na(.), 1, any),] %>% 
  sf::st_as_sf(coords = c("lon", "lat")) %>% 
  sf::`st_crs<-`("WGS84")

clinics %>% 
  leaflet::leaflet() %>% 
  leaflet::addTiles() %>% 
  leaflet::addCircleMarkers(radius = 5,
                            color = "red",
                            fillOpacity = 0.5,
                            popup = ~name,
                            clusterOptions = leaflet::markerClusterOptions())

count_pts_in_polys(clinics, planning_areas, "nclinics")

planning_areas <- "../data/data_gov/plan-bdy-dwelling-type-2017.kml" %>% 
  sf::st_read() %>% 
  sf::st_zm() %>% 
  # Extract data from the HTML in the Description column
  dplyr::bind_cols(.$Description %>% 
                     lapply(function(html) {
                       html %>% 
                         xml2::read_html() %>% 
                         rvest::html_node("table") %>% 
                         rvest::html_table() %>% 
                         t() %>% 
                         `colnames<-`(.[1,]) %>% 
                         .[2,] %>% 
                         t() %>% 
                         tibble::as_tibble()
                     }) %>% 
                     dplyr::bind_rows() %>% 
                     setNames(tolower(names(.))) %>% 
                     dplyr::select(-inc_crc, -fmel_upd_d) %>% 
                     dplyr::rename(plan_area = pln_area_n,
                                   pop = total) %>% 
                     dplyr::mutate(plan_area = plan_area %>% 
                                     tolower() %>% 
                                     tools::toTitleCase()) %>% 
                     dplyr::mutate_at(dplyr::vars(-plan_area), as.numeric)) %>% 
  dplyr::mutate(area_km2 = units::set_units(sf::st_area(.), km^2),
                # Find nearest stations
                stn = sf::st_centroid(.) %>% 
                  sf::st_distance(climate_stations) %>% 
                  apply(1, FUN = which.min) %>% 
                  climate_stations$Station[.]) %>% 
  dplyr::select(-Name, -Description)

planning_areas$stn %>% 
  unique()

# Transform ----
count_pts_in_polys <- function(points, polygons, colname) {
  sf::st_intersects(points, polygons) %>% 
    tibble::as_tibble() %>% 
    dplyr::rename(plan_area = col.id) %>% 
    dplyr::mutate(plan_area = polygons$plan_area[plan_area]) %>% 
    dplyr::group_by(plan_area) %>% 
    dplyr::count(name = colname)
}

joined_table <- dengue_points %>% 
  count_pts_in_polys(planning_areas, "ncases") %>% 
  # dplyr::inner_join("../data/data_gov/moh-chas-clinics.kml" %>% 
  #                     sf::st_read() %>% 
  #                     count_pts_in_polys(planning_areas, "nclinics"),
  #                   by = "plan_area") %>% 
  dplyr::inner_join(count_pts_in_polys(clinics, planning_areas, "nclinics"),
                    by = "plan_area") %>% 
  dplyr::inner_join(planning_areas, by = "plan_area") %>% 
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
                                               round(area_km2, 2),
                                               "<br/>Climate station: ",
                                               stn))) %>% 
  sf::st_as_sf()

climate_stations <- climate_stations %>% 
  dplyr::filter(Station %in% joined_table$stn)

# Visualize ----
set.seed(336483)

area_pal <- colors() %>% 
  .[grep("gr(a|e)y", ., invert = T)] %>% 
  # sample(nrow(planning_areas)) %>% 
  sample(nrow(climate_stations)) %>% 
  leaflet::colorFactor(NULL)

cases_pal <- leaflet::colorNumeric("Reds", dengue_polys$ncases)
caseden_pal <- leaflet::colorNumeric("Reds", joined_table$caseden)

leaflet::leaflet(height = 700, width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(data = joined_table,
                       weight = 1,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.5,
                       # fillColor = ~area_pal(plan_area),
                       # fillColor = ~area_pal(stn),
                       fillColor = ~caseden_pal(caseden),
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

df <- c(
  "../data/data_gov/20200714/aedes-mosquito-breeding-habitats-central-kml.kml",
  "../data/data_gov/20200714/aedes-mosquito-breeding-habitats-north-east-kml.kml",
  "../data/data_gov/20200714/aedes-mosquito-breeding-habitats-north-west-kml.kml",
  "../data/data_gov/20200714/aedes-mosquito-breeding-habitats-south-east-kml.kml",
  "../data/data_gov/20200714/aedes-mosquito-breeding-habitats-south-west-kml.kml"
) %>% 
   lapply(sf::st_read) %>% 
   dplyr::bind_rows() %>% 
   sf::st_zm() %>% 
   dplyr::mutate(nhab = sub(".*Habitats : (\\d+).*", "\\1", Description) %>% 
                   as.numeric())

nhab_pal <- leaflet::colorNumeric("Reds", df$nhab)

df %>% 
  # dplyr::glimpse() %>% 
  leaflet::leaflet(width = "100%") %>% 
  leaflet::addTiles() %>% 
  leaflet::addPolygons(fillOpacity = 1,
                       fillColor = ~nhab_pal(nhab),
                       popup = ~Description,
                       weight = 1)

df$nhab %>% 
  summary()
