# analyze_time.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

# Import ----
bulletin_s <- "../data/moh_weekly_bulletin_20200724.csv" %>% 
  readr::read_csv() %>%
  dplyr::select(Epiyear,
                Epiweek,
                Start,
                End,
                Dengue,
                HFMD,
                `Acute Upper Respiratory Tract infections`,
                `Acute Diarrhoea`)

weather_2012_2020 <- "../data/mss_daily_2012_2020_4stations_20200714.csv" %>% 
  readr::read_csv()

# Transform ----

# Have to combine the meteorological data into a global/national aggregate
weather_national <- weather_2012_2020 %>% 
  # Calculate daily temperature range
  dplyr::mutate(dtr = Maximum_Temperature_degC - Minimum_Temperature_degC) %>% 
  # Combine 4 stations' data, combine (up to) 7 days' data
  dplyr::group_by(Epiyear, Epiweek) %>% 
  dplyr::summarise(mean_rainfall = mean(Daily_Rainfall_Total_mm),
                   med_rainfall = median(Daily_Rainfall_Total_mm),
                   mean_temp = mean(Mean_Temperature_degC),
                   med_temp = median(Mean_Temperature_degC),
                   mean_temp_rng = mean(dtr),
                   med_temp_rng = median(dtr))

combined <- weather_national %>% 
  dplyr::left_join(bulletin_s, by = c("Epiyear", "Epiweek"))

# # A way to calculate date from Epiyear and Epiweek (not always reliable)
# combined %>%
#   dplyr::mutate(start_date = paste(Epiyear, Epiweek, "Sun", sep = "-") %>%
#                   lubridate::parse_date_time("Y-W-a"))

# Visualize ----
dplyr::glimpse(combined)

# Time series
combined %>% 
  dplyr::ungroup() %>%
  dplyr::select(-matches("Epiweek|End|mean|wind")) %>% 
  dplyr::select(Epiyear, Start, everything()) %>% 
  dplyr::mutate(Epiyear = as.factor(Epiyear)) %>% 
  dplyr::rename(`Acute URTI` = `Acute Upper Respiratory Tract infections`) %>% 
  tidyr::pivot_longer(med_rainfall:`Acute Diarrhoea`) %>% 
  ggplot(aes(x = Start, y = value, color = Epiyear)) + 
  geom_line() + 
  geom_point(alpha = 0.3) + 
  facet_grid(name ~ ., scales = "free_y") + 
  labs(title = "History of variables from 2012 to 2020",
       x = "",
       y = "",
       caption = "Sources: moh.gov.sg, weather.gov.sg") + 
  theme(legend.position = "none")

# ggsave("../imgs/diseases4_weather3_2012_2020.png", width = 16, height = 10)

# Densities
combined %>% 
  dplyr::ungroup() %>%
  dplyr::select(-matches("Epi|End|Start|wind")) %>% 
  dplyr::rename(`Acute URTI` = `Acute Upper Respiratory Tract infections`) %>% 
  # Try some transformations
  dplyr::mutate(log10_Dengue = log10(Dengue),
                log10_med_rainfall = log10(med_rainfall)) %>% 
  tidyr::pivot_longer(everything()) %>% 
  ggplot(aes(x = value, color = name)) + 
  geom_density() + 
  facet_wrap(name ~ ., scales = "free") + 
  theme(legend.position = "none")

# Associations
gridExtra::grid.arrange(
  grobs = list(
    "med_rainfall",
    "med_temp",
    "med_temp_rng"
  ) %>% 
    lapply(function(var) {
      combined %>% 
        dplyr::select(matches("med|Dengue")) %>% 
        # Move dengue cases down by 1 week
        dplyr::mutate(Dengue = dplyr::lag(Dengue, 1)) %>% 
        dplyr::mutate(Epiyear = as.factor(Epiyear)) %>% 
        ggplot(aes(x = combined[[var]], y = Dengue, color = Epiyear)) + 
        geom_point(alpha = 0.5) + 
        geom_smooth(method = "lm", formula = y ~ x) + 
        facet_grid(. ~ Epiyear, scales = "free") + 
        labs(x = var) + 
        theme(legend.position = "none")
    }), nrow = 3
)



# Model ----

combined %>% 
  dplyr::mutate(Dengue = dplyr::lag(Dengue, 1)) %>% 
  # dplyr::filter(Epiyear == "2012") %>% 
  lm(log10(Dengue) ~ med_temp, data = .) %>% 
  summary()
  # gvlma::gvlma()

combined %>% 
  ggplot(aes(x = med_temp_rng)) + 
  geom_density()
