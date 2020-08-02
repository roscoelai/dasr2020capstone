# analyze_space.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

pacman::p_load(
  ggfortify,
  ggplot2,
  magrittr
)

read_kmls <- function(url_or_path) {
  #' Read Single or Multiple KML Files
  #' 
  #' @description
  #' There are (at least) 2 approaches to handling .kml data:
  #' \enumerate{
  #'   \item sp - rgdal::readOGR()
  #'   \item sf - sf::st_read()
  #' }
  #'
  #' The sp approach was abandoned as their objects were rather complex and 
  #'   did not facilitate method chaining.
  #'
  #' The sf approach produced objects that look like data.frames, which had 
  #'   better support for method chaining, but also some peculiarities:
  #' \itemize{
  #'   \item Dimension: set to XY using sf::st_zm()
  #'   \item Geographic CRS: use sf::`st_crs<-`("WGS84") World Geodetic 
  #'         Survey 1984
  #' }
  #' 
  #' @param url_or_path The URL(s) or file path(s) of the .kml file(s).
  #' @return A single combined sf object.
  
  # Check if the given paths are URLs by trying to download to temp files. If 
  #   successful, return the temp files. If not, return the original paths. 
  #   Automatically extract .zip files, if any.
  kml_files = tryCatch({
    temp = tempfile(fileext = paste0(".", tools::file_ext(url_or_path)))
    Map(function(x, y) download.file(x, y, mode = "wb"), url_or_path, temp)
    sapply(temp, function(x) {
      if (endsWith(x, ".zip")) {
        unzip(x)
      } else {
        x
      }
    })
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

grand_import_no_webscraping <- function(from_online_repo = TRUE) {
  # Allow user to choose whether to import raw data from an online repository 
  #   or from local files.
  
  if (from_online_repo) {
    fld = paste0("https://raw.githubusercontent.com/roscoelai/",
                 "dasr2020capstone/master/data/")
  } else {
    # Check that the "../data/ folder exists
    assertthat::assert_that(dir.exists("../data/"),
                            msg = 'Unable to locate "../data/" directory.')
    fld = "../data/"
  }
  
  list(
    # "moh_bulletin" = import_moh_weekly(paste0(
    #   fld, "moh/weekly-infectious-disease-bulletin-year-2020.xlsx"
    # )),
    
    "mss_19stations" = readr::read_csv(paste0(
      fld, "mss/mss_daily_2012_2020_19stations_20200726.csv"
    )),
    
    "hci_clinics" = readr::read_csv(paste0(
      fld, "hcid/hci_clinics_20200725.csv"
    )),
    
    "planning_areas" = read_kmls(paste0(
      fld, "kmls/plan-bdy-dwelling-type-2017.kml"
    )),
    
    "dengue_polys" = read_kmls(paste0(
      fld, "kmls/denguecase-", c("central",
                                 "northeast",
                                 "southeast",
                                 "southwest"), "-area.kml"
    )),
    
    "aedes_polys" = read_kmls(paste0(
      fld, "kmls/breedinghabitat-", c("central",
                                      "northeast",
                                      "northwest",
                                      "southeast",
                                      "southwest"), "-area.kml"
    )),
    
    "mss_63station_pos" = readr::read_csv(paste0(
      fld, "mss/Station_Records.csv"
    ))
  )
}

raw_data <- grand_import_no_webscraping(from_online_repo = F)

# Transform ----

grand_transform_space <- function(raw_data) {
  data = list(
    "dengue_points" = raw_data$dengue_polys,
    "aedes_points" = raw_data$aedes_polys
  ) %>% 
    lapply(function(df) {
      df %>% 
        dplyr::transmute(n = sub(".*: (\\d+).*", "\\1", Description)) %>% 
        sf::st_centroid() %>% 
        .[rep(1:nrow(.), as.numeric(.$n)),]
    })
  
  data[["clinic_points"]] = raw_data$hci_clinics %>% 
    sf::st_as_sf(coords = c("lon", "lat")) %>% 
    sf::`st_crs<-`("WGS84")
  
  data[["weather_points"]] = raw_data$mss_19stations %>% 
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
    sf::st_as_sf()
  
  # Because we have weather_points, we can define IDW interpolation and 
  #   immediately join with planning_areas.
  
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
      tibble::as_tibble() %>% 
      dplyr::mutate(plan_area = polys$plan_area)
  }
  
  data[["planning_areas"]] = raw_data$planning_areas %>% 
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
    sf::st_as_sf() %>% 
    # Add meteorological data
    dplyr::left_join(
      idw_interpolation(data$weather_points, ., ordinal = 2),
      by = "plan_area"
    )
  
  data
}

data <- grand_transform_space(raw_data)

data_space <- list(
  ncases = data$dengue_points,
  nhabs = data$aedes_points,
  nclinics = data$clinic_points
) %>% 
  {
    # Count the number of points in each polygon
    lapply(names(.), function(name) {
      .[[name]] %>% 
        sf::st_intersects(data$planning_areas) %>%
        tibble::as_tibble() %>%
        dplyr::mutate(plan_area = data$planning_areas$plan_area[col.id]) %>%
        dplyr::count(plan_area, name = name)
    })
  } %>% 
  # Join everything
  Reduce(function(x, y) dplyr::left_join(x, y, by = "plan_area"), .) %>% 
  dplyr::left_join(data$planning_areas, by = "plan_area") %>% 
  sf::st_as_sf() %>% 
  dplyr::mutate(
    area_km2 = units::set_units(sf::st_area(.), km^2),
    popden = as.numeric(pop / area_km2),
    caseden = as.numeric(ncases / area_km2),
    landedden = as.numeric(landed_properties / area_km2),
    landedprop = landed_properties / pop,
    label = paste0(
      "<b>", plan_area,
      "</b><br/>Area: ", round(area_km2, 2),
      "<br/>Cases: ", ncases,
      "<br/>Clinics: ", nclinics,
      "<br/>Population: ", pop,
      "<br/><i>Aedes</i> habitats: ", nhabs
    )
  )

data_space

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

# ncases ~ popden + landedprop

shapiro.test(data_space$popden)

data_space %>% 
  tibble::as_tibble() %>% 
  dplyr::select(ncases, popden, landedprop, -geometry) %>% 
  dplyr::mutate(landedprop_sqrt = sqrt(landedprop),
                landedprop_log = log10(landedprop),
                ncases_sqrt = sqrt(ncases),
                ncases_log = log10(ncases)) %>% 
  tidyr::pivot_longer(everything()) %>% 
  ggplot(aes(x = value, color = name)) + 
  geom_density(size = 1) + 
  facet_wrap(~name, scales = "free") + 
  theme(legend.position = "none")

data_space %>% 
  dplyr::mutate(landedprop_sqrt = sqrt(landedprop),
                landedprop_log = log10(landedprop),
                ncases_sqrt = sqrt(ncases),
                ncases_log = log10(ncases)) %>% 
  lm(ncases_log ~ popden * landedprop_sqrt, data = .) %>% 
  # gvlma::gvlma()
  summary()

ks.test(scale(data_space$ncases), scale(data_space$caseden))
data_space %>% 
  tibble::as_tibble() %>% 
  dplyr::mutate(ncases = scale(ncases),
                caseden = scale(caseden)) %>% 
  dplyr::select(ncases, caseden, -geometry) %>% 
  tidyr::pivot_longer(everything()) %>% 
  ggplot(aes(x = value, color = name)) + 
  geom_density(size = 1) + 
  facet_wrap(~name, scales = "free_x") + 
  theme(legend.position = "none")

data_space %>% 
  # lm(log10(caseden) ~ log10(popden) + landedden, data = .) %>%
  lm(log10(caseden) ~ log10(popden) + landedprop, data = .) %>%
  gvlma::gvlma()
  # car::vif()
  summary()

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
