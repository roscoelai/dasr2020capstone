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

dplyr::glimpse(bulletin_s)

bulletin_s %>% 
  # dplyr::select(-DHF, -`Salmonellosis(non-enteric fevers)`) %>% 
  tidyr::pivot_longer(cols = c("Dengue",
                               "HFMD",
                               "Acute Upper Respiratory Tract infections",
                               "Acute Diarrhoea"),
                      names_to = "Diseases",
                      values_to = "Numbers") %>% 
  tidyr::drop_na() %>%
  ggplot(aes(x = Start, y = Numbers)) + 
  geom_point(aes(color = Diseases), size = 1, alpha = 0.4) +
  geom_line(aes(color = Diseases), size = 0.5) + 
  labs(title = "Weekly cases for select diseases from 2012 to 2020",
       subtitle = "Why is there a sudden spike in dengue cases this year?",
       x = "",
       y = "Numbers",
       caption = "Source: moh.gov.sg") + 
  ggthemes::theme_fivethirtyeight() + 
  geom_line(data = bulletin_s %>% tidyr::drop_na(),
            aes(x = Start, y = Dengue),
            color = "#11eebb",
            size = 5,
            alpha = 0.25)

# ggsave("../imgs/ncases_4diseases_2012_2020.png", width = 12, height = 6)

dplyr::glimpse(bulletin_s)

bulletin_s %>% 
  dplyr::rename(`Acute URTI` = `Acute Upper Respiratory Tract infections`,
                Salmonellosis = `Salmonellosis(non-enteric fevers)`) %>% 
  dplyr::select(-DHF, -Salmonellosis) %>%
  dplyr::mutate(Epiyear = as.factor(Epiyear)) %>%
  tidyr::pivot_longer(cols = c("Acute Diarrhoea",
                               "Acute URTI",
                               "Dengue",
                               # "DHF",
                               # "Salmonellosis",
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

weather <- readr::read_csv("../data/mss_daily_2012_2020_19stations_20200714.csv")

# From 2012 to 2019, find the climate stations with at least 52 weeks of data 
#   per year for 6 variables.
# Step 1: Find the stations with 52 weeks of data per year
# Step 2: Check if any of the candidates has less than 6 variables
wks_per_stn_yr_var <- weather %>% 
  dplyr::filter(Epiyear < 2020) %>%
  dplyr::select(-matches("Highest")) %>% 
  tidyr::pivot_longer(cols = Daily_Rainfall_Total_mm:Max_Wind_Speed_kmh,
                      names_to = "Variable",
                      values_to = "Values") %>% 
  tidyr::drop_na() %>% 
  dplyr::group_by(Station, Epiyear, Epiweek, Variable) %>% 
  dplyr::count(name = "days") %>% 
  dplyr::group_by(Station, Epiyear, Variable) %>% 
  dplyr::count(name = "weeks")

c_stns <- setdiff(unique(weather$Station),
                  wks_per_stn_yr_var %>% 
                    dplyr::filter(weeks < 52) %>%
                    # dplyr::filter(weeks < 37) %>%
                    # dplyr::filter(weeks < 27) %>%
                    .$Station %>% 
                    unique())

wks_per_stn_yr_var %>% 
  dplyr::filter(Station %in% c_stns) %>% 
  dplyr::group_by(Station, Epiyear) %>% 
  dplyr::count(name = "vars") %>% 
  dplyr::filter(vars < 6)

# Nothing is good!

weather2 <- weather %>% 
  dplyr::filter(Station %in% c_stns) %>%
  # dplyr::filter(Station != "Seletar") %>% 
  # dplyr::filter(Epiyear == 2020) %>% 
  dplyr::select(-matches("Highest"))

unique(weather2$Station)

# weather2 %>% 
#   readr::write_csv("../data/mss_daily_2020_13stations_20200722.csv")

# weather2 <- import_mss_daily(years = 2012:2020,
#                          stations = c("Ang Mo Kio",
#                                       "Changi",
#                                       "Pasir Panjang",
#                                       "Tai Seng"))
# 
# weather2 %>%
#   dplyr::select(-matches("Highest")) %>%
#   readr::write_csv("../data/mss_daily_2012_2020_4stations_20200714.csv")

dplyr::glimpse(weather2)

bulletin <- "../data/moh_weekly_bulletin_s_2012_2020_tidy_20200717.csv" %>% 
  readr::read_csv() %>% 
  dplyr::select(Epiyear:Dengue)

weather_wks <- weather2 %>% 
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
  dplyr::left_join(bulletin, by = c("Epiyear", "Epiweek"))

weather_wks %>% 
  dplyr::select(mean_temp_rng, med_temp_rng)

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
