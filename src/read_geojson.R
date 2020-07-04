# read_geojson.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# Read .geojson file(s)
geojson_file <- "../data/dengue-cases-central/dengue-cases-central-geojson.geojson"

lspdf <- rgdal::readOGR(geojson_file)

leaflet::leaflet(lspdf) %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(stroke = FALSE,
                       smoothFactor = 0.3,
                       fillOpacity = 0.7,
                       fillColor = "deepskyblue4")



# pal <- colorNumeric("viridis", NULL)
# 
# leaflet(nycounties) %>%
#   addTiles() %>%
#   addPolygons(stroke = FALSE, smoothFactor = 0.3, fillOpacity = 1,
#               fillColor = ~pal(log10(pop)),
#               label = ~paste0(county, ": ", formatC(pop, big.mark = ","))) %>%
#   addLegend(pal = pal, values = ~log10(pop), opacity = 1.0,
#             labFormat = labelFormat(transform = function(x) round(10^x)))
