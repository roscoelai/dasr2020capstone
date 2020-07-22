# import_hcidirectory.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_hcidirectory <- function() {
  #' Import Healthcare Institutions Directory Records
  #' 
  #' @description
  #' The Healthcare Institutions Directory website is rather fancy, it cannot 
  #' be webscraped using naive methods. Time for RSelenium.
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
  
  # Click 4 things:
  # 1. "MORE SEARCH OPTIONS"
  # 2. "Medical Clinics Only"
  # 3. "General Medical"
  # 4. "Search"
  c(
    "options" = "#moreSearchOptions",
    "medclins" = "#criteria > table > tbody > tr:nth-child(2) > td > label",
    "genmed" = "#isGenMed",
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
  
  # We'll use this "append-to-empty-tibble" approach, for now
  df = tibble::tibble(
    no = character(),
    name = character(),
    add = character()
  )
  
  i = 1
  while (T) {
    results = remDr$findElement("#results", using = "css")
    
    html = results$getElementAttribute("innerHTML")[[1]] %>% 
      xml2::read_html()
    
    idx = html %>% 
      rvest::html_nodes(".col1") %>% 
      .[1] %>% 
      rvest::html_text() %>%
      gsub("\\s+", " ", .) %>% 
      gsub(",", "", .) %>% 
      sub(".*Showing (\\d+) - (\\d+) of .*", "\\1,\\2", .) %>% 
      strsplit(split = ",") %>% 
      unlist() %>% 
      as.numeric() %>% 
      { .[1]:.[2] }
    
    # This would ensure only unique indices get added to the table
    if (!any(idx %in% df$no)) {
      next_10 = html %>%
        rvest::html_nodes(".name,.add") %>%
        rvest::html_text() %>%
        gsub("\\s+", " ", .) %>%
        trimws() %>%
        { cbind(idx, .[c(TRUE,FALSE)], .[!c(TRUE,FALSE)]) } %>%
        tibble::as_tibble() %>% 
        setNames(c("no", "name", "add"))
      
      df = df %>% 
        dplyr::bind_rows(next_10)
      
      message(i, " of ", npages, " done (", round(i / npages * 100, 2), "%)")
      
      i = i + 1
    }
    
    if (i > npages) break
    
    # Navigate to the next page (if available, else stop)
    the_end = tryCatch({
      nextpage = remDr$findElement("#PageControl > div.r_arrow", using = "css")
      nextpage$clickElement()
      F
    }, error = function(e) {
      # Should not reach here under normal conditions
      print(paste("There are no more pages after", i))
      T
    })
    
    if (the_end) break
  }
  
  # Clean up RSelenium
  remDr$close()
  rD[["server"]]$stop()
  rm(rD, remDr)
  gc()
  # Kill Java instance(s) inside RStudio
  # docs.microsoft.com/en-us/windows-server/administration/windows-commands/taskkill
  system("taskkill /im java.exe /f", intern = F, ignore.stdout = F)
  
  df
}

hci <- import_hcidirectory()

# Save
hci %>%
  readr::write_csv("../results/scrape_hci_20200721.csv")

# Load
hci <- readr::read_csv("../results/scrape_hci_20200721.csv")

# Check
hci %>% 
  .[duplicated(.$add) | duplicated(.$add, fromLast = T),] %>% 
  dplyr::arrange(add)

# Clean duplicate addresses
hci_nodup <- hci %>% 
  .[!duplicated(.$add, fromLast = T),]

# Save
hci_nodup %>%
  readr::write_csv("../results/scrape_hci_nodup_20200721.csv")
