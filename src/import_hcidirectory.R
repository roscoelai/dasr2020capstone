# import_hcidirectory.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_hcidirectory <- function() {
  #' Import Healthcare Institutions Directory Records
  #' 
  #' @description
  #' 
  #' 
  #' Variables:
  #' \enumerate{
  #'   \item 
  #' }
  #' 
  #' @details
  #' \href{http://hcidirectory.sg/hcidirectory/}{Healthcare Institutions Directory}
  #' 
  #' @return A table containing .
  
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
  
  # Get page 1
  c(
    "options" = "#moreSearchOptions",
    "medclins" = "#criteria > table > tbody > tr:nth-child(2) > td > label",
    "search" = "#search_btn_left"
  ) %>% 
    sapply(remDr$findElement, using = "css") %>% 
    sapply(function(elem) { elem$clickElement() })
  
  webElems = c(
    "results" = "#results",
    "nextpage" = "#PageControl > div.r_arrow > a"
  ) %>% 
    sapply(remDr$findElement, using = "css")
  
  scrape_field = function(node, class) {
    node %>% 
      rvest::html_node(class) %>% 
      rvest::html_text() %>% 
      gsub("\\s+", " ", .) %>% 
      trimws()
  }
  
  scrape_page = function(res_html) {
    res_html %>% 
      rvest::html_nodes(".result_container") %>% 
      .[2:11] %>% 
      sapply(function(node) {
        c(
          name = scrape_field(node, ".name"),
          add = scrape_field(node, ".add")
        )
      }) %>% 
      t() %>% 
      tibble::as_tibble()
  }
  
  tbls = list(scrape_page(res_html))
  
  # Get page > 1
  npages = webElems$results$getElementAttribute("innerHTML")[[1]] %>% 
    xml2::read_html() %>% 
    rvest::html_node("#totalPage") %>% 
    rvest::html_attr("value") %>% 
    as.numeric()
  
  npages = 4
  
  for (i in 2:npages) {
   tryCatch({
     webElems$nextpage$clickElement()
     
     webElems = c(
       "results" = "#results",
       "nextpage" = "#PageControl > div.r_arrow > a"
     ) %>% 
       sapply(remDr$findElement, using = "css")
     
     res_html = webElems$results$getElementAttribute("innerHTML")[[1]] %>% 
       xml2::read_html()
     
     tbls[[i]] = scrape_page(res_html)
   },
   error = function(e) { NA })
    
  }
  
  remDr$findElement("#PageControl > ul > li:nth-child(1) > a", using = "css")
  
  
  # Clean up: Close browser, stop server, kill Java instance(s) inside RStudio
  remDr$close()
  rD[["server"]]$stop()
  rm(rD)
  gc()
  system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
  
  tables %>% 
    dplyr::bind_rows()
}

df <- import_hcidirectory()
