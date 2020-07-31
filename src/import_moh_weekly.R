# import_moh_weekly.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_moh_weekly <- function(url_or_path = NULL) {
  #' Weekly Infectious Diseases Bulletin
  #' 
  #' @description
  #' \href{https://www.moh.gov.sg/resources-statistics/infectious-disease-
  #' statistics/2020/weekly-infectious-diseases-bulletin}{MOH Weekly Infectious 
  #' Disease Bulletin} from the Ministry of Health (MOH). 
  #' 
  #' \href{https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/
  #' weekly-infectious-disease-bulletin-year-2020
  #' d1092fcb484447bc96ef1722b16b0c08.xlsx}{Latest data as of 31 July 2020 
  #' (2012-W01 to 2020-W30)}.
  #' 
  #' @param url_or_path The URL or file path of the .xlsx file.
  #' @return Weekly infectious diseases bulletin (2012-W01 to 2020-W30).
  
  # If no URL or path is specified, try to get the file directly from MOH.
  if (is.null(url_or_path)) {
    url_or_path = paste0(
      "https://www.moh.gov.sg/docs/librariesprovider5/diseases-updates/",
      "weekly-infectious-disease-bulletin-year-2020",
      "d1092fcb484447bc96ef1722b16b0c08.xlsx"
    )
  }
  
  # Check if the given path is a URL by trying to download to a temp file. If 
  #   successful, return the temp file. If not, return the original path.
  xlsx_file = tryCatch({
    temp = tempfile(fileext = ".xlsx")
    download.file(url_or_path, destfile = temp, mode = "wb")
    temp
  }, error = function(e) {
    url_or_path
  })
  
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
  
  xlsx_file %>%
    readxl::excel_sheets() %>% 
    lapply(function(sheetname) {
      df = readxl::read_xlsx(xlsx_file, sheetname, skip = 1)
      
      # Date formats are different for 2020 (dmy instead of mdy)
      if (sheetname == "2020") {
        df$Start = lubridate::dmy(df$Start)
        df$End = lubridate::dmy(df$End)
      }
      
      # Find and rename columns that need to be renamed, and rename them
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
bulletin <- import_moh_weekly()

# From online repo
bulletin <- import_moh_weekly(paste0(
  "https://raw.githubusercontent.com/roscoelai/dasr2020capstone/master/",
  "data/moh/weekly-infectious-disease-bulletin-year-2020.xlsx"
))

# From local
bulletin <- import_moh_weekly(
  "../data/moh/weekly-infectious-disease-bulletin-year-2020.xlsx"
)

# Import END ----
