import pandas as pd
from ggplot import *
from analysis_util import *
from sklearn.decomposition import PCA
from sklearn.preprocessing import scale
from sklearn.cluster import KMeans, AgglomerativeClustering
from sklearn.metrics import adjusted_rand_score, silhouette_score, calinski_harabaz_score


data = pd.read_pickle('../data/analysis/result_all.pkl')

# ==== tSNE =====

for i in (5, 30, 100):
    for dataset in ('roads', 'buildings', 'rbw'):
        d = data['tsne'+str(i)+'_'+dataset].apply(pd.Series)
        d.columns = ['tsne_x', 'tsne_y']
        d.to_csv('../data/analysis/'+dataset+'/tsne'+str(i)+'.csv')

# ==== PCA ====

def analyse_pca(series):
    scaled = scale(np.vstack(series))
    pca = PCA(n_components=100).fit(scaled)
    explained_ratios = pd.DataFrame({'explained_variance_ratio': pca.explained_variance_ratio_})
    return explained_ratios
    
analyse_pca(data.e_roads).to_csv('../data/analysis/roads/pca_explained.csv')
analyse_pca(data.e_buildings).to_csv('../data/analysis/buildings/pca_explained.csv')
analyse_pca(data.e_rbw).to_csv('../data/analysis/rbw/pca_explained.csv')


# ==== KMEANS ====

def analyse_kmeans(series):
    pca = np.vstack(series)
    Ks = range(2, 21)
    km = [KMeans(n_clusters=i) for i in Ks]
    fitted = [km[i].fit(pca) for i in range(len(km))] 
    score = [fitted[i].score(pca) for i in range(len(km))]
    explained = pd.DataFrame({'k': Ks, 'score': score})
    explained.plot(0,1)
    silh = [silhouette_score(pca, fitted[i].predict(pca)) for i in range(len(km))]
    silhouette = pd.DataFrame({'k': Ks, 'silhouette_score': silh})
    silhouette.plot(0,1)
    return silhouette, explained

sil_roads, elbow_roads = analyse_kmeans(data.pca_roads)
elbow_roads.to_csv('../data/analysis/roads/kmeans_elbow.csv')
sil_roads.to_csv('../data/analysis/roads/kmeans_silhouette.csv')

sil_buildings,elbow_buildings = analyse_kmeans(data.pca_buildings)
elbow_buildings.to_csv('../data/analysis/buildings/kmeans_elbow.csv')
sil_buildings.to_csv('../data/analysis/buildings/kmeans_silhouette.csv')

sil_rbw, elbow_rbw = analyse_kmeans(data.pca_rbw)
elbow_rbw.to_csv('../data/analysis/rbw/kmeans_elbow.csv')
sil_rbw.to_csv('../data/analysis/rbw/kmeans_silhouette.csv')


for dataset in ('roads', 'buildings', 'rbw'):
    print('dataset: ',dataset)
    Ks = []
    silhouette_list = []
    calinski_harabaz_list = []
    for k in range(2,21):
        kmeans = get_kmeans(data, 'pca_'+dataset, k)
        kmeans_df = pd.DataFrame({'cluster': kmeans}, index=data.index)
        kmeans_df.to_csv('../data/analysis/'+dataset+'/kmeans'+str(k)+'.csv')
        print('K: ', k)
        print('clusters:', len(kmeans_df.cluster.unique()))
        print('cluster sizes:')
        print(kmeans_df.cluster.value_counts())
        print()

# =========== WARD ===========

for dataset in ('roads', 'buildings', 'rbw'):
    print('dataset: ',dataset)
    Ks = []
    ward_silhouette = []
    ward_calinski_harabaz = []
    for k in range(2,21):
        col_name = 'e_'+dataset
        ward = get_ward(data, col_name, k)
        ward_df = pd.DataFrame({'cluster': ward}, index=data.index)
        ward_df.to_csv('../data/analysis/'+dataset+'/e_ward'+str(k)+'.csv')
        X = np.vstack(data[col_name])
        silhouette = silhouette_score(X, ward_df.cluster)
        cal_har = calinski_harabaz_score(X, ward_df.cluster)
        Ks.append(k)
        ward_silhouette.append(silhouette)
        ward_calinski_harabaz.append(cal_har)
        print('K: ', k)
        print('cluster sizes:')
        print(ward_df.cluster.value_counts())
        print('silhouette score:',silhouette)
        print('calinski-harabasz score:', cal_har)
        print()
    pd.DataFrame({'k': Ks, 'silhouette_score': ward_silhouette, 'calinski_harabaz_score': ward_calinski_harabaz}).to_csv('../data/analysis/e_ward_'+dataset+'_analysis.csv')

# ============== Adjusted Rand Index


def get_ari(comparison_df, models):
    ari = pd.DataFrame(columns=models, index=models)
    for i,model_a in enumerate(models):
        for j, model_b in enumerate(models):
            ari.at[model_a, model_b] = adjusted_rand_score(comparison_df['cluster_'+model_a].values, comparison_df['cluster_'+model_b])
    return ari
    
models = ('roads', 'buildings', 'rbw')

kmeans2_comp = pd.read_csv('../data/analysis/kmeans/kmeans2_comparison.csv')
km2ari = get_ari(kmeans2_comp, models)
km2ari.to_csv('../data/analysis/kmeans/ari2.csv')

kmeans10_comp = pd.read_csv('../data/analysis/kmeans/kmeans10_comparison.csv')
km10ari = get_ari(kmeans10_comp, models)
km10ari.to_csv('../data/analysis/kmeans/ari10.csv')

kmeans20_comp = pd.read_csv('../data/analysis/kmeans/kmeans20_comparison.csv')
km20ari = get_ari(kmeans2_comp, models)
km20ari.to_csv('../data/analysis/kmeans/ari20.csv')

roads_kmeans2 = pd.read_csv('../data/analysis/roads/kmeans2.csv')
buildings_kmeans2 = pd.read_csv('../data/analysis/buildings/kmeans2.csv')
rbw_kmeans2 = pd.read_csv('../data/analysis/rbw/kmeans2.csv')

# ==== HDBSCAN ====

def analyse_hdb(series, min_size=10,min_samples=10, allow_single=False):
    data = np.vstack(series)
    clusterer = HDBSCAN(min_cluster_size=min_size, min_samples=min_samples, allow_single_cluster=allow_single).fit(data)
    return clusterer
    

agg_results = pd.DataFrame(columns=['dataset', 'min_cluster_size', 'number_clusters', 'max_cluster', 'median_cluster'])

for dataset in ('roads', 'buildings', 'rbw'):
    for min_cluster_size in (3, 5, 10):
        
        clusterer = analyse_hdb(data['e_'+dataset], min_cluster_size, 1)
        hdbscan_df = pd.DataFrame({'cluster': clusterer.labels_}, index=data.index)
        hdbscan_df.to_csv('../data/analysis/'+dataset+'/hdbscan'+str(min_cluster_size)+'.csv')
        print('dataset:', dataset)
        print('min_cluster_size:', min_cluster_size)
        hdbscan_df = hdbscan_df[hdbscan_df.cluster != -1]
        n_clusters = len(hdbscan_df.cluster.unique())
        print('clusters:', n_clusters)
        print('cluster sizes:')
        cluster_size = hdbscan_df.cluster.value_counts()
        print(cluster_size)
        agg_results=agg_results.append({'dataset': dataset, 'min_cluster_size': min_cluster_size, 'number_clusters': n_clusters, 'max_cluster': cluster_size.max(), 'median_cluster': cluster_size.median()}, ignore_index=True)
        print()

agg_results.to_csv('../data/analysis/hdbscan_runs.csv')