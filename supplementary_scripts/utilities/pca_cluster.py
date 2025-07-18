import argparse
import pandas as pd
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score
import matplotlib.pyplot as plt

def auto_kmeans_pca(input_file, output_file, k_min=2, k_max=10):
    # Load and clean data
    df = pd.read_csv(input_file, sep='\t', index_col=0)
    df = df.drop(columns=[col for col in df.columns if "Unnamed" in col or df[col].isnull().all()])
    df = df.loc[df.index.intersection(df.columns)]
    df = df.apply(pd.to_numeric, errors='coerce').fillna(0)

    # Standardize
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(df)

    # PCA
    pca = PCA(n_components=2)
    X_pca = pca.fit_transform(X_scaled)

    # Determine best k using silhouette score
    best_k = k_min
    best_score = -1
    for k in range(k_min, min(k_max + 1, len(X_pca))):
        kmeans = KMeans(n_clusters=k, random_state=42)
        labels = kmeans.fit_predict(X_pca)
        score = silhouette_score(X_pca, labels)
        if score > best_score:
            best_k = k
            best_score = score

    # Final clustering with best_k
    kmeans = KMeans(n_clusters=best_k, random_state=42)
    clusters = kmeans.fit_predict(X_pca)

    # Plot
    plt.figure()  # Use default sizing
    scatter = plt.scatter(X_pca[:, 0], X_pca[:, 1], c=clusters, s=100, alpha=0.7)
    plt.title(f"PCA with K-means Clustering (k={best_k})", fontsize=16)
    plt.xlabel("Principal Component 1")
    plt.ylabel("Principal Component 2")
    plt.grid(True)
    plt.legend(*scatter.legend_elements(), title="Cluster")
    plt.tight_layout()
    plt.savefig(output_file, dpi=300)
    plt.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PCA + auto K-means clustering from a similarity matrix")
    parser.add_argument('-i', '--input', required=True, help='Input tab-delimited matrix file')
    parser.add_argument('-o', '--output', required=True, help='Output image file (e.g. .png)')
    parser.add_argument('--kmin', type=int, default=2, help='Minimum number of clusters to test')
    parser.add_argument('--kmax', type=int, default=10, help='Maximum number of clusters to test')
    args = parser.parse_args()

    auto_kmeans_pca(args.input, args.output, args.kmin, args.kmax)
