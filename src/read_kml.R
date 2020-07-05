# read_kml.R

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(magrittr)

# Read .kml file(s)
df <- sf::st_read("../data/dengue-cases-central/dengue-cases-central-kml.kml")

class(df)

df <- df %>% 
  dplyr::mutate(ncases = gsub(".*Dengue Cases : (\\d+).*", "\\1", Description),
                ncases = as.numeric(ncases))

dplyr::glimpse(df)

plot(df)

leaflet::leaflet(df) %>%
  leaflet::addTiles() %>%
  leaflet::addPolygons(stroke = T,
                       opacity = 1,
                       smoothFactor = 0.5,
                       fillOpacity = 0.75,
                       fillColor = ~pal(Name),
                       weight = 1)


# write.csv(map, "../results/kml1.csv")

kml_files <- c(
  "./input/dengue-cases/dengue-cases-central-kml.kml",
  "./input/dengue-cases/dengue-cases-north-east-kml.kml",
  "./input/dengue-cases/dengue-cases-north-west-kml.kml",
  "./input/dengue-cases/dengue-cases-south-east-kml.kml",
  "./input/dengue-cases/dengue-cases-south-west-kml.kml"
)

maps <- lapply(kml_files, st_read)
plot(maps[[1]])
plot(maps[[2]])
plot(maps[[3]])
plot(maps[[4]])
plot(maps[[5]])
