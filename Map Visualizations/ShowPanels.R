setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(leaflet)
library(leafsync)
library(htmltools)
library(dplyr)
library(RColorBrewer)
library(sf)
library(leaflet.extras)

base_folder <- "/home/jaumeasensio/Documents/Projectes/BEEGroup/solar_potencial_estimation_v3/Results/"
neighborhoods <- c("Test_70_el Besòs i el Maresme")
neighborhoods <- c("70_el Besòs i el Maresme")

cadaster_sf_list <- list()
planes_sf_list <- list()

searchPath <- "/Solar Estimation Panels Simulated/"
for (neighborhood in neighborhoods){
  parcels <- list.files(path = paste(base_folder, neighborhood, "/Parcels/", sep=""))
  for (parcel in parcels){
    constructions <- list.dirs(path = paste(base_folder, neighborhood, "/Parcels/", parcel, sep=""), recursive = FALSE, full.names = FALSE)
    gpkg_files <- paste0(base_folder, neighborhood, "/Parcels/", parcel, "/", constructions, "/Map files/", constructions, ".gpkg")
    
    partial_cadaster_sf_list <- lapply(gpkg_files, function(file) {
      re_sf <- read_sf(file)
      re_sf <- st_zm(re_sf)
      re_sf <- st_transform(re_sf, 4326)
      re_sf$parcel <- parcel
      re_sf$construction <- gsub(".gpkg", "", basename(file))
      return(re_sf)
    })
    cadaster_sf_list <- c(cadaster_sf_list, partial_cadaster_sf_list)
    
    for (construction in constructions){
      planes <- list.files(path = paste0(base_folder, neighborhood, "/Parcels/", parcel, "/", construction, searchPath), recursive = FALSE, full.names = FALSE)
      planes <- planes[!file.info(file.path(paste0(base_folder, neighborhood, "/Parcels/", parcel, "/", construction, searchPath), planes))$isdir]
      planes <- planes[grepl("\\.gpkg$", planes)]
      if(length(planes) > 0){
        gpkg_files <- paste0(base_folder, neighborhood, "/Parcels/", parcel, "/", construction, searchPath, planes)
        partial_planes_sf_list <- lapply(gpkg_files, function(file) {
          re_sf <- read_sf(file)
          re_sf <- st_zm(re_sf)
          re_sf <- st_transform(re_sf, 4326)
          re_sf$parcel <- parcel
          re_sf$construction <- construction
          re_sf$plane  <- gsub(".gpkg", "", basename(file))
          return(re_sf)
        })
        planes_sf_list <- c(planes_sf_list, partial_planes_sf_list)
      }
    }
  }
}
cadaster_merged_sf <- do.call(rbind, cadaster_sf_list)
planes_merged_sf <- do.call(rbind, planes_sf_list)

palette <- colorNumeric(palette = "inferno", domain = planes_merged_sf$yearly)

map2 <- leaflet(planes_merged_sf, options = leafletOptions(maxZoom = 25)) %>%
  addProviderTiles(providers$OpenStreetMap.Mapnik, options = providerTileOptions(opacity=1, maxZoom=20)) %>%

  
  addPolygons(
    # fillColor = "blue",
    fillColor = ~ palette(yearly),
    opacity = 1,
    stroke = TRUE,
    color = "white",
    fillOpacity = 1,           # Adjust the fill opacity for better visibility
    weight = 0,                 # Set outline thickness
    label = ~paste(parcel, construction, sep=". "),
  ) %>%
  
  addPolygons(data = cadaster_merged_sf,
              weight = 4,
              color =  "black",
              fillColor = "white",
              fillOpacity = 0,
              opacity = 1,
              label = ~paste(REFCAT, construction, CONSTRU, sep=". ")
  )%>%
  
  addLegend(
    pal = palette,
    values = ~yearly,
    title = "Solar energy production<br>(kWh/panel/year)",
    position = "bottomright",
    opacity=1,
  )%>%
  
  addScaleBar()

map2
# library(leaflet)
# library(leafsync)
# library(htmltools)
# library(htmlwidgets)
# saveWidget(map2, file="panels.html")
# 