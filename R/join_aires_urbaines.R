library(tidyverse)
library(sf)
library(mapview)
library(ggmap)
library(ggplot2)
library(rnaturalearth)
library(units)
library(tmap)
library(tmaptools)
library(magrittr)

geocode_french_cities <- function(cities){
  geocode_OSM(paste0(cities, ', France')) %>%
    mutate(city = cities, country='France') %>%
    rename(bottom = lat_min, top = lat_max, left = lon_min, right = lon_max, lng=lon)
}

# ==== SHAPE READING / MANIPULATION ====

grid <- st_read('../data/boundaries/frapoly_core.geojson') %>% rowid_to_column('grid_id')

europe <- rnaturalearth::ne_countries(continent = 'Europe', type='map_units', scale='large') %>% st_as_sf %>%
  filter(name != 'Russia')

france_id <- 12
grid$non_france_intersects <- st_intersects(grid, europe) %>% lapply(function(x){x[x!=france_id]}) %>% lengths

grid <- grid %>% filter(non_france_intersects == 0)

tile_shapes <- st_read('../data/boundaries/fr-15-tiles-shapes.geojson') %>% filter( lengths(st_intersects(., grid)) > 0)

aires_urbaines <- st_read('../data/boundaries/fr_aires_urbaines/n_perimetre_aire_urbaine_s_fr.shp') %>% st_transform(4326)

# ==== FILL missing urban municipalities (Paris, Lyon, Marseille) ====

fill_municipalities <- st_read('../data/boundaries/fr_arrondissements_municipaux/arrondissements-municipaux-20160128.shp') %>%
  st_transform(4326) %>%
  mutate(city = word(nom, 1)) %>%
  group_by(city) %>%
  summarise() %>%
  st_buffer(0.01)

marseille_muni <- fill_municipalities %>% filter(city == 'Marseille') %>% st_geometry()
paris_muni <- fill_municipalities %>% filter(city == 'Paris') %>% st_geometry()
lyon_muni <- fill_municipalities %>% filter(city == 'Lyon') %>% st_geometry()

aires_urbaines[aires_urbaines$au == 'Paris',]$geometry <- st_union(paris_muni, aires_urbaines[aires_urbaines$au == 'Paris',]$geometry)
aires_urbaines[aires_urbaines$au == 'Lyon',]$geometry <- st_union(lyon_muni, aires_urbaines[aires_urbaines$au == 'Lyon',]$geometry)
aires_urbaines[word(aires_urbaines$au,1) == 'Marseille',]$geometry <- st_union(marseille_muni, aires_urbaines[word(aires_urbaines$au,1) == 'Marseille',]$geometry)

aires_urbaines <- aires_urbaines %>%
  mutate(au_ascii = iconv(au, from='UTF-8', to='ASCII//TRANSLIT')) %>%
  mutate(city = word(au, 1, sep='\\s[^\\w]'))

# ==== Join grid and tiles with aires urbaines =====

grid_joined <- grid %>% st_join(aires_urbaines, largest=T)
tiles_joined <- tile_shapes %>% st_join(aires_urbaines, largest=T) %>%
  filter(!is.na(au))

# very small number of tiles for these two due to cross-border regions being rejected - filter out
tiles_joined <- tiles_joined %>%
  filter(!grepl('Lille', au) & !grepl('Béthune', au))


tiles_joined <- tiles_joined %>%
  mutate(id = gsub('[()]', '', id)) %>%
  separate(id, c('col', 'row', 'zoom')) %>%
  mutate(name = paste(zoom, col, row, sep='_'))

# ===== URBAN CENTRES =====

city_centres <- grid_joined %>%
  mutate(city = recode(city, `Saint-Nazaire` = 'Saint-Nazaire, Loire-Atlantique')) %>%
  extract2('city') %>%
  geocode_french_cities %>%
  mutate(city = recode(city, `Saint-Nazaire, Loire-Atlantique` = 'Saint-Nazaire')) %>%
  st_as_sf(coords=c('lng', 'lat'),crs=4326)

city_centre_coords <- bind_cols(city_centres, data.frame(st_coordinates(city_centres))) %>%
  st_set_geometry(NULL) %>%
  unique() %>%
  select(city, lat = Y, lon = X)

tile_city_centres <- tiles_joined %>% st_set_geometry(NULL) %>%
  inner_join(city_centre_coords, by='city') %>%
  st_as_sf(coords=c('lon', 'lat'), crs=4326)

tiles_joined$dist <- st_distance(st_centroid(tiles_joined),tile_city_centres, by_element = T)
tiles_joined$dist <- drop_units(tiles_joined$dist)

city_metrics <-
  tiles_joined %>%
  st_set_geometry(NULL) %>%
  group_by(au) %>%
  summarise(max_dist=max(dist), size = n())

city_radii <- city_centres %>%
  inner_join(city_metrics, by='city') %>%
  st_transform(2154) %>%
  st_buffer(dist = .$max_dist) %>%
  st_transform(4326)

city_metrics %>%
  arrange(-size) %>%
  rowid_to_column('rn') %>%
  mutate(max_dist = max_dist / 1000) %>%
  filter(rn < 11 | rn > 56) %>%
  rename(`No.`=rn, Area=au, Radius=max_dist, Size=size) %>%
  write.csv('../data/analysis/urbansizes.csv', fileEncoding = 'UTF-8')

tiles_joined <- tiles_joined %>%
  inner_join(city_metrics, by='city')

# ==== SAVE MATCHED TILES ====

tiles_joined %>%
  select(name, zoom, col, row, au, city, distance_from_center = dist, city_max_dist = max_dist, city_size = size) %>%
  st_set_geometry(NULL) %>%
  write_csv('../data/analysis/matched-ghs-fr-core.csv')

tiles_joined %>%
  st_write('../data/analysis/tiles.geojson', delete_dsn=TRUE)

city_centres %>%
  inner_join(city_metrics, by='city') %>%
  st_write('../data/analysis/cities.geojson', delete_dsn=TRUE)

grid_joined %>%
  st_write('../data/analysis/ghs-grid.geojson', delete_dsn=TRUE)