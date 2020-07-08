# get_moh_eweekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_moh_eweekly <- function(path) {
  #' Weekly Infectious Diseases Bulletin
  #' 
  #' @description
  #' Weekly infectious diseases bulletin from the Ministry of Health (MOH). 
  #' Data from 2012-W01 to 2020-W26. Follow the URLs below to download the 
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
  #' \href{https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/weekly-infectious-disease-bulletin-year-2020ef64ac3712334d4dba1206de20313f78.xlsx}{Latest data (as of 08 Jul 2020)}
  #' 
  #' @param path The file path of the dataset.
  #' @return A table containing the combined weekly records.
  
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

bulletin <- get_moh_eweekly("../data/weekly-infectious-disease-bulletin-year-2020ef64ac3712334d4dba1206de20313f78.xlsx")
