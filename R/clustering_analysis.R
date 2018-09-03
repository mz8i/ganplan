library(tidyverse)

# ========= compare ward and kmeans

mutate(read_csv('../data/analysis/ward/ward_roads_analysis.csv'), algo='ward') %>%
bind_rows(
  mutate(read_csv('../data/analysis/kmeans/kmeans_roads_silhouette.csv'),algo='kmeans')
) %>%
  ggplot() + geom_line(aes(x=k, y=silhouette_score, color=algo, group=algo))

# ========== compare algorithms by type


get_clustering_comparison <- function(k, algo) {
  read_csv('../data/analysis/matched-ghs-fr-core.csv') %>%
    inner_join(read_csv(paste0('../data/analysis/roads/',algo,k,'.csv')), by='name') %>%
    mutate(cluster = as.factor(cluster)) %>% rename(cluster_roads = cluster) %>%
    inner_join(read_csv(paste0('../data/analysis/buildings/',algo,k,'.csv')), by='name') %>%
    mutate(cluster = as.factor(cluster)) %>% rename(cluster_buildings = cluster) %>%
    inner_join(read_csv(paste0('../data/analysis/rbw/',algo,k,'.csv')), by='name') %>%
    mutate(cluster = as.factor(cluster)) %>% rename(cluster_rbw = cluster)
}

get_kmeans_comparison <- function(k){
  get_clustering_comparison(k, 'kmeans')
}
get_ward_comparison <- function(k){
  get_clustering_comparison(k, 'ward')
}

km2comp <- get_kmeans_comparison(2)
write_csv(km2comp, '../data/analysis/kmeans/kmeans2_comparison.csv')

# boxplots 

normdist_plot <- function(k){
  get_kmeans_comparison(k) %>%
    mutate(normdist = distance_from_center / city_max_dist) %>%
    rename(R2 = cluster_roads, B2 = cluster_buildings, RBW2 = cluster_rbw) %>%
    gather('algo', 'cluster', R2:RBW2) %>%
    ggplot(aes(x=cluster, y=normdist, color=cluster)) + geom_violin() + facet_wrap(~algo) +
    stat_summary(fun.y="median", geom="point") +
    ylab('Normalised distance to centre') +
    ggtitle('') + 
    theme(plot.title = element_text(hjust = 0.5))
}

figure(
  normdist_plot(4)
,'radial4plot', height=3)

normdist_plot(3)
normdist_plot(5)
normdist_plot(10)
  

# KDE plots

km2comp <- get_kmeans_comparison(2)
write_csv(km10comp, '../data/analysis/kmeans/kmeans9_comparison.csv')

figure(
km2comp %>%
  mutate(`Normalised distance to centre` = distance_from_center / city_max_dist) %>%
  rename(R2 = cluster_roads, B2 = cluster_buildings, RBW2 = cluster_rbw) %>%
  gather('Model', 'Cluster',R2:RBW2) %>%
  mutate(Model = factor(Model, levels = c('R2', 'B2', 'RBW2'))) %>%
  # filter(city == 'Paris') %>%
  ggplot() + geom_density(aes(`Normalised distance to centre`, fill=Cluster, group=Cluster), alpha=0.5) +
  facet_wrap(~Model) +
  ggtitle('Cluster distribution density in relation to city centres') + title_center
, 'k2density', height=3)


km20comp <- get_kmeans_comparison(20)
write_csv(km20comp, '../data/analysis/kmeans/kmeans20_comparison.csv')


w2comp <- get_ward_comparison(2)
write_csv(w2comp, '../data/analysis/ward/ward2_comparison.csv')

w2comp %>%
  mutate(normdist = distance_from_center / city_max_dist) %>%
  gather('Model', 'Cluster',cluster_buildings:cluster_roads) %>%
  # filter(city == 'Paris') %>%
  ggplot() + geom_density(aes(normdist, fill=Cluster, group=Cluster), alpha=0.5) + facet_wrap(~Model)
