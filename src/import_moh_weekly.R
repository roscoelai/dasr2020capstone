# import_moh_weekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(ggplot2)
library(magrittr)

import_moh_weekly <- function(path = NULL) {
  #' Weekly Infectious Diseases Bulletin
  #' 
  #' @description
  #' Weekly infectious diseases bulletin from the Ministry of Health (MOH). 
  #' Data from 2012-W01 to 2020-W27. Follow the URLs below to download the 
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
  #' \href{https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020301ce94d47e44d24aa16207418a38cff.xlsx}{Latest data (as of 11 Jul 2020)}
  #' 
  #' @param path The file path of the dataset.
  #' @return A table containing the combined weekly records.
  
  # # If no file path is given, download the file from MOH
  # if (is.null(path)) {
  #   url = "https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/"
  #   file = "weekly-infectious-disease-bulletin-year-2020301ce94d47e44d24aa16207418a38cff.xlsx"
  #   path = paste0("../results/", file)
  #   
  #   download.file(paste0(url, file), destfile = path)
  # }
  
  # There are variations in some column names over the years
  # The headers for 2020 will be chosen as the standard
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
    readxl::excel_sheets() %>%  # Get all sheetnames in an Excel file
    lapply(function(sheetname) {
      # The first rows are titles, not column headers, so skip = 1
      df = readxl::read_xlsx(path, sheetname, skip = 1)
      
      # The sheetnames happen to be the years
      df$Year = sheetname
      
      # Start and End date formats are different for 2020
      if (sheetname == "2020") {
        df$Start = lubridate::dmy(df$Start)
        df$End = lubridate::dmy(df$End)
      }
      
      # Standardize column names
      mask = match(names(colnames_2020), names(df))
      names(df)[na.omit(mask)] = colnames_2020[which(!is.na(mask))]
      
      df
    }) %>% 
    dplyr::bind_rows() %>%  # Will work properly if columns are standardized
    dplyr::mutate(Year = as.numeric(Year)) %>% 
    dplyr::select(Year, everything()) %>% 
    dplyr::arrange(Year, `Epidemiology Wk`)
}

# bulletin <- import_moh_weekly("../data/weekly-infectious-disease-bulletin-year-2020301ce94d47e44d24aa16207418a38cff.xlsx")
# 
# bulletin_s <- bulletin %>%
#   dplyr::select(Year,
#                 `Epidemiology Wk`,
#                 Start,
#                 End,
#                 Dengue,
#                 DHF,
#                 HFMD,
#                 `Salmonellosis(non-enteric fevers)`,
#                 `Acute Upper Respiratory Tract infections`,
#                 `Acute Diarrhoea`)
# 
# write.csv(bulletin_s,
#           "../data/moh_weekly_bulletin_s_2012_2020_tidy_20200711.csv",
#           row.names = F)

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
