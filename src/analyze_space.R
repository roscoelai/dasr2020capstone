# analyze_space.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggfortify)
library(ggplot2)
library(magrittr)

read_kmls <- function(url_or_path) {
  # There are (at least) 2 approaches to handling .kml data:
  # 1. sp - rgdal::readOGR()
  # 2. sf - sf::st_read()
  #
  # The sp approach was quickly abandoned as their objects were rather complex 
  #   and did not facilitate method chaining.
  #
  # The sf approach produced objects that look like data.frames, which allowed 
  #   for method chaining, but had their own peculiarities:
  #   - Dimension: set to XY using sf::st_zm()
  #   - Geographic CRS: use sf::`st_crs<-`("WGS84") World Geodetic Survey 1984
  
  # Check if the given paths are URLs by trying to download to temp files. If 
  #   successful, return the temp files. If not, return the original paths.
  kml_files = tryCatch({
    temp = tempfile(fileext = rep(".kml", length(dsns)))
    Map(function(u, d) download.file(u, d, mode="wb"), url_or_path, temp)
    temp
  }, error = function(e) {
    url_or_path
  })
  
  kml_files %>% 
    lapply(sf::st_read, quiet = T) %>% 
    dplyr::bind_rows() %>% 
    tibble::as_tibble() %>% 
    sf::st_as_sf() %>% 
    sf::st_zm()
}

# Import ----

# Reading from URLs is too slow - download the files and read from disk

# Read from local files (check that the "../data/ folder exists)
assertthat::assert_that(dir.exists("../data/"),
                        msg = 'Unable to locate "../data/" directory.')

raw_data <- list(
  # "moh_bulletin" = import_moh_weekly(paste0(
  #   "../data/moh/weekly-infectious-disease-bulletin-year-2020",
  #   "71e221d63d4b4be0aa2b03e9c5e78ac2.xlsx"
  # )),
  
  "mss_19stations" = readr::read_csv(
    "../data/mss/mss_daily_2012_2020_19stations_20200726.csv"
  ) %>% 
    dplyr::mutate(
      # Calculate daily temperature range
      Temp_range = Max_temp - Min_temp,
      # Calculate epidemiological years and weeks
      Date = lubridate::ymd(paste(Year, Month, Day, sep = "-")),
      Epiyear = lubridate::epiyear(Date),
      Epiweek = lubridate::epiweek(Date),
      .keep = "unused"
    ),
  
  "hci_clinics" = readr::read_csv(
    "../data/hcid/hci_clinics_20200725.csv"
  ),
  
  "planning_areas" = read_kmls(
    "../data/data_gov/plan-bdy-dwelling-type-2017.kml"
  ),
  
  # The polygons are (200 m) x (200 m) squares
  "dengue_polys" = read_kmls(c(
    "../data/kmls/denguecase-central-area.kml",
    "../data/kmls/denguecase-northeast-area.kml",
    "../data/kmls/denguecase-southeast-area.kml",
    "../data/kmls/denguecase-southwest-area.kml"
  )),
  
  # The polygons are (200 m) x (200 m) squares
  "aedes_polys" = read_kmls(c(
    "../data/kmls/breedinghabitat-central-area.kml",
    "../data/kmls/breedinghabitat-northeast-area.kml",
    "../data/kmls/breedinghabitat-northwest-area.kml",
    "../data/kmls/breedinghabitat-southeast-area.kml",
    "../data/kmls/breedinghabitat-southwest-area.kml"
  )),
  
  "mss_63station_pos" = readr::read_csv(
    "../data/mss/Station_Records.csv"
  )
)

# Transform ----

data <- list(
  "dengue_points" = raw_data$dengue_polys %>% 
    dplyr::mutate(n = as.numeric(sub(".*: (\\d+).*", "\\1", Description))) %>% 
    sf::st_centroid() %>% 
    .[rep(1:nrow(.), .$n),] %>% 
    dplyr::select(-Name, -Description, -n),
  
  "aedes_points" = raw_data$aedes_polys %>% 
    dplyr::mutate(n = as.numeric(sub(".*: (\\d+).*", "\\1", Description))) %>% 
    sf::st_centroid() %>% 
    .[rep(1:nrow(.), .$n),] %>% 
    dplyr::select(-Name, -Description, -n),
  
  "clinic_points" = raw_data$hci_clinics %>% 
    sf::st_as_sf(coords = c("lon", "lat")) %>% 
    sf::`st_crs<-`("WGS84"),
  
  "weather_points" = raw_data$mss_19stations %>% 
    dplyr::filter(Epiyear == 2020) %>% 
    # Filter for the last 3 weeks
    dplyr::filter(Epiweek > max(Epiweek) - 3) %>% 
    # Aggregation schema (up to 7 days x up to 3 weeks -> 1 value)
    dplyr::group_by(Station) %>% 
    dplyr::summarise(mean_rainfall = mean(Rainfall, na.rm = T),
                     med_rainfall = median(Rainfall, na.rm = T),
                     mean_temp = mean(Mean_temp, na.rm = T),
                     med_temp = median(Mean_temp, na.rm = T),
                     mean_temp_rng = mean(Temp_range, na.rm = T),
                     med_temp_rng = median(Temp_range, na.rm = T),
                     .groups = "drop") %>% 
    tidyr::drop_na() %>% 
    dplyr::left_join(
      raw_data$mss_63station_pos %>% 
        sf::st_as_sf(coords = c("Long. (E)", "Lat.(N)")) %>% 
        sf::`st_crs<-`("WGS84") %>% 
        dplyr::select(Station),
      by = "Station"
    ) %>% 
    sf::st_as_sf(),
  
  "planning_areas" = raw_data$planning_areas %>% 
    dplyr::bind_cols(
      # Extract data from HTML in the Description column (dwelling types)
      .$Description %>% 
        lapply(function(x) {
          xml2::read_html(x) %>% 
            rvest::html_node("table") %>% 
            rvest::html_table() %>% 
            t() %>% 
            `colnames<-`(.[1,]) %>% 
            .[2, 1:10]
        }) %>% 
        dplyr::bind_rows()
    ) %>% 
    dplyr::select(-Name, -Description) %>% 
    dplyr::rename_all(tolower) %>% 
    dplyr::rename(plan_area = pln_area_n,
                  pop = total) %>% 
    dplyr::mutate(plan_area = tools::toTitleCase(tolower(plan_area)),
                  dplyr::across(pop:others, as.numeric)) %>% 
    tibble::as_tibble() %>% 
    sf::st_as_sf()
)

idw_interpolation <- function(points, polys, ordinal = 2) {
  # Inverse-distance-weighted interpolation
  weights = polys %>% 
    sf::st_centroid() %>% 
    sf::st_distance(points) %>% 
    # Small ordinal: Unweighted average
    # Large ordinal: Proximity (Thiessen) interpolation
    { 1 / (. ^ ordinal) }
  
  values = points %>% 
    as.data.frame() %>% 
    dplyr::select(-Station, -geometry) %>% 
    as.matrix()
  
  (weights %*% values / rowSums(weights)) %>% 
    tibble::as_tibble()
}

# # TODO: Can we avoid reassignment?
# data$planning_areas <- data$planning_areas %>% 
#   dplyr::bind_cols(idw_interpolation(data$weather_points, .)) %>% 
#   tibble::as_tibble() %>% 
#   sf::st_as_sf()

npts_in_polys <- function(points, polys, colname = "n") {
  sf::st_intersects(points, polys) %>% 
    tibble::as_tibble() %>% 
    dplyr::mutate(plan_area = polys$plan_area[col.id]) %>% 
    dplyr::count(plan_area, name = colname)
}

data_space <- data %>% 
  {
    list(
      npts_in_polys(.$dengue_points, .$planning_areas, "ncases"),
      npts_in_polys(.$aedes_points, .$planning_areas, "nhabs"),
      npts_in_polys(.$clinic_points, .$planning_areas, "nclinics"),
      .$planning_areas %>% 
        dplyr::bind_cols(idw_interpolation(data$weather_points, .))
    )
  } %>%
  Reduce(function(x, y) dplyr::left_join(x, y, by = "plan_area"), .) %>% 
  tibble::as_tibble() %>% 
  sf::st_as_sf() %>% 
  dplyr::mutate(
    area_km2 = units::set_units(sf::st_area(.), km^2),
    popden = pop / area_km2,
    caseden = as.numeric(ncases / area_km2),
    label = paste0(
      "<b>", plan_area,
      "</b><br/>Area: ", round(area_km2, 2),
      "<br/>Cases: ", ncases,
      "<br/>Clinics: ", nclinics,
      "<br/>Population: ", pop,
      "<br/><i>Aedes</i> habitats: ", nhabs
    )
  )

# Visualize ----

# Leaflet

# Choropleth issues:
# - Modifiable areal unit problem (MAUP)
#   - Must be careful in how you frame the results
# - Ecological fallacy
#   - Do not extend conclusions for one level of aggregation to another

data_space %>% 
  leaflet::leaflet(width = "100%") %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(
    weight = 1,
    opacity = 1,
    fillOpacity = 0.6,
    smoothFactor = 0.5,
    fillColor = ~leaflet::colorNumeric("Reds", caseden)(caseden),
    label = ~lapply(label, htmltools::HTML),
    popup = ~lapply(label, htmltools::HTML)
  ) %>%
  leaflet::addCircleMarkers(
    data = data$dengue_points,
    color = "red",
    radius = 5,
    fillOpacity = 0.5,
    clusterOptions = leaflet::markerClusterOptions()
  ) %>% 
  leaflet::addLabelOnlyMarkers(
    data = sf::st_centroid(data_space),
    label =  ~plan_area,
    labelOptions = leaflet::labelOptions(
      noHide = T,
      textOnly = T,
      direction = "center",
      style = list("color" = "blue"))
  )

# Densities
data_space %>% 
  tibble::as_tibble() %>% 
  dplyr::select(matches("^(n|med_t|pop$)")) %>% 
  tidyr::pivot_longer(everything()) %>% 
  ggplot(aes(x = value, color = name)) + 
  geom_density(size = 1) + 
  facet_wrap(name ~ ., scales = "free") + 
  labs(x = "",
       caption = "Sources: data.gov.sg, weather.gov.sg") + 
  theme(legend.position = "none")

# Scatter
data_space %>% 
  tibble::as_tibble() %>% 
  dplyr::select(matches("^(n|med_t|pop$)")) %>% 
  tidyr::pivot_longer(nhabs:med_temp_rng) %>% 
  ggplot(aes(x = value, y = ncases, color = name)) + 
  geom_point(alpha = 0.6) + 
  geom_smooth(method = "lm", formula = y ~ x, size = 0.5) + 
  facet_wrap(name ~ ., scales = "free") + 
  labs(x = "",
       caption = "Sources: data.gov.sg, weather.gov.sg") + 
  theme(legend.position = "none")

# Population-weighted
data_space_pw <- data_space %>% 
  tibble::as_tibble() %>% 
  dplyr::select(plan_area:med_temp_rng) %>% 
  dplyr::select(-pop, everything(), pop) %>% 
  dplyr::mutate_at(dplyr::vars(ncases:others), ~(. / pop)) %>% 
  dplyr::select(-pop)

data_space_pw %>% 
  dplyr::select(-plan_area) %>% 
  dplyr::mutate(ncases_sqrt = sqrt(ncases),
                ncases_log = log10(ncases),
                nhabs_sqrt = sqrt(nhabs),
                nhabs_log = log10(nhabs),
                nclinics_sqrt = sqrt(nclinics),
                nclinics_log = log10(nclinics),
                nclinics_inv = (1 / nclinics)) %>% 
  tidyr::pivot_longer(everything()) %>% 
  ggplot(aes(x = value, color = name)) + 
  geom_density(size = 1) + 
  facet_wrap(name ~ ., scales = "free") + 
  labs(x = "",
       caption = "Sources: data.gov.sg, weather.gov.sg") + 
  theme(legend.position = "none")

data_space_pw %>% 
  dplyr::select(-plan_area) %>% 
  dplyr::mutate(ncases_log = log10(ncases),
                nhabs_log = log10(nhabs),
                nclinics_inv = (1 / nclinics),
                .keep = "unused") %>% 
  tidyr::pivot_longer(-ncases_log) %>% 
  ggplot(aes(x = value, y = ncases_log, color = name)) + 
  geom_point(alpha = 0.6) + 
  geom_smooth(method = "lm", formula = y ~ x, size = 0.5) + 
  facet_wrap(name ~ ., scales = "free") + 
  labs(x = "",
       caption = "Sources: data.gov.sg, weather.gov.sg") + 
  theme(legend.position = "none")

# Model ----

# Correlation
data_space_pw %>% 
  dplyr::select(-plan_area) %>% 
  dplyr::mutate(ncases_log = log10(ncases),
                nhabs_log = log10(nhabs),
                nclinics_inv = (1 / nclinics),
                .keep = "unused") %>% 
  as.matrix() %>% 
  Hmisc::rcorr() %>% 
  broom::tidy() %>% 
  dplyr::filter(p.value < 0.05) %>%
  dplyr::arrange(estimate)

# Trial model
data_space_pw %>% 
  dplyr::select(-plan_area) %>% 
  dplyr::mutate(ncases_log = log10(ncases),
                nhabs_log = log10(nhabs),
                nclinics_inv = (1 / nclinics),
                .keep = "unused") %>% 
  lm(ncases_log ~ med_temp + med_temp_rng + nclinics_inv + nhabs_log, .) %>% 
  gvlma::gvlma()
  car::vif()
  autoplot()
  summary()
