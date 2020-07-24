# import_moh_weekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_moh_weekly <- function(path) {
  #' Weekly Infectious Diseases Bulletin
  #' 
  #' @description
  #' Weekly infectious diseases bulletin from the Ministry of Health (MOH). 
  #' Data from 2012-W01 to 2020-W29. Follow the URLs below to download the 
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
  #' \href{https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-202071e221d63d4b4be0aa2b03e9c5e78ac2.xlsx}{Latest data as of 24 Jul 2020 (2012-W01 to 2020-W29)}
  #' 
  #' @param path The file path of the dataset.
  #' @return A table containing the combined weekly records.
  
  # Columns will be renamed to follow 2020
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
      
      # Date formats are different for 2020
      if (sheetname == "2020") {
        df$Start = lubridate::dmy(df$Start)
        df$End = lubridate::dmy(df$End)
      }
      
      # Find columns that need to be renamed
      mapper = na.omit(colnames_2020[names(df)])
      
      df %>% 
        dplyr::rename_with(~mapper, names(mapper)) %>% 
        # Take advantage of the sheetnames being the epidemiological years
        dplyr::mutate(Epiyear = sheetname)
    }) %>% 
    dplyr::bind_rows() %>% 
    dplyr::rename(Epiweek = `Epidemiology Wk`) %>% 
    dplyr::select(Epiyear, everything()) %>% 
    dplyr::arrange(Start)
}

bulletin <- 
  paste0(
    "../data/weekly-infectious-disease-bulletin-year-2020",
    "71e221d63d4b4be0aa2b03e9c5e78ac2.xlsx"
  ) %>% 
  import_moh_weekly()

bulletin %>%
  readr::write_csv("../data/moh_weekly_bulletin_20200724.csv")

# Import END ----
