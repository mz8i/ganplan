library(raster)
library(sf)
library(mapview)
library(rnaturalearth)
library(dplyr)
library(geojsonio)
library(magrittr)

france <- rnaturalearth::ne_countries(geounit='France', type='map_units', scale='large') %>%
  spTransform("+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs") %>% st_as_sf

norway <- rnaturalearth::ne_countries(geounit='Norway', type='map_units', scale='large') %>%
  spTransform("+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs")

europe <- rnaturalearth::ne_countries(continent = 'Europe', type='map_units', scale='large') %>% st_as_sf %>%
  filter(name != 'Russia') %>% as('Spatial') %>% spTransform("+proj=moll +ellps=WGS84")

eustmt <- raster('../data/boundaries/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif', RAT=T) %>%
  crop(europe)

eustmt[eustmt < 3] <- NA
eustmt[eustmt >=2] <- T

eupoly <- rasterToPolygons(eustmt, dissolve=T) %>% st_as_sf

mapview(eupoly)

africa <- rnaturalearth::ne_countries(continent = 'Africa', type='map_units', scale='large') %>% st_as_sf %>%
  filter(name != 'Russia') %>% as('Spatial') %>% spTransform("+proj=moll +ellps=WGS84") %>% st_as_sf %>% st_union %>% st_buffer(10000)

final_eur_borders <- st_difference(st_as_sf(europe), africa) %>% st_union

final_eupoly <- st_intersection(final_eur_borders, eupoly)

geojson_write(final_eupoly, file='eupoly_core.geojson')

eupoly <- st_read('../data/boundaries/eupoly.geojson') %>% st_cast('POLYGON') %>% st_set_crs("+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs") %>%
  st_transform(4326)

geojson_write(eupoly, file='eupoly.geojson')

final_eupoly %>% st_intersection(st_as_sf(france) %>% st_buffer(5000)) %>% geojson_write(file='frapoly_core.geojson')
