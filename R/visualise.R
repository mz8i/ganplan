library(tidyverse)
library(plotly)
library(dplyr)
library(gghighlight)

library(sf)
library(mapview)
library(ggmap)
library(ggsn)
library(tmap)
library(tmaptools)
library(magrittr)


datasets <- c('roads', 'buildings', 'rbw')
ordered_data <- factor(datasets, levels = datasets)

tiles <- read_csv('../data/analysis/matched-ghs-fr-core.csv')

tsne <- read_csv('../data/analysis/roads/tsne30.csv')

get_base_dataset <- function(dataset) {
  tiles %>%
    inner_join(read_csv(paste0('../data/analysis/',dataset,'/tsne30.csv')))
}

roads <- get_base_dataset('roads')
buildings <- get_base_dataset('buildings')
rbw <- get_base_dataset('rbw')

clusters <- read_csv('../data/analysis/roads/hdbscan3.csv') %>%
  mutate(cluster = as.character(cluster))

get_clustered <- function(base_data, clustering, param, dataset=deparse(substitute(base_data))){
  cl <- read_csv(paste0('../data/analysis/',dataset,'/',clustering,param,'.csv')) %>%
    mutate(cluster = as.factor(cluster))
  base_data %>%
    inner_join(cl)
}


figure <- function(g, filename, height=4, width=5.7, mult=1.5, type='svg'){
  dev <- if(type=='svg') svg else png
  width <- if(type=='svg') width else width * 96
  height <- if(type=='svg') height else height * 96
  dev(paste0('../data/analysis/visualisation/', filename, '.',type), width*mult, height*mult, pointsize = 30)
  print(g)
  dev.off()
}

th <- theme(axis.line=element_blank(),axis.text.x=element_blank(),
            axis.text.y=element_blank(),axis.ticks=element_blank(),
            axis.title.x=element_blank(),
            axis.title.y=element_blank(),legend.position="none",
            panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
            panel.grid.minor=element_blank(),plot.background=element_blank())

title_center <- theme(plot.title = element_text(hjust = 0.5))


# ============ produce plots ==============


models <- c(roads='R2', buildings='B2', rbw='RBW2')

pca_explained <- datasets %>%
  lapply(function(x)
    read_csv(paste0('../data/analysis/',x,'/pca_explained.csv')) %>%
      rename(component = X1) %>%
      mutate(model = factor(models[x], levels=models), component = component + 1)
  ) %>% do.call(what=bind_rows)

figure(
pca_explained %>%
  group_by(model) %>%
  filter(row_number() <= 10) %>%
  ungroup() %>%
  ggplot(aes(component, explained_variance_ratio, fill=model, group=model)) +
    geom_bar(stat='identity', position='dodge') +
    scale_x_continuous(breaks=1:10) +
    ylab('Explained variance ratio') + xlab('Principal component') +
    ggtitle('Explained variance ratio for first ten principal components') +
    title_center
, 'pca_explained', height = 3)

figure(
pca_explained %>%
  group_by(model) %>%
  mutate(cumulative_explained_variance_ratio = cumsum(explained_variance_ratio)) %>%
  ungroup() %>%
  ggplot(aes(component, cumulative_explained_variance_ratio, color=model, group=model)) +
    geom_line() + 
    scale_x_continuous(breaks = c(seq(0,100,25),10))+
    geom_vline(xintercept = 10, linetype='dashed') +
    ylab('Cumulative explained variance ratio') + xlab('Principal component') +
    ggtitle('Cumulative explained variance ratio for all principal components') +
    title_center
, 'pca_cumulative', height = 3)

figure(
get_clustered(roads, 'hdbscan', 3) %>%
  ggplot() +
    geom_point(alpha=0.5, aes(tsne_x, tsne_y, color=cluster)) +
    theme_minimal() +
    gghighlight(cluster!='-1',use_direct_label=F) + th
, 'hdb_roads_3')


figure(
get_clustered(rbw, 'hdbscan', 3) %>%
  # filter(cluster!= '-1') %>%
  ggplot() +
  geom_point(alpha=0.5, aes(tsne_x, tsne_y, color=cluster)) +
  theme_minimal() +
  gghighlight(cluster!='-1',use_direct_label=F) + th
, 'hdb_rbw_3')

figure(
  get_clustered(rbw, 'hdbscan', 10) %>%
    # filter(cluster!= '-1') %>%
    ggplot() +
    geom_point(alpha=0.5, aes(tsne_x, tsne_y, color=cluster)) +
    theme_minimal() +
    gghighlight(cluster!='-1',use_direct_label=F) + th
  , 'hdb_rbw_10')

read_csv('../data/analysis/roads/kmeans_elbow.csv') %>%
  mutate(k = as.integer(k)) %>%
  ggplot(aes(k, score)) + geom_line() + theme_minimal() + scale_x_continuous(breaks = scales::pretty_breaks(n=10))


figure(
datasets %>%
  lapply(function(x) {
      kmeans_data <- read_csv(paste0('../data/analysis/kmeans/kmeans_', x, '_silhouette.csv')) %>%
        mutate(algorithm='kmeans')
      ward_data <- read_csv(paste0('../data/analysis/ward/ward_', x, '_analysis.csv')) %>%
        mutate(algorithm='ward') %>% select(-calinski_harabaz_score)
      bind_rows(kmeans_data, ward_data) %>%
        mutate(model = factor(models[x], levels=models))
  }) %>%
  do.call(what=bind_rows) %>%
  ggplot() +
    geom_line(aes(k, silhouette_score, color=algorithm,group=algorithm)) +
    scale_x_continuous(breaks=2:20) +
    facet_wrap(~model,nrow = 3) +
    ylab('Mean silhouette score') +
    xlab('k (number of clusters)') +
    ggtitle('Mean silhouette score per k for Ward and k-means latent space clustering') +
    title_center
, 'silhouette_score', height=5)


# visualise tsne

models <- c(roads='R2', buildings = 'B2', rbw = 'RBW2')
figure(
datasets %>%
  lapply(function(x){
    c(5, 30, 100) %>% lapply(function(y){
      read_csv(paste0('../data/analysis/',x,'/tsne',y,'.csv')) %>% mutate(model = models[x], k=y)
    }) %>% do.call(what=bind_rows)
      
  }) %>% do.call(what=bind_rows) %>%
  ggplot() + geom_point(aes(tsne_x, tsne_y),alpha=0.2) + facet_wrap(~model+k) +
  ggtitle('t-SNE plots of latent spaces for varying perplexity') +
  title_center
, 'tsne_full',height=5, type='png', mult=1.2)


# ==== produce maps ====

get_coords <- function(df){
  df %>%
    mutate(
      CENTROID = map(geometry, st_centroid),
      COORDS = map(CENTROID, st_coordinates),
      COORDS_X = map_dbl(COORDS, 1),
      COORDS_Y = map_dbl(COORDS, 2)
    )
}

tiles_joined <- st_read('../data/analysis/tiles.geojson')
grid_joined <- st_read('../data/analysis/ghs-grid.geojson')
city_centres <- st_read('../data/analysis/cities.geojson')


# == France overview map ==


france <- rnaturalearth::ne_countries(geounit='France', type='map_units', scale='large') %>%
  spTransform("+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs") %>% st_as_sf

figure(
  st_read('../data/boundaries/frapoly_core.geojson') %>% ggplot() +
    geom_sf(inherit.aes=F, fill='red') +
    geom_sf(data=france, alpha=0,inherit.aes=F) + ggtitle('GHS settlement model urban centres for France') + title_center
  , 'ghsfrance',height=4)


# == Chartres overview map

chartres_tiles <- tiles_joined %>% filter(au=='Chartres')
chartres_ghs <- grid_joined %>% filter(au=='Chartres')
chartres_center <- st_centroid(chartres_ghs)
chartres_basemap <- get_map(st_coordinates(chartres_center), maptype='toner-lite', source='stamen', zoom = 12)

figure(
  ggmap(basemap) + 
    geom_sf(aes(fill='red',group=1), data=chartres_ghs, inherit.aes = F, fill='#ff000070', colour=NA, show.legend = 'polygon') +
    geom_sf(aes(group=2), data=chartres_tiles, inherit.aes = F, fill=NA, colour='black', show.legend = 'line') +
    theme_minimal() + ggtitle('An overview of Chartres with the GHS grid (red) and OSM tiles (black) ') + title_center
,'chartres',height=5)

# == clustering map visualisation

map_clustering <- function(clustering, param, dataset, .au, basemap, display_labels=T){
  dat <- get_clustered(tiles_joined, clustering, param, dataset) %>%
    filter(au == .au) %>%
    get_coords
  
  clusters <- length(unique(dat$cluster))
  g <- ggmap(basemap) +
    geom_sf(aes(fill=cluster), dat, alpha=0.7, inherit.aes=F)
    # scale_fill_manual(values=as.character(0:param-1), palette=) +
  if(display_labels){
    g <- g + geom_text(aes(COORDS_X, COORDS_Y, label=cluster), alpha=0.7, data=dat)
  }
  g
}

get_basemap <- function(.au, zoom){
  ghs <- grid_joined %>% filter(au == .au)
  center <- st_centroid(st_union(ghs))
  print(center)
  
  basemap <- get_map(st_coordinates(center), maptype='toner-lite', source='stamen', zoom = zoom)
  basemap
}


map_clustering('kmeans', 5, 'rbw', 'Chartres', chartres_basemap)

paris_basemap <- get_basemap('Paris', 10)

figure(
  map_clustering('kmeans', 2, 'rbw', 'Paris', paris_basemap, F)
, 'paris_rbw_kmeans2', height=4, mult=1.5)

figure(
  map_clustering('kmeans', 2, 'buildings', 'Paris', paris_basemap, F)
, 'paris_buildings_kmeans2', height=4, mult=1.5)
