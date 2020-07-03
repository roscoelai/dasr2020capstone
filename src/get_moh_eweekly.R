# get_moh_eweekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_moh_eweekly <- function(path) {
  #' Get (Epi) Weekly Records from Ministry of Health (MOH)
  #' 
  #' @description
  #' Available data ranges from 2012-W01 to 2020-W25.
  #' 
  #' The file is a multi-sheet Excel Workbook. Each sheet stores a year's data.
  #' 
  #' @details
  #' "https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020ea2c0b1cec1549009844537d52f2377f.xlsx"
  #' 
  #' @param path The file path of the dataset.
  #' @return A table containing the combined historical epi-weekly records.
  #' @examples
  #' get_moh_eweekly("dataset.xlsx")
  
  # Read multiple sheets in an Excel Workbook
  dfs = path %>% 
    readxl::excel_sheets() %>% 
    set_names(., .) %>%
    lapply(readxl::read_xlsx, path = path, skip = 1)
  
  # Start and End date formats are different for 2020
  dfs[["2020"]]$Start = lubridate::dmy(dfs[["2020"]]$Start)
  dfs[["2020"]]$End = lubridate::dmy(dfs[["2020"]]$End)
  
  for (y in names(dfs)) {
    # Add a "Year" column to distinguish different tables
    dfs[[y]]$Year = y
    
    # There is some inconsistent naming of column headers
    names(dfs[[y]])[names(dfs[[y]]) == "Campylobacter enterosis"] <- "Campylobacter enteritis"
    names(dfs[[y]])[names(dfs[[y]]) == "Campylobacterenterosis"] <- "Campylobacter enteritis"
    names(dfs[[y]])[names(dfs[[y]]) == "Campylobacteriosis"] <- "Campylobacter enteritis"
    names(dfs[[y]])[names(dfs[[y]]) == "Chikungunya Fever"] <- "Chikungunya"
    names(dfs[[y]])[names(dfs[[y]]) == "Dengue Haemorrhagic Fever"] <- "DHF"
    names(dfs[[y]])[names(dfs[[y]]) == "Dengue Fever"] <- "Dengue"
    names(dfs[[y]])[names(dfs[[y]]) == "Hand, Foot and Mouth Disease"] <- "HFMD"
    names(dfs[[y]])[names(dfs[[y]]) == "Hand, Foot Mouth Disease"] <- "HFMD"
    names(dfs[[y]])[names(dfs[[y]]) == "Nipah virus infection"] <- "Nipah"
    names(dfs[[y]])[names(dfs[[y]]) == "Viral Hepatitis A"] <- "Acute Viral Hepatitis A"
    names(dfs[[y]])[names(dfs[[y]]) == "Viral Hepatitis E"] <- "Acute Viral Hepatitis E"
    names(dfs[[y]])[names(dfs[[y]]) == "Zika Virus Infection"] <- "Zika"
    names(dfs[[y]])[names(dfs[[y]]) == "Zika virus infection"] <- "Zika"
  }
  
  dplyr::bind_rows(dfs)
}

df <- get_moh_eweekly("../data/weekly-infectious-disease-bulletin-year-2020ea2c0b1cec1549009844537d52f2377f.xlsx")
