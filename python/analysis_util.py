import numpy as np
import os
import pandas as pd
import time
import re
import argparse

from imageio import imread, imwrite
from PIL import Image
from sklearn.neighbors import NearestNeighbors
from sklearn.manifold import TSNE
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans, AgglomerativeClustering
from sklearn import preprocessing
from sklearn.metrics import adjusted_rand_score

from tileutils import usemodel, wrangle

def read_df(input_file_path):
    if input_file_path.endswith('.csv'):
        return get_df_from_csv(input_file_path)
    elif input_file_path.endswith('.pkl'):
        return get_df_from_pickle(input_file_path)
    else:
        raise ValueError('invalid input file type')

def write_df(data, output_file_path):
    if output_file_path.endswith('.csv'):
        return data.to_csv(output_file_path)
    elif output_file_path.endswith('.pkl'):
        return data.to_pickle(output_file_path)
    else:
        raise ValueError('invalid input file type')

def read_embedding(file_path):
    return np.squeeze(np.load(file_path))

def get_df_from_csv(file_path):
    data = pd.read_csv(file_path) # assumes at least row, col, zoom
    data['name'] = data.zoom.map(str).str.cat((data.col.map(str), data.row.map(str)), sep='_')
    data = data.set_index('name')
    return data

def get_df_from_pickle(file_path):
    return pd.read_pickle(file_path)

def get_df_from_directory(directory):
    filenames = os.listdir(directory)
    data = pd.DataFrame()
    data['filename'] = filenames
    data['name'] = data.filename.str.replace(r'\..+', '')
    data['zoom'], data['col'], data['row'] = data.name.str.split('_', 2).str
    data = data.set_index('name')
    return data

def get_embeddings(df, embeddings_dir):
    return df.index.map(lambda x: read_embedding(os.path.join(embeddings_dir, x+'.npy')))

def get_knn(data, k, repr_col):
    neigh = NearestNeighbors(k+1)

    print('starting to fit knn')
    start = time.time()
    neigh.fit(np.stack(data[repr_col]))
    print('elapsed {}s'.format(time.time() - start))

    print('starting to assign knn values')
    start = time.time()
    nn = data[repr_col].map(lambda arr: np.squeeze(neigh.kneighbors(arr.reshape(1,-1), return_distance=False))[1:])
    print('elapsed {}s'.format(time.time() - start))
    print('finished knn')

    return nn.map(lambda x: data.index[x].values)


def get_tsne(data, col_name, perplexity=30):
    tsne_embedding =  TSNE(verbose=3, perplexity=perplexity, n_iter=3000).fit_transform(np.vstack(data[col_name].values))
    return list(tsne_embedding)


def get_pca(data, col_name, n_components=10):
    numbers = np.vstack(data[col_name])
    numbers = preprocessing.scale(numbers)
    pca = PCA(n_components=n_components).fit(numbers)
    print(pca.explained_variance_)
    pca_embedding = pca.transform(numbers)
    return list(pca_embedding)


def get_kmeans(data, col_name, n_clusters=10):
    clusters = KMeans(n_clusters = n_clusters).fit_predict(np.vstack(data[col_name]))
    return list(clusters)
    
def get_ward(data, col_name, n_cluster=10):
    clusters = AgglomerativeClustering(n_cluster, linkage='ward').fit_predict(np.vstack(data[col_name]))
    return list(clusters)


def compare_clusters(data, cluster_columns):
    comparison = pd.DataFrame([[adjusted_rand_score(data[c1], data[c2]) for c2 in cluster_columns] for c1 in cluster_columns], columns = cluster_columns)
    comparison.index = cluster_columns
    return comparison
    

def analyse_embeds(args, input_name, output_file_name):
    data_root = os.path.join(os.path.abspath(os.path.dirname(__file__)), '..', 'data')

    input_path = os.path.join(data_root, 'analysis', input_name)
    
    analysis_result_path = os.path.join(data_root, 'analysis', output_file_name)

    do_processing = not args.extract_only
    
    data = read_df(input_path)

    if 'embeds' in args.modes:
        if args.embed_dir_name is None:
            raise ValueError('Embed dir name required')
        embeddings_dir = os.path.join(data_root, 'embeds', args.embed_dir_name)
        data['embed'] = get_embeddings(data, embeddings_dir)
    
    # data = get_df_from_directory(embeddings_dir)

    if 'knn' in args.modes:
        data['nn'] = get_knn(data, 5, 'embed')

    if 'tsne' in args.modes:
        if do_processing:
            data['tsne'] =  get_tsne(data, 'embed', args.tsne_perplexity)
        result = data.tsne.apply(pd.Series)
        result.columns = ['tsne_x', 'tsne_y']

    if 'pca' in args.modes:
        n_components = args.pca_components
        if do_processing:
            data['pca'] = get_pca(data, 'embed', n_components)
        pca_col_list = ['pca'+str(i) for i in range(n_components)]
        result = data.pca.apply(pd.Series)
        result.columns = pca_col_list

    if 'kmeans' in args.modes:
        column_name = 'kmeans'
        if do_processing:
            data[column_name] = get_kmeans(data, 'pca', args.kmeans_clusters)
        result = data[[column_name]]

    if args.result_only:
        write_df(result, analysis_result_path)
    else:
        write_df(data, analysis_result_path)


if __name__ == '__main__':

    parser = argparse.ArgumentParser() 
    parser.add_argument('csv_name')
    parser.add_argument('output_file_name')
    parser.add_argument('-r', '--result-only', action='store_true', default=False)
    parser.add_argument('-e', '--extract-only', action='store_true', default=False)
    parser.add_argument('-m', '--modes', nargs='*', default=[])
    parser.add_argument('-p', '--prefix')
    parser.add_argument('--embed-dir')
    parser.add_argument('--tsne-perplexity', type=int, default=30)
    parser.add_argument('--pca-components', type=int, default=10)
    parser.add_argument('--kmeans-clusters', type=int, default=5)

    args = parser.parse_args()

    analyse_embeds(args, args.csv_name, args.output_file_name)

