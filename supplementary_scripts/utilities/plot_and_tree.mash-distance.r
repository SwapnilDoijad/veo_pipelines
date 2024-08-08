###############################################################################
## simple tree plot
	library(ape)
	library(phangorn)
	all_distance <- as.matrix(read.table("results/0137_phylongey_ANI_by_mash/matrix.tab", header = TRUE, row.names = 1))
	treeUPGMA <- upgma(all_distance)
	mytree <- as.phylo(treeUPGMA)
	write.tree(mytree,file = "results/0137_phylongey_ANI_by_mash/matrix.tab.tree.phangorn.nwk")
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
	# pdf("results/0137_phylongey_ANI_by_mash/matrix.tab.tree.pvclust.pdf", width = 15, height = 10, pointsize = 12, family = "Helvetica", bg = "white")
	# plot(pvclust_tree, hang = -1, cex = 0.75 ) # or plot(pvclust_tree, hang = 0)
	# dev.off()

	# # Save dendrogram plot as SVG
	# svg("results/0137_phylongey_ANI_by_mash/matrix.tab.tree.pvclust.svg")
	# plot(pvclust_tree, hang = -1, cex = 0.75 ) # or plot(pvclust_tree, hang = 0)
	# dev.off()

	# # Set width and height for the PNG file (in inches)
	# png("results/0137_phylongey_ANI_by_mash/matrix.tab.tree.pvclust.png", width = 15, height = 10, units = "in", res = 300)  # Adjust width, height, and resolution as needed
	# plot(pvclust_tree, hang = -1, cex = 0.75 ) # or plot(pvclust_tree, hang = 0)
	# dev.off()
###############################################################################