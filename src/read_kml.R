# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# Import ----
regions <- c(
  "central" = "../data/dengue-cases-central/dengue-cases-central-kml.kml",
  "northeast" = "../data/dengue-cases-north-east/dengue-cases-north-east-kml.kml",
  "southeast" = "../data/dengue-cases-south-east/dengue-cases-south-east-kml.kml",
  "southwest" = "../data/dengue-cases-south-west/dengue-cases-south-west-kml.kml"
)

spdf <- regions %>% 
  lapply(rgdal::readOGR) %>% 
  do.call("rbind", .)

# Transform ----
spdf@data$ncases <- 
  as.numeric(gsub(".*Cases : (\\d+).*", "\\1", spdf@data$Description))

# Visualize ----

# pal <- leaflet::colorFactor(RColorBrewer::brewer.pal(length(spdf), "Set3"), NULL)

pal <- leaflet::colorNumeric("Reds", spdf@data$ncases)

spdf %>% 
  leaflet::leaflet() %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(stroke = T,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.75,
                       fillColor = ~pal(ncases),
                       weight = 0.5,
                       label = ~as.character(ncases),
                       popup = ~as.character(ncases))
