# get_nea_daily.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

get_nea_daily <- function(breakdown = TRUE) {
  #' Get Cluster Case Numbers from National Environment Agency (NEA)
  #' 
  #' @description 
  #' 
  #' @details https://www.nea.gov.sg/dengue-zika/dengue/dengue-clusters
  #' 
  #' @param breakdown Keep breakdown by location. Defaults to TRUE.
  #' @return A table containing the combined current records.
  #' @examples
  #' get_nea_daily()
  response = xml2::read_html("https://www.nea.gov.sg/dengue-zika/dengue/dengue-clusters") %>% 
    rvest::html_nodes("#mainContent_mainContent_TFA5CC790007_Col00 > div.surveillance-table-wrap > table") %>% 
    rvest::html_table(fill = T)
  
  result = response[[1]] %>% 
    setNames(.[1,]) %>% 
    dplyr::select(-`Alert Level`) %>% 
    dplyr::slice(-1) %>% 
    tidyr::drop_na() %>% 
    tibble::as_tibble()
  
  if (!breakdown) {
    result = result %>% 
      dplyr::select(1:(ncol(.) - 2)) %>%
      dplyr::distinct()
  }
  
  result
}

df <- get_nea_daily(breakdown = F)

