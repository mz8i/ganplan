library(sf)
library(tmap)
library(manipulate)
library(maps)
library(rnaturalearth)
library(dplyr)
library(igraph)
library(magrittr)
library(purrr)
library(geojsonio)

tmap_mode('view')

dat <- st_read('../DGURBA_2014_SH/data/DGURBA_RG_01M_2014.shp') %>% st_transform(4326)

degtorad <- function(deg){
  deg/180*pi
}
size_for_zoom_lat <- function(zoom, lat){
  40075016.686 * cos(lat) / 2^zoom
}

manipulate(size_for_zoom_lat(z, degtorad(l)) %T>% print %>% plot,
           z = manipulate::slider(0, 20, initial=10, label='zoom'),
           l = manipulate::slider(-90, 90, initial=0))

dat %>% st_intersection(filter(st_as_sf(ne_countries()), name == 'Belgium')) %>% qtm

cities <- dat %>% filter(DGURBA_CLA == 1)

cs <- st_intersects(cities, cities) %>% as.matrix %>% graph_from_adjacency_matrix() %>% components %>% extract2('membership')

merged_cities <- cities %>% mutate(comp = cs) %>% group_by(comp) %>% summarise

merged_cities_bb <- merged_cities %>% st_geometry() %>% map(st_bbox) %>% map(st_as_sfc) %>% do.call(c, .) %>% st_set_geometry(merged_cities, .)



cities %>% geojson_json %>% geojson_write(file='cities.geojson')
