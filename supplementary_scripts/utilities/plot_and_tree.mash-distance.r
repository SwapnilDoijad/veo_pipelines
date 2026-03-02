###############################################################################
## simple tree plot
	# library(ape)
	# library(phangorn)
	# all_distance <- as.matrix(read.table("results/0137_phylogeny_ANI_by_mash/raw_files/matrix.tab", header = TRUE, row.names = 1, sep = "\t"))
	# treeUPGMA <- upgma(all_distance)
	# mytree <- as.phylo(treeUPGMA)
	# write.tree(mytree,file = "results/0137_phylogeny_ANI_by_mash/matrix.tab.tree.phangorn.nwk")
	# Note: UPGMA may not cluster genomes in same cluster

	## Notes: With higher numbers of genomes, clustering do not occur correctly. 
	## Other methods tried. 
		## Plot the tree using the NJ method, better than UPGMA for Mash distances
			# library(ape)
			# all_distance <- as.matrix(read.table("/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab", header=TRUE, row.names=1, sep="\t"))
			# dist_object <- as.dist(all_distance)
			# treeNJ <- nj(dist_object)
			# write.tree(treeNJ, file="/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab.tree.NJ.nwk")
			# plot(treeNJ, main="Mash Distance - NJ Tree")
		## robust tree using FastME
			# library(ape)
			# all_distance <- as.matrix(read.table("/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab", header=TRUE, row.names=1, sep="\t"))
			# dist_object <- as.dist(all_distance)
			# tree <- fastme.bal(dist_object)
			# write.tree(tree, file="/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab.fastme_tree.nwk")
			# plot(tree, main="Mash Distance Taxonomy Tree (FastME)")
		## tree using hclust
			# library(ape)
			# mash <- as.matrix(read.table("/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab", header=TRUE, row.names=1, sep="\t", check.names=FALSE))
			# dist_object <- as.dist(mash)
			# hc <- hclust(dist_object, method="average")
			# tree <- as.phylo(hc)
			# write.tree(tree, file="/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab.hc_average.nwk")
			# plot(tree, cex=0.5, main="Mash-based Taxonomy Tree")
###############################################################################
## bootstrap tree plot
	# library(pvclust)

	# # Read precomputed Mash distances from the file
	# myData <- as.matrix(read.table("results/0137_phylongey_ANI_by_mash/matrix.tab", header = TRUE, row.names = 1))

	# # Perform hierarchical clustering with pvclust using the provided distances
	# pvclust_tree <- pvclust(myData, method.dist = "correlation", method.hclust = "average", nboot = 1000)

	# # Plot the dendrogram
	# plot(pvclust_tree, hang = -1)

	# # Save dendrogram plot as PNG
	# pdf("/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab.tree.pvclust.pdf", width = 15, height = 10, pointsize = 12, family = "Helvetica", bg = "white")
	# plot(pvclust_tree, hang = -1, cex = 0.75 ) # or plot(pvclust_tree, hang = 0)
	# dev.off()

	# # Save dendrogram plot as SVG
	# svg("/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files/matrix.tab.tree.pvclust.svg")
	# plot(pvclust_tree, hang = -1, cex = 0.75 ) # or plot(pvclust_tree, hang = 0)
	# dev.off()

	# # Set width and height for the PNG file (in inches)
	# png("/vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/results_unarranged_genomes/0137_phylogeny_ANI_by_mash_2136/raw_files	/matrix.tab.tree.pvclust.png", width = 15, height = 10, units = "in", res = 300)  # Adjust width, height, and resolution as needed
	# plot(pvclust_tree, hang = -1, cex = 0.75 ) # or plot(pvclust_tree, hang = 0)
	# dev.off()
###############################################################################

Rhizobium mongolense subsp. loessense CGMCC 1.3401 GCF 900099775.1
rhizo 158890.5 bvbrc
rhizo 57676.5 bvbrc
rhizo 1079460.13 bvbrc
rhizo 57676.3 bvbrc
Rhizobium mongolense USDA 1844 GCF 000419765.1
rhizo 1079460.3 bvbrc
rhizo 2785056.3 bvbrc
rhizo 56730.16 bvbrc
rhizo 3039160.9 bvbrc
rhizo 3039160.8 bvbrc
rhizo 3039160.6 bvbrc
rhizo 3039160.4 bvbrc
rhizo 3039160.10 bvbrc
