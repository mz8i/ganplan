from scipy.stats import mannwhitneyu
import pandas as pd


data = pd.read_csv('../data/analysis/matched-ghs-fr-core.csv')

def get_mann_whitney(df,dataset, k, alpha=0.05):
    kmeans = pd.read_csv('../data/analysis/'+dataset+'/kmeans'+str(k)+'.csv')
    m = df.merge(kmeans, on='name')
    m['normdist'] = m.distance_from_center / m.city_max_dist
    clusters = sorted(m.cluster.unique())
    res= [mannwhitneyu(m[m.cluster==c1]['normdist'].values, m[m.cluster==c2]['normdist'].values, alternative='less') for c1 in clusters for c2 in clusters]
    return pd.DataFrame(np.array([str(r.statistic)+'*' if r.pvalue < alpha else str(r.statistic) for r in res]).reshape(k,k), columns=clusters, index=clusters)
    
def compare_mann_whitney(data, k):
    print('R2')
    print (get_mann_whitney(data, 'roads',k))
    print('B2')
    print(get_mann_whitney(data, 'buildings',k))
    print('RBW2')
    print(get_mann_whitney(data, 'rbw',k))


for i in range(2,20):
    r=get_mann_whitney(data, 'roads',i)
    b=get_mann_whitney(data, 'buildings',i)
    rbw=get_mann_whitney(data, 'rbw',i)
    pd.concat({'R2':r, 'B2':b, 'RBW2':rbw}, axis=1, names=['model', 'cluster']).to_csv('../data/analysis/mann_whitney/mann_whitney'+str(i)+'.csv')
    
compare_mann_whitney(data,5)