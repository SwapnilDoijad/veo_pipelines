import argparse
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch_geometric.nn as pyg_nn
from torch_geometric.data import DataLoader, Data
import numpy as np
from tqdm import tqdm
from GCNFrame import Biodata, GCNmodel
import pandas as pd
from sklearn.preprocessing import LabelEncoder
import umap
import matplotlib.pyplot as plt
from Bio import SeqIO
import pickle

# Argument parser for configurable paths
def parse_args():
    parser = argparse.ArgumentParser(description="Process and train GCN models.")
    parser.add_argument("--fasta_file", type=str, required=True, help="Path to the FASTA file.")
    parser.add_argument("--phylum_file", type=str, required=True, help="Path to the phylum label file.")
    parser.add_argument("--model_path", type=str, required=True, help="Path to save/load the GCN model.")
    parser.add_argument("--numeric_labels_path", type=str, required=True, help="Path to save numeric labels.")
    parser.add_argument("--label_mapping_path", type=str, required=True, help="Path to save label mapping.")
    parser.add_argument("--embedding_save_path", type=str, required=True, help="Path to save embeddings.")
    return parser.parse_args()

# Section 1: Prepare phylum labels
def prepare_phylum_labels(label_file, numeric_labels_path, label_mapping_path):
    labels_df = pd.read_csv(label_file, sep='\t', header=None, names=['sequence_id', 'phylum'])
    label_encoder = LabelEncoder()
    numeric_labels = label_encoder.fit_transform(labels_df['phylum'])
    label_mapping = dict(zip(label_encoder.classes_, range(len(label_encoder.classes_))))
    np.savetxt(numeric_labels_path, numeric_labels, fmt='%d')
    with open(label_mapping_path, 'w') as f:
        for phylum, idx in label_mapping.items():
            f.write(f"{phylum}\t{idx}\n")
    return numeric_labels, label_mapping

# Section 2: Train a two-class model
def train_model(fasta_file, numeric_labels_path, model_path):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    data = Biodata(fasta_file=fasta_file, label_file=numeric_labels_path, feature_file=None)
    dataset = data.encode(thread=20)
    model = GCNmodel.model(label_num=20, other_feature_dim=0).to(device)
    GCNmodel.train(dataset, model, weighted_sampling=True, batch_size=16, model_name=model_path)
    return dataset

# Section 3: BipartiteData class
class BipartiteData(Data):
    def _add_other_feature(self, other_feature):
        self.other_feature = other_feature

    def __inc__(self, key, value):
        if key == 'edge_index':
            return torch.tensor([[self.x_src.size(0)], [self.x_dst.size(0)]])
        else:
            return super(BipartiteData, self).__inc__(key, value)

# Section 4: Extract flattened embeddings
def get_flattened_embeddings_from_model(model, data, device):
    model.eval()
    with torch.no_grad():
        x_f = data.x_src.to(device)
        x_p = data.x_dst.to(device)
        edge_index_forward = data.edge_index[:, ::2].to(device)
        edge_index_backward = data.edge_index[[1, 0], :][:, 1::2].to(device)

        if model.pnode_nn:
            x_p = torch.reshape(x_p, (-1, model.pnode_num * model.pnode_dim))
            x_p = model.pnode_d(x_p)
            x_p = torch.reshape(x_p, (-1, model.node_hidden_dim))
        else:
            x_p = torch.reshape(x_p, (-1, model.pnode_dim))

        if model.fnode_nn:
            x_f = torch.reshape(x_f, (-1, model.fnode_num))
            x_f = model.fnode_d(x_f)
            x_f = torch.reshape(x_f, (-1, model.node_hidden_dim))
        else:
            x_f = torch.reshape(x_f, (-1, 1))

        if hasattr(model, 'label_embedding') and hasattr(data, 'y'):
            label_embedding = model.label_embedding(data.y)
            x_p = x_p + label_embedding.unsqueeze(1).expand(-1, x_p.size(1), -1)

        for i in range(model.gcn_layer_num):
            x_p = model.gconvs_1[i]((x_f, x_p), edge_index_forward)
            x_p = F.relu(x_p)
            x_f = model.gconvs_2[i]((x_p, x_f), edge_index_backward)
            x_f = F.relu(x_f)
            if not i == model.gcn_layer_num - 1:
                x_p = model.lns[i](x_p)
                x_f = model.lns[i](x_f)

        x_p = torch.reshape(x_p, (-1, model.gcn_dim, model.pnode_num))
        for i in range(model.cnn_layer_num):
            x_p = model.convs[i](x_p)
            x_p = F.relu(x_p)

        flattened_embedding = x_p.flatten(start_dim=1)
        return flattened_embedding.cpu(), data.y.cpu() if hasattr(data, 'y') else None

def get_flattened_dataset_embeddings(dataset, model_path, batch_size=8, device=None):
    if device is None:
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

    model = torch.load(model_path, map_location=device)
    model.to(device)
    model.eval()

    loader = DataLoader(dataset, batch_size=batch_size, shuffle=False, follow_batch=['x_src', 'x_dst'])
    embeddings = []
    labels = []

    with torch.no_grad():
        for batch in tqdm(loader, desc="Processing batches"):
            embedding, label = get_flattened_embeddings_from_model(model, batch, device)
            embeddings.append(embedding)
            if label is not None:
                labels.append(label)
            torch.cuda.empty_cache()

    embeddings = torch.cat(embeddings, dim=0)
    if labels:
        labels = torch.cat(labels, dim=0)
        return embeddings, labels
    return embeddings, None

# Section 5: Save embeddings
def save_embeddings(embeddings, save_path):
    with open(save_path, 'wb') as f:
        pickle.dump(embeddings, f)

# Main function
if __name__ == "__main__":
    args = parse_args()

    # Prepare labels
    prepare_phylum_labels(args.phylum_file, args.numeric_labels_path, args.label_mapping_path)

    # Train model
    dataset = train_model(args.fasta_file, args.numeric_labels_path, args.model_path)

    # Extract embeddings
    flattened_embeddings, labels = get_flattened_dataset_embeddings(dataset, args.model_path, batch_size=32)

    # Save embeddings
    save_embeddings(flattened_embeddings, args.embedding_save_path)

    print(f"Embeddings saved to {args.embedding_save_path}")

