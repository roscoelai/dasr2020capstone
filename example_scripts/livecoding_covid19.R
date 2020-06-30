# Prof. Roh's COVID-19 Live-Coding

# Problem Statement ----
# Y = COVID-19 cases across the US states
# X1 = Search volumes on Google Trends for COVID-19 symptoms
# X2 = Different search queries (NOT ALL search queries are created equal)
# "Headache" vs. "Shortness of breath"

# SETUP ----
# Set working directory to where the script file is (if using RStudio)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Set scientific notation penalty ("discourage" scientific notation)
options(scipen = 9999)

# library(tidyverse)  # How much can we get away with (not running this)?
library(ggplot2)  # Too troublesome otherwise...
library(magrittr)  # How else to activate pipes?

# IMPORT ----
cases_data <- readr::read_csv("https://talktoroh.squarespace.com/s/States-Reporting-Cases-of-COVID-19-to-CDC-042420.csv")

searches <- gtrendsR::gtrends(c("headache", "shortness of breath"),
                              geo = "US",
                              gprop = "web",
                              time = "2020-01-22 2020-04-17")

# TIDY ----
names(searches)
search <- tibble::tibble(searches[["interest_by_region"]])

# TRANSFORM ----
dplyr::glimpse(cases_data)
cases <- cases_data %>% dplyr::transmute(location = Jurisdiction,
                                         cases = as.numeric(`Cases Reported`))

dplyr::glimpse(cases)
dplyr::glimpse(search)

covid19 <- cases %>% dplyr::inner_join(search, by = "location")

dplyr::glimpse(covid19)
colSums(is.na(covid19))  # No missing values, good!

# MODEL ---- Y: cases, X1: hits, X2: keyword, UNIT of OBSERVATION: location
m1 <- lm(cases ~ hits, data = covid19)
gvlma::gvlma(m1)  # Assumption Checks (let's always stick gvlma after lm, ok?)

# # Tidyverse-way
# covid19 %>% 
#   ggplot(aes(x = cases)) + 
#   geom_histogram(fill = "deepskyblue4", bins = 50)

# Base R
{
  par(mfrow = c(1, 2))  # 1 row, 2 columns
  plot(density(covid19$hits, na.rm = T), main = "Hits")
  plot(density(covid19$cases, na.rm = T), main = "Cases")
}

# Two solutions for addressing GVLMA problems
# Transformation of your variables

moments::skewness(covid19$cases)

# Lesson: Handling skewed data ----
  # (1) square-root (0.5 < |skew| < 1)
  # Right (positively) skewed data
  sqrt(covid19$cases)
  # Left (negatively) skewed data
  sqrt(max(covid19$cases + 1) - covid19$cases)
  
  # (2) log transformation (|skew| = 1)
  # Right (positively) skewed data
  log10(covid19$cases)
  # Left (negatively) skewed data
  log10(max(covid19$cases + 1) - covid19$cases)
  
  # (3) inverse (|skew| > 1)
  # Right (positively) skewed data
  1/covid19$cases
  # Left (negatively) skewed data
  1/(max(covid19$cases + 1) - covid19$cases)

# Which transform to use?
{
  par(mfrow = c(1, 3))
  plot(density(sqrt(covid19$cases), na.rm = T), main = "sqrt")
  plot(density(log10(covid19$cases), na.rm = T), main = "log10")
  plot(density(1 / covid19$cases, na.rm = T), main = "inverse")
}

# Perform Log Transformation ----
m1_log <- lm(log10(cases) ~ hits, data = covid19)
gvlma::gvlma(m1_log)  # Assumption Checks

# jtools::summ(m1, robust = T)

# Poisson Regression ----
# m1_poisson <- glm(cases ~ hits, data = covid19, family = poisson(link = "log"))

# Tidyverse broom::
broom::tidy(m1_log)
broom::glance(m1_log)

m2_log <- lm(log10(cases) ~ hits * as.factor(keyword), data = covid19)
gvlma::gvlma(m2_log)  # Assumption Checks

# Report Regression Models ----
jtools::export_summs(m1_log, m2_log,
                     error_format = "(t = {statistic}, p = {p.value})",
                     model.names = c("Main Effects of Search Volumes",
                                     "Interplay of Search Volumes and Queries"),
                     digits = 3)

# Model Comparison ----
# Is there a significant difference (increase) in R2?
anova(m1_log, m2_log)

# Visualize ----
covid19 %>% 
  ggplot(aes(x = hits, y = log10(cases), label = location)) + 
  ggrepel::geom_text_repel() + 
  geom_smooth(method = "lm", formula = y ~ x, level = 0.95, aes(color = keyword)) + 
  ggthemes::scale_color_fivethirtyeight() + 
  facet_grid(. ~ keyword, scales = "free") + 
  labs(title = "The Relationships between Relative Search Volumes of Google Search Queries and Reported COVID-19 Cases",
         subtitle = "Let's revisit our interpretation",
         x = "Relative Search Volumes on Google",
         y = "The Number of Reported cases of COVID-19 (Log Transformed)",
         caption = "Source: Google Trends and Centers for Disease Control and Prevention") + 
  theme_linedraw() + 
  theme(legend.position = "none")

# YAY~!
# ~33% (?)
