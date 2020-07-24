# analyze_time.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

# Diseases ----

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

# bulletin_s %>% 
#   tidyr::pivot_longer(cols = c("Dengue",
#                                "HFMD",
#                                "Acute Upper Respiratory Tract infections",
#                                "Acute Diarrhoea"),
#                       names_to = "Diseases",
#                       values_to = "Numbers") %>% 
#   tidyr::drop_na() %>%
#   ggplot(aes(x = Start, y = Numbers)) + 
#   geom_point(aes(color = Diseases), size = 1, alpha = 0.4) +
#   geom_line(aes(color = Diseases), size = 0.5) + 
#   labs(title = "Weekly cases for select diseases from 2012 to 2020",
#        subtitle = "Why is there a sudden spike in dengue cases this year?",
#        x = "",
#        y = "Numbers",
#        caption = "Source: moh.gov.sg") + 
#   ggthemes::theme_fivethirtyeight() + 
#   geom_line(data = bulletin_s %>% tidyr::drop_na(),
#             aes(x = Start, y = Dengue),
#             color = "#11eebb",
#             size = 5,
#             alpha = 0.25)

# ggsave("../imgs/ncases_4diseases_2012_2020.png", width = 12, height = 6)

dplyr::glimpse(bulletin_s)

bulletin_s %>% 
  dplyr::rename(`Acute URTI` = `Acute Upper Respiratory Tract infections`) %>% 
  dplyr::mutate(Epiyear = as.factor(Epiyear)) %>%
  tidyr::pivot_longer(cols = c("Acute Diarrhoea",
                               "Acute URTI",
                               "Dengue",
                               "HFMD"),
                      names_to = "Disease",
                      values_to = "n") %>% 
  ggplot(aes(x = Start, y = n, color = Epiyear)) + 
  geom_line(size = 0.75) + 
  geom_point(alpha = 0.25) + 
  facet_grid(Disease ~ ., scales = "free_y") + 
  labs(title = "Weekly numbers from 2012 to 2020",
       x = "",
       y = "",
       caption = "Source: moh.gov.sg")

# ggsave("../imgs/ncases_4diseases_sep_2012_2020.png", width = 12, height = 6)



# Weather ----

weather_2012_2020 <- "../data/mss_daily_2012_2020_4stations_20200714.csv" %>% 
  readr::read_csv()

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

weather_wks <- weather_2012_2020 %>% 
  dplyr::mutate(temp_rng = Maximum_Temperature_degC - Minimum_Temperature_degC) %>% 
  dplyr::group_by(Station, Epiyear, Epiweek) %>% 
  dplyr::summarise(mean_rainfall_mm = mean(Daily_Rainfall_Total_mm),
                   med_rainfall_mm = median(Daily_Rainfall_Total_mm),
                   mean_temp_degc = mean(Mean_Temperature_degC),
                   med_temp_degc = median(Mean_Temperature_degC),
                   mean_temp_rng = mean(temp_rng),
                   med_temp_rng = median(temp_rng),
                   mean_wind_kmh = mean(Mean_Wind_Speed_kmh),
                   med_wind_kmh = median(Mean_Wind_Speed_kmh)) %>% 
  dplyr::left_join(bulletin_s, by = c("Epiyear", "Epiweek"))

dplyr::glimpse(weather_wks)



weather_wks %>% 
  dplyr::mutate(Epiyear = as.factor(Epiyear)) %>% 
  ggplot(aes(x = Start, y = mean_temp_rng, color = Epiyear)) + 
  geom_line() +
  geom_point(alpha = 0.25) + 
  facet_grid(Station ~ .)

weather_wks %>% 
  dplyr::transmute(start_date = paste(Epiyear, Epiweek, "Sun", sep = "-") %>% 
                     lubridate::parse_date_time("Y-W-a"))

weather_wks %>% 
  dplyr::mutate(Dengue = dplyr::lag(Dengue, 1)) %>% 
  # dplyr::filter(Epiyear == "2012") %>% 
  ggplot(aes(x = mean_temp_degc, y = log10(Dengue))) + 
  geom_point(color = "deepskyblue4", alpha = 0.5) + 
  geom_smooth(method = "lm", formula = y ~ x) + 
  facet_wrap(Epiyear ~ .)

weather_wks %>% 
  dplyr::mutate(Dengue = dplyr::lag(Dengue, 1)) %>% 
  # dplyr::filter(Epiyear == "2012") %>% 
  lm(log10(Dengue) ~ mean_temp_degc, data = .) %>% 
  summary()
gvlma::gvlma()

weather_wks %>% 
  ggplot(aes(x = temp_rng)) + 
  geom_density()
