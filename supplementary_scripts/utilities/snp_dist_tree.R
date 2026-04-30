#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
  library(ape)
})

option_list <- list(
  make_option(c("-i", "--input"), type="character", help="Input SNP distance matrix (tab-delimited)"),
  make_option(c("-o", "--output"), type="character", help="Output Newick tree file")
)

opt <- parse_args(OptionParser(option_list=option_list))

if (is.null(opt$input) || is.null(opt$output)) {
  stop("Usage: Rscript upgma_from_snp.R -i snp_dist.tsv -o tree.nwk\n", call.=FALSE)
}

# Read distance matrix
d <- read.table(
  opt$input,
  header = TRUE,
  row.names = 1,
  sep = "\t",
  check.names = FALSE
)

# Convert to dist object
dist_mat <- as.dist(d)

# UPGMA = average linkage
hc <- hclust(dist_mat, method = "average")

# Convert to phylo
tree <- as.phylo(hc)

# Write Newick
write.tree(tree, file = opt$output)
