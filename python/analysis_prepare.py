from analysis_util import *


def preprocess(data, name):
    e_name = 'e_' + name
    data[e_name] = get_embeddings(data, '../data/embeds/france_15_'+name+'_128_full')

    for perplexity in [5, 30, 100]:
        tsne_name = 'tsne' + str(perplexity) + '_' + name
        data[tsne_name] = get_tsne(data, e_name, perplexity)
    

if __name__ == '__main__':

    data_csv = '../data/analysis/matched-ghs-fr-core.csv'
    data = get_df_from_csv(data_csv)
    
    for name in ['roads', 'buildings', 'rbw']:
        preprocess(data, name)

    data['e_roads'] = get_embeddings(data, '../data/embeds/france_15_roads_128_full')
    data['e_buildings'] = get_embeddings(data, '../data/embeds/france_15_buildings_128_full')
    data['e_rbw'] = get_embeddings(data, '../data/embeds/france_15_rbw_128_full')

    tsne_perplexity = 30
    data['tsne_roads'] = get_tsne(data, 'e_roads', tsne_perplexity)
    data['tsne_buildings'] = get_tsne(data, 'e_buildings', tsne_perplexity)
    data['tsne_rbw'] = get_tsne(data, 'e_rbw', tsne_perplexity)
    
    write_df(data, '../data/analysis/embed_tsne_all.pkl')

    n_principal_components = 10
    data['pca_roads'] = get_pca(data, 'e_roads', n_principal_components)
    data['pca_buildings'] = get_pca(data, 'e_buildings', n_principal_components)
    data['pca_rbw'] = get_pca(data, 'e_rbw', n_principal_components)

    data['kmeans3_roads'] = get_kmeans(data, 'pca_roads', 3)
    data['kmeans3_buildings'] = get_kmeans(data, 'pca_buildings', 3)
    data['kmeans3_rbw'] = get_kmeans(data, 'pca_rbw', 3)
    
    print(data)

    write_df(data, '../data/analysis/result_all.pkl')