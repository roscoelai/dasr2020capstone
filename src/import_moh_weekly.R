# import_moh_weekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_moh_weekly <- function(url_or_path) {
  #' Weekly Infectious Diseases Bulletin
  #' 
  #' @description
  #' Weekly infectious diseases bulletin from the Ministry of Health (MOH). 
  #' Data from 2012-W01 to 2020-W29 (as of 24 July 2020). Relevant links to MOH 
  #' are given under details.
  #' 
  #' @details
  #' \href{https://www.moh.gov.sg/resources-statistics/infectious-disease-statistics/2020/weekly-infectious-diseases-bulletin}{MOH Weekly Infectious Disease Bulletin}
  #'
  #' \href{https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-202071e221d63d4b4be0aa2b03e9c5e78ac2.xlsx}{Latest data as of 24 July 2020 (2012-W01 to 2020-W29)}
  #' 
  #' @param url_or_path The URL or file path of the .xlsx file.
  #' @return Weekly infectious diseases bulletin (2012-W01 to 2020-W29).
  
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
  
  # Check if the given path is a URL by trying to download to a temp file. If 
  #   successful, return the temp file. If not, return the original path.
  xlsx_file = tryCatch({
    temp = tempfile(fileext = ".xlsx")
    download.file(url_or_path, destfile = temp, mode = "wb")
    temp
  }, error = function(e) {
    url_or_path
  })
  
  xlsx_file %>%
    readxl::excel_sheets() %>% 
    lapply(function(sheetname) {
      df = readxl::read_xlsx(xlsx_file, sheetname, skip = 1)
      
      # Date formats are different for 2020
      if (sheetname == "2020") {
        df$Start = lubridate::dmy(df$Start)
        df$End = lubridate::dmy(df$End)
      }
      
      # Find and rename columns that need to be renamed
      mapper = na.omit(colnames_2020[names(df)])
      dplyr::rename_with(df, ~mapper, names(mapper))
    }) %>% 
    dplyr::bind_rows() %>% 
    dplyr::rename(Epiweek = `Epidemiology Wk`) %>% 
    dplyr::mutate(Epiyear = lubridate::epiyear(Start)) %>% 
    dplyr::select(Epiyear, everything()) %>% 
    dplyr::arrange(Start)
}

# Import START ----

# From MOH
bulletin <- 
  paste0(
    "https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/",
    "weekly-infectious-disease-bulletin-year-2020",
    "71e221d63d4b4be0aa2b03e9c5e78ac2.xlsx"
  ) %>% 
  import_moh_weekly()

# From GitHub
bulletin <- 
  paste0(
    "https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/",
    "data/moh/weekly-infectious-disease-bulletin-year-2020",
    "71e221d63d4b4be0aa2b03e9c5e78ac2.xlsx"
  ) %>% 
  import_moh_weekly()

# From HDD
bulletin <- 
  paste0(
    "../data/moh/weekly-infectious-disease-bulletin-year-2020",
    "71e221d63d4b4be0aa2b03e9c5e78ac2.xlsx"
  ) %>% 
  import_moh_weekly()

bulletin %>%
  readr::write_csv("../data/moh_weekly_bulletin_20200724.csv")

# Import END ----
