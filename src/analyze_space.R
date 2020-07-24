# analyze_space.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

# There are (at least) 2 approaches to handling .kml data:
# 1. sp - rgdal::readOGR()
# 2. sf - sf::st_read()
#
# The sp approach was quickly abandoned as their objects were rather complex 
#   and did not facilitate method chaining. It seems to be the older approach.
#
# The sf approach produced objects that look like data.frames, which allowed 
#   for method chaining, but had their own peculiarities:
#   - Dimension: set to XY using sf::st_zm()
#   - Geographic CRS: use sf::`st_crs<-`("WGS84") World Geodetic Survey 1984

# Import ----

# Reading from URLs is too slow - download the files and read from disk

points <- list(
  # The polygons are (200 m) x (200 m) squares
  "dengue_cases" = c(
    "../data/data_gov/20200717/denguecase-central-area.kml",
    "../data/data_gov/20200717/denguecase-northeast-area.kml",
    "../data/data_gov/20200717/denguecase-southeast-area.kml",
    "../data/data_gov/20200717/denguecase-southwest-area.kml"
  ),
  "aedes_habs" = c(
    "../data/data_gov/20200717/breedinghabitat-central-area.kml",
    "../data/data_gov/20200717/breedinghabitat-northeast-area.kml",
    "../data/data_gov/20200717/breedinghabitat-northwest-area.kml",
    "../data/data_gov/20200717/breedinghabitat-southeast-area.kml",
    "../data/data_gov/20200717/breedinghabitat-southwest-area.kml"
  )
) %>% 
  lapply(function(filepaths) {
    filepaths %>% 
      lapply(sf::st_read) %>% 
      dplyr::bind_rows() %>% 
      dplyr::mutate(n = as.numeric(sub(".*: (\\d+).*", "\\1", Description))) %>%
      sf::st_centroid() %>%
      .[rep(1:nrow(.), .$n),] %>%
      dplyr::select(-Name, -Description, -n)
  })

points[["clinics"]] <- "../data/hci_clinics_geocoords_20200722.csv" %>% 
  readr::read_csv() %>% 
  tidyr::drop_na() %>% 
  # .[!apply(is.na(.), 1, any),] %>%  # Base R
  sf::st_as_sf(coords = c("lon", "lat")) %>% 
  sf::`st_crs<-`("WGS84")

points[["weather"]] <- "../data/mss_daily_2020_13stations_20200722.csv" %>% 
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

planning_areas <- "../data/data_gov/plan-bdy-dwelling-type-2017.kml" %>% 
  sf::st_read() %>% 
  sf::st_zm() %>% 
  # Extract data from the HTML in the Description column (dwelling types)
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
  dplyr::select(-name, -description, -inc_crc, -fmel_upd_d) %>% 
  # Input aggregated meteorological data
  dplyr::bind_cols(Reduce(function(polys, points) {
    # Calculate inverse distance weighted (IDW) averages
    M = polys %>% 
      sf::st_centroid() %>% 
      sf::st_distance(points) %>% 
      # units::set_units(km) %>% 
      # The power is a hyperparameter
      # A very high power would result in proximity (Thiessen) interpolation
      { 1 / (. ^ 2) }
    
    weather_data = points %>% 
      as.data.frame() %>%
      dplyr::select(-Station, -geometry) %>% 
      as.matrix()
    
    (M %*% weather_data / rowSums(M)) %>% 
      tibble::as_tibble()
  }, list(., points$weather)))

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
  npts_in_polys(points$dengue_cases, planning_areas, "ncases"),
  npts_in_polys(points$aedes_habs, planning_areas, "nhabs"),
  npts_in_polys(points$clinics, planning_areas, "nclinics"),
  planning_areas
) %>%
  Reduce(function(x, y) dplyr::left_join(x, y, by = "plan_area"), .) %>%
  dplyr::mutate(popden = pop / area_km2,
                caseden = as.numeric(ncases / area_km2),
                label = htmltools::HTML(
                  paste0(plan_area,
                         "<br/>Area: ", round(area_km2, 2),
                         "<br/>Cases: ", ncases,
                         "<br/>Clinics: ", nclinics,
                         "<br/>Population: ", pop,
                         "<br/><i>Aedes</i> habitats: ", nhabs)
                )) %>%
  sf::st_as_sf()

# Visualize ----

# set.seed(336483)

# area_pal <- colors() %>%
#   .[grep("gr(a|e)y", ., invert = T)] %>%
#   sample(nrow(planning_areas)) %>%
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
                       fillColor = ~caseden_pal(caseden),
                       label = ~label,
                       popup = ~label) %>%
  leaflet::addCircleMarkers(data = points$dengue_cases,
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
                               )) %>%
  {.}

# Model ----

# Modifiable areal unit problem (MAUP)
# - Must be careful in how you frame the results
# Ecological fallacy
# - Do not extend conclusions for one level of aggregation to another

dplyr::glimpse(joined_table)

joined_table %>% 
  tibble::as_tibble() %>% 
  dplyr::select(matches("^(n|med|pop$|area)")) %>% 
  as.matrix() %>% 
  Hmisc::rcorr() %>% 
  broom::tidy() %>% 
  dplyr::filter(p.value < 0.05) %>%
  dplyr::arrange(estimate)

m1 <- lm(ncases ~ nhabs + med_temp + pop + med_temp_rng, data = joined_table)
m1 <- lm(ncases ~ nhabs + med_temp + pop + nclinics, data = joined_table)
gvlma::gvlma(m1)
summary(m1)
car::vif(m1)

joined_table %>% 
  tibble::as_tibble() %>% 
  dplyr::select(matches("^(n|med_t|pop$)")) %>% 
  tidyr::pivot_longer(everything()) %>% 
  ggplot(aes(x = value, color = name)) + 
  geom_density() + 
  facet_wrap(name ~ ., scales = "free")

joined_table %>% 
  tibble::as_tibble() %>% 
  dplyr::select(matches("^(n|med_t|pop$)")) %>% 
  tidyr::pivot_longer(nhabs:med_temp_rng) %>% 
  ggplot(aes(x = value, y = ncases, color = name)) + 
  geom_point(alpha = 0.6) + 
  geom_smooth(method = "lm", formula = y ~ x, size = 0.5) + 
  facet_wrap(name ~ ., scales = "free")

