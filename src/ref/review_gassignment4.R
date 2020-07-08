# Group Assignment 4 Review

# library(tidyverse)
library(ggplot2)
library(magrittr)

# Import ----
job <- readr::read_csv("https://talktoroh.squarespace.com/s/JobInterview.csv")

# Explore the Dataset ----
head(job);tail(job);dplyr::glimpse(job);tibble::as_tibble(job);str(job);dim(job)

# Transform ----

# The first Y variable = Intellect_Rating
table(job$compt);table(job$thought);table(job$intell)

job$Intellect_Rating <- (job$compt + job$thought + job$intell) / 3
job$Intellect_Rating2 <- job[, 2:4] %>% rowMeans()  # Efficient coding
table(job$Intellect_Rating == job$Intellect_Rating2)

# Item Analysis (Whether Items for an Index Hang Together)
# PCA (Dimensionality Reduction)
# Cronbach's alpha (Examine Reliability of Index)
psych::alpha(job[, 2:4])  # Benchmark > 0.80

# X variable (Experimental Factor)
job <- job %>% dplyr::mutate(audio = ifelse(CONDITION == 1, 1, 0))
table(job$audio == job$CONDITION)

dplyr::glimpse(job)

# Model: OLS Regression ----
int_lm <- lm(Intellect_Rating ~ audio, data = job)
gvlma::gvlma(int_lm)  # Assumption Checks

imp_lm <- lm(Impression_Rating ~ audio, data = job)
gvlma::gvlma(imp_lm)  # Assumption Checks

hire_lm <- lm(Hire_Rating ~ audio, data = job)
gvlma::gvlma(hire_lm)  # Assumption Checks

# Model: Analysis of Variance ----
int_aov <- aov(Intellect_Rating ~ audio, data = job)
imp_aov <- aov(Impression_Rating ~ audio, data = job)
hire_aov <- aov(Hire_Rating ~ audio, data = job)

# # Assumption Checks ----
# library(gvlma)
# gvlma(int_lm);gvlma(imp_lm);gvlma(hire_lm)

# VIF check? ----
# NOPE

# Reporting Modeling Results ----
# Base R
summary(int_lm)

# Tidyverse-way Part 1: broom::
broom::glance(int_lm)

# Tidyverse-way Part 2:
jtools::export_summs(int_lm, imp_lm, hire_lm,
                     error_format = "(t = {statistic}, p = {p.value})",
                     model.names = c("Intellect", "Impression", "Hire"),
                     digits = 3)

# Vizualize ----
dplyr::glimpse(job)
job$audio <- as.factor(job$audio)

commons <- function(g) {
  g + 
    geom_boxplot(notch = T) +
    geom_jitter(alpha = 0.5, color = "deepskyblue4") + 
    stat_summary(fun.data = "mean_cl_normal",
                 geom = "errorbar",
                 color = "tomato3") + 
    scale_x_discrete(labels = c("Transcript", "Audio"),
                     name = "Modes of Pitch") + 
    coord_cartesian(ylim = c(0, 10)) + 
    theme_bw()
}

f1 <- job %>% 
  ggplot(aes(x = audio, y = Intellect_Rating)) %>% 
  commons()

f2 <- job %>% 
  ggplot(aes(x = audio, y = Impression_Rating)) %>% 
  commons()

f3 <- job %>% 
  ggplot(aes(x = audio, y = Hire_Rating)) %>% 
  commons()

gridExtra::grid.arrange(f1, f2, f3, 
                        ncol = 3,
                        top = "I am PROUD of YOU, TEAM :) ^^")

# Means and SDs (Descriptive Statistics of Your Sample) ----
results <- job %>% dplyr::group_by(audio) %>% 
  dplyr::summarize(int_M = mean(Intellect_Rating),
            int_SD = sd(Intellect_Rating),
            imp_M = mean(Impression_Rating),
            imp_SD = sd(Impression_Rating),
            hire_M = mean(Hire_Rating),
            hire_SD = sd(Hire_Rating))
results

# Thanks :)
# Benchmark: 15-20 mins
