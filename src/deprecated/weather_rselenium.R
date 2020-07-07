
# We go through all this trouble to get DAILY data (and to do webscraping)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(RSelenium)

rD <- rsDriver(browser = "chrome", chromever = "83.0.4103.39", check = F)
remDr <- rD$client
remDr$setTimeout(type = "implicit", milliseconds = 10000)

remDr$navigate("http://www.weather.gov.sg/climate-historical-daily/")

xpaths = list(
  "location" = '//*[@id="cityname"]',
  "month" = '//*[@id="month"]',
  "year" = '//*[@id="year"]',
  "display" = '//*[@id="display"]',
  "table" = '//*[@id="temp"]/h4[2]/div/div/table'
)
months <- paste(xpaths[["month"]], "/ul/li[", 1:12 , "]/a", sep = "")
months[12]

webElems <- lapply(xpaths, remDr$findElement, using = "xpath")



select_monthyear <- function(month, year) {
  webElems[["month"]]$clickElement()
  xp = paste(xpaths[["month"]], "/ul/li[", month , "]/a", sep = "")
  remDr$findElement(using = "xpath", value = xp)$clickElement()
  
  webElems[["year"]]$clickElement()
  
  webElems[["display"]]$clickElement()
  
  Sys.sleep(1.0)
  
  
}

month <- 11


## Clean up
remDr$close()
rD$server$stop()
rm(rD)
gc(rD)


# webElems1 <- vector("list", length(xpaths))
# names(webElems1) <- names(xpaths)
# for (name in names(xpaths)) {
#   webElems1[[name]] <- remDr$findElement(using = "xpath", value = xpaths[[name]])
# }

# option <- remDr$findElement(using = "xpath", value = '//*[@id="cityname"]')
# option$clickElement()
# option <- remDr$findElement(using = "xpath", "/html/body/div/div/div[3]/div[1]/div[1]/div/div/ul/li[11]/a")
# option$clickElement()
# option <- remDr$findElement(using = "xpath", '//*[@id="yearDiv"]/ul/li[2]/a')
# option$clickElement()

## Reference
# https://www.selenium.dev/selenium/docs/api/rb/Selenium/WebDriver/Keys.html
