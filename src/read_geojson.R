# read_geojson.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# Read .geojson file(s)
lspdf <- rgdal::readOGR("../data/dengue-cases-central/dengue-cases-central-geojson.geojson")

lspdf@data <- lspdf@data %>% 
  dplyr::mutate(ncases = gsub(".*Dengue Cases : (\\d+).*", "\\1", Description),
                ncases = as.numeric(ncases))

pal <- leaflet::colorNumeric("Reds", lspdf@data$ncases)

leaflet::leaflet(lspdf) %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(stroke = T,
                       opacity = 1,
                       color = "black",
                       smoothFactor = 0.5,
                       fillOpacity = 0.75,
                       fillColor = ~pal(ncases),
                       weight = 1,
                       label = lspdf@data$ncases,
                       labelOptions = leaflet::labelOptions(
                         style = list("font-weight" = "normal", padding = "3px 8px"),
                         textsize = "15px",
                         direction = "auto"
                       ))



# pal <- colorNumeric("viridis", NULL)
# 
# leaflet(nycounties) %>%
#   addTiles() %>%
#   addPolygons(stroke = FALSE, smoothFactor = 0.3, fillOpacity = 1,
#               fillColor = ~pal(log10(pop)),
#               label = ~paste0(county, ": ", formatC(pop, big.mark = ","))) %>%
#   addLegend(pal = pal, values = ~log10(pop), opacity = 1.0,
#             labFormat = labelFormat(transform = function(x) round(10^x)))
