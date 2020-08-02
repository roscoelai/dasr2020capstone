# animate_choropleth.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

animate_choropleth <- function(raw_data, .var = "Med_temp", .title = ".") {
  weather_nested = raw_data$mss_19stations %>%
    dplyr::mutate(Year = lubridate::year(Date),
                  Month = lubridate::month(Date)) %>%
    dplyr::group_by(Year, Month, Station) %>%
    dplyr::summarise(Mean_rainfall = mean(Rainfall, na.rm = T),
                     Med_temp = median(Mean_temp, na.rm = T),
                     Med_temp_rng = median(Temp_range, na.rm = T),
                     .groups = "drop") %>%
    tidyr::drop_na() %>% 
    dplyr::left_join(
      dplyr::select(raw_data$mss_63station_pos, Station:`Long. (E)`),
      by = "Station"
    ) %>% 
    sf::st_as_sf(coords = c("Long. (E)", "Lat.(N)")) %>% 
    sf::`st_crs<-`("WGS84") %>% 
    dplyr::mutate(Date = lubridate::ymd(paste(Year, Month, "01", sep = "-"))) %>% 
    dplyr::select(Date, everything()) %>% 
    dplyr::group_by(Year, Month) %>% 
    tidyr::nest()
  
  pa_polys = raw_data$planning_areas %>% 
    dplyr::select(-Name) %>% 
    dplyr::mutate(plan_area = sub(".*d>(.*?)<.*", "\\1", Description),
                  plan_area = tools::toTitleCase(tolower(plan_area)),
                  .keep = "unused")
  
  result = weather_nested$data %>% 
    lapply(function(x) {
      df = idw_interpolation(
        points = x,
        points_label = c("Station", "Date"),
        polys = pa_polys,
        polys_label = "plan_area",
        ordinal = 15
      )
      
      df$Date = x$Date[1]
      
      df
    }) %>% 
    dplyr::bind_rows() %>% 
    dplyr::left_join(pa_polys, by = "plan_area") %>% 
    sf::st_as_sf()
  
  result %>% 
    ggplot(aes(fill = .data[[.var]])) + 
    geom_sf() + 
    scale_fill_viridis_c(guide = guide_colourbar(
      title.position = "top",
      title.hjust = .5,
      barwidth = 20,
      barheight = .4
    )) +
    labs(title = .title,
         subtitle = "Date: {frame_time}") + 
    theme_void() +
    theme(legend.position = "bottom") +
    gganimate::transition_time(Date) + 
    gganimate::ease_aes("linear")
}

animate_choropleth(
  raw_data,
  .var = "Med_temp",
  .title = "Median temperatures in planning areas (2012-2020)"
)

gganimate::anim_save("../results/choropleth_med_temp_ord_15.gif")

animate_choropleth(
  raw_data,
  .var = "Med_temp_rng",
  .title = "Median temperature ranges in planning areas (2012-2020)"
)

gganimate::anim_save("../results/choropleth_med_temp_rng_ord_15.gif")
