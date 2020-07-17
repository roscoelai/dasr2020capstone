# import_moh_weekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

import_moh_weekly <- function(path) {
  #' Weekly Infectious Diseases Bulletin
  #' 
  #' @description
  #' Weekly infectious diseases bulletin from the Ministry of Health (MOH). 
  #' Data from 2012-W01 to 2020-W28. Follow the URLs below to download the 
  #' dataset (single Excel file; 1 year's data per sheet). This function will 
  #' combine all data into a single table.
  #' 
  #' Number of cases:
  #' \enumerate{
  #'   \item Cholera
  #'   \item Paratyphoid
  #'   \item Typhoid
  #'   \item Acute Viral Hepatitis A
  #'   \item Acute Viral Hepatitis E
  #'   \item Poliomyelitis
  #'   \item Plague
  #'   \item Yellow Fever
  #'   \item Dengue
  #'   \item DHF
  #'   \item Malaria
  #'   \item Chikungunya
  #'   \item HFMD
  #'   \item Diphtheria
  #'   \item Measles
  #'   \item Mumps
  #'   \item Rubella
  #'   \item SARS
  #'   \item Nipah
  #'   \item Acute Viral hepatitis B
  #'   \item Encephalitis
  #'   \item Legionellosis
  #'   \item Campylobacter enteritis
  #'   \item Acute Viral hepatitis C
  #'   \item Leptospirosis
  #'   \item Melioidosis
  #'   \item Meningococcal Infection
  #'   \item Pertussis
  #'   \item Pneumococcal Disease (invasive)
  #'   \item Haemophilus influenzae type b
  #'   \item Salmonellosis(non-enteric fevers)
  #'   \item Avian Influenza
  #'   \item Zika
  #'   \item Ebola Virus Disease
  #'   \item Japanese Encephalitis
  #'   \item Tetanus
  #'   \item Botulism
  #'   \item Murine Typhus
  #' }
  #' 
  #' Average daily numbers (of polyclinic attendances):
  #' \enumerate{
  #'   \item Acute Upper Respiratory Tract infections
  #'   \item Acute Conjunctivitis
  #'   \item Acute Diarrhoea
  #'   \item Chickenpox
  #' }
  #' 
  #' @details
  #' \href{https://www.moh.gov.sg/resources-statistics/infectious-disease-statistics/2020/weekly-infectious-diseases-bulletin}{MOH Weekly Infectious Disease Bulletin}
  #'
  #' \href{https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020f3b1838244614d8a812f10e1febd31b1.xlsx}{Latest data as of 17 Jul 2020 (2012-W01 to 2020-W28)}
  #' 
  #' @param path The file path of the dataset.
  #' @return A table containing the combined weekly records.
  
  # The column headers will be made to conform to 2020
  colnames_2020 = c(
    "Campylobacter enterosis" = "Campylobacter enteritis",
    "Campylobacterenterosis" = "Campylobacter enteritis",
    "Campylobacteriosis" = "Campylobacter enteritis",
    "Chikungunya Fever" = "Chikungunya",
    "Dengue Haemorrhagic Fever" = "DHF",
    "Dengue Fever" = "Dengue",
    "Hand, Foot and Mouth Disease" = "HFMD",
    "Hand, Foot Mouth Disease" = "HFMD",
    "Nipah virus infection" = "Nipah",
    "Viral Hepatitis A" = "Acute Viral Hepatitis A",
    "Viral Hepatitis E" = "Acute Viral Hepatitis E",
    "Zika Virus Infection" = "Zika",
    "Zika virus infection" = "Zika"
  )
  
  path %>% 
    readxl::excel_sheets() %>% 
    lapply(function(sheetname) {
      df = readxl::read_xlsx(path, sheetname, skip = 1)
      
      # By a stroke of serendipity (or good planning), the sheetnames just 
      #   happen to be the epidemiological years. Otherwise, we could simply 
      #   use lubridate::epiyear() on Start or End.
      df$Epiyear = sheetname
      
      # Start and End date formats are dmy for 2020 (mdy for the others)
      if (sheetname == "2020") {
        df$Start = lubridate::dmy(df$Start)
        df$End = lubridate::dmy(df$End)
      }
      
      # Change column names
      mapper = na.omit(colnames_2020[names(df)])
      
      df %>% 
        dplyr::rename_with(~mapper, names(mapper))
    }) %>% 
    # Will work properly only if columns are standardized
    dplyr::bind_rows() %>% 
    dplyr::select(Epiyear, everything()) %>% 
    dplyr::rename(Epiweek = `Epidemiology Wk`) %>% 
    dplyr::arrange(Start)
}

# bulletin <- import_moh_weekly("../data/weekly-infectious-disease-bulletin-year-2020f3b1838244614d8a812f10e1febd31b1.xlsx")
# 
# bulletin_s <- bulletin %>%
#   dplyr::select(Epiyear,
#                 Epiweek,
#                 Start,
#                 End,
#                 Dengue,
#                 DHF,
#                 HFMD,
#                 `Salmonellosis(non-enteric fevers)`,
#                 `Acute Upper Respiratory Tract infections`,
#                 `Acute Diarrhoea`)
# 
# bulletin_s %>% 
#   readr::write_csv("../data/moh_weekly_bulletin_s_2012_2020_tidy_20200717.csv")

bulletin_s <- "../data/moh_weekly_bulletin_s_2012_2020_tidy_20200717.csv" %>% 
  readr::read_csv()

dplyr::glimpse(bulletin_s)

bulletin_s %>% 
  dplyr::select(-DHF, -`Salmonellosis(non-enteric fevers)`) %>% 
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
