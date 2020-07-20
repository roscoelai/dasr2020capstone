# import_hcidirectory.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_hcidirectory <- function() {
  #' Import Healthcare Institutions Directory Records
  #' 
  #' @description
  #' The Healthcare Institutions Directory website is quite fancy, it cannot be 
  #' webscraped using naive methods.
  #' 
  #' Variables:
  #' \enumerate{
  #'   \item name: Name of clinic
  #'   \item add: Address of clinic
  #' }
  #' 
  #' @details
  #' \href{http://hcidirectory.sg/hcidirectory/}{Healthcare Institutions Directory}
  #' 
  #' @return A table containing names and addresses of clinics registered in 
  #' the Healthcare Institutions Directory.
  
  # Run a Selenium Server using `RSelenium::rsDriver()`. The parameters e.g. 
  #   `browser`, `chromever` (or `geckover` if using Firefox, or other drivers 
  #   if using other browsers) have to be properly set. Trial-and-error until a 
  #   configuration works. Set `check = T` the very first time it's run on a 
  #   system, then set `check = F` after that to speed things up.
  rD = RSelenium::rsDriver(browser = "chrome",
                           chromever = "83.0.4103.39",
                           check = F)
  
  # Connect to server with a remoteDriver instance.
  remDr = rD$client
  
  # Set timeout on waiting for elements
  remDr$setTimeout(type = "implicit", milliseconds = 10000)
  
  # Navigate to the given URL
  remDr$navigate("http://hcidirectory.sg/hcidirectory/")
  
  # Click 3 things:
  # 1. "MORE SEARCH OPTIONS"
  # 2. "Medical Clinics Only"
  # 3. "Search"
  c(
    "options" = "#moreSearchOptions",
    "medclins" = "#criteria > table > tbody > tr:nth-child(2) > td > label",
    "search" = "#search_btn_left"
  ) %>% 
    lapply(remDr$findElement, using = "css") %>% 
    purrr::walk(function(elem) elem$clickElement())
  
  # Find the number of pages
  results = remDr$findElement("#results", using = "css")
  npages = results$getElementAttribute("innerHTML")[[1]] %>% 
    xml2::read_html() %>% 
    rvest::html_node("#totalPage") %>% 
    rvest::html_attr("value") %>% 
    as.numeric()
  
  # DEBUG
  # npages = 2
  
  # # Scrape all pages
  # tbls = lapply(1:npages, function(i) {
  #   results = remDr$findElement("#results", using = "css")
  #   
  #   t = results$getElementAttribute("innerHTML")[[1]] %>% 
  #     xml2::read_html() %>% 
  #     rvest::html_nodes(".result_container:not(.showing_results)") %>% 
  #     rvest::html_nodes(".name,.add") %>% 
  #     rvest::html_text() %>% 
  #     gsub("\\s+", " ", .) %>% 
  #     trimws() %>% 
  #     { cbind(.[c(TRUE,FALSE)], .[!c(TRUE,FALSE)]) } %>% 
  #     tibble::as_tibble() %>% 
  #     setNames(c("name", "add"))
  #   
  #   print(paste0(i, " of ", npages, " (", round(i / npages * 100, 2), "%)"))
  #   
  #   # Navigate to the next page (if available)
  #   tryCatch({
  #     nextpage = remDr$findElement("#PageControl > div.r_arrow", using = "css")
  #     nextpage$clickElement()
  #   },
  #   error = function(e) {
  #     print(paste("No more pages after page", i))
  #   })
  #   
  #   t
  # })
  
  # Might have to use this method... (takes about 5-10 min)
  tbls = vector(mode = "list", length = npages)

  for (i in 1:npages) {
    results = remDr$findElement("#results", using = "css")

    tbls[[i]] = results$getElementAttribute("innerHTML")[[1]] %>%
      xml2::read_html() %>%
      rvest::html_nodes(".result_container:not(.showing_results)") %>%
      rvest::html_nodes(".name,.add") %>%
      rvest::html_text() %>%
      gsub("\\s+", " ", .) %>%
      trimws() %>%
      { cbind(.[c(TRUE,FALSE)], .[!c(TRUE,FALSE)]) } %>%
      tibble::as_tibble() %>%
      setNames(c("name", "add"))

    print(paste0(i, " of ", npages, " (", round(i / npages * 100, 2), "%)"))

    # Navigate to the next page (if available)
    terminate = tryCatch({
      nextpage = remDr$findElement("#PageControl > div.r_arrow", using = "css")
      nextpage$clickElement()
      F
    },
    error = function(e) {
      print(paste("No more pages after page", i))
      T
    })

    if (terminate) break
  }
  
  # Combine
  df = tbls %>% 
    dplyr::bind_rows()
  
  # Inspect
  df %>% 
    dplyr::glimpse()
  
  # Check
  sum(duplicated(df))
  
  # TODO: Clean
  # - Dental
  # - Specialists
  # - Duplicate addresses
  
  df %>% 
    .[duplicated(.$add) | duplicated(.$add, fromLast = T),] %>% 
    dplyr::arrange(add) %>% 
    View()
  
  df %>% 
    dplyr::filter(grepl("(?i)dental", name))
  
  
  
  # Clean up: Close browser, stop server, kill Java instance(s) inside RStudio
  remDr$close()
  rD[["server"]]$stop()
  rm(rD)
  gc()
  system("taskkill /im java.exe /f", intern = F, ignore.stdout = F)
  
  df
}

df <- import_hcidirectory()

# Save
# df %>%
#   readr::write_csv("../results/scrape_hci_20200720.csv")