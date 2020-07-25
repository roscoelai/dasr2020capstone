# import_hcidirectory.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

import_hcidirectory <- function() {
  #' Healthcare Institutions Directory
  #' 
  #' @description
  #' The \href{http://hcidirectory.sg/hcidirectory/}{Healthcare Institutions 
  #' (HCI) Directory}, an initiative by the Ministry of Health (MOH), is a 
  #' platform for all HCIs licensed under the Private Hospitals and Medical 
  #' Clinics (PHMC) Act to provide information about their services and 
  #' operations to the public.
  #' 
  #' This function is custom-made to consolidate the names and addresses of 
  #' HCIs which are medical clinics that offer general medical services.
  #' 
  #' The HCI Directory is a dynamic web page, so using RSelenium might be 
  #' required.
  #' 
  #' @return The names and addresses of selected HCIs.
  
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
  
  # Create an empty tibble to append results
  df = tibble::tibble(
    id = character(),
    name = character(),
    add = character()
  )
  
  i = 1
  while (T) {
    results = remDr$findElement("#results", using = "css")
    html = results$getElementAttribute("innerHTML")[[1]] %>% 
      xml2::read_html()
    
    # Determine the index numbers of the (up to 10) results on the page
    idx = html %>% 
      # Find the element that says "SHOWING 1 - 10 OF 1,761 RESULTS"
      rvest::html_nodes(".col1") %>% 
      .[1] %>% 
      rvest::html_text() %>% 
      # Commas have to be eliminated for numbers > 999
      gsub(",", "", .) %>% 
      # Find the smallest and largest numbers and apply the colon operator
      sub(".*Showing\\s+(.*)\\s+of.*", "\\1", .) %>% 
      strsplit(split = " - ") %>% 
      unlist() %>% 
      as.numeric() %>% 
      { .[1]:.[2] }
    
    # Only append results if IDs are not in the table
    if (!any(idx %in% df$id)) {
      df = df %>% 
        dplyr::bind_rows(
          html %>%
            # Find both the name and address nodes
            rvest::html_nodes(".name,.add") %>% 
            rvest::html_text() %>% 
            # Tidy whitespace
            gsub("\\s+", " ", .) %>% 
            trimws() %>% 
            # Concatenate IDs, odd rows (names), and even rows (addresses)
            { cbind(idx, .[c(TRUE,FALSE)], .[!c(TRUE,FALSE)]) } %>% 
            tibble::as_tibble() %>% 
            setNames(c("id", "name", "add"))
        )
      
      # Announce progress and increment page counter
      message(i, " of ", npages, " done (", round(i / npages * 100, 2), "%)")
      i = i + 1
    }
    
    # Natural exit point
    if (i > npages) break
    
    # Navigate to the next page (if available, else stop)
    the_end = tryCatch({
      nextpage = remDr$findElement("#PageControl > div.r_arrow", using = "css")
      nextpage$clickElement()
      F
    }, error = function(e) {
      print(paste("There are no more pages after", i))
      T
    })
    
    # Unnatural exit point
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
  
  # Clean up:
  # - Franchises may have the same name with different addresses
  # - Different practices may have the same zipcodes and even buildings
  # - We will consider each full address unique, and a single practice
  
  # Clean up duplicate addresses
  df %>% 
    .[!duplicated(tolower(.$add), fromLast = T),]
}

# Import START ----

hcid_s <- import_hcidirectory()

hcid_s %>%
  readr::write_csv("../data/hci_scrape_raw_20200725.csv")

# Import END ----
