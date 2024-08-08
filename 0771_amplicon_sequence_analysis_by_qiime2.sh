#!/bin/bash
###############################################################################
## header
	pipeline=0771_amplicon_sequence_analysis_by_qiime2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: preparation

	source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate qiime2-2023.5 #&& qiime --help  

	( mkdir -p $wd/raw_files/ ) > /dev/null 2>&1

	manifest="data/manifest.tsv"
	metadata="data/metadata.tsv"
 	cat $parameters | grep -v "##" | awk '/forward-absolute-filepath/ {flag=1} flag {print} /^$/ {flag=0}' > $manifest
	cat $parameters | grep -v "##" | awk '/group/{flag=1} flag{if (/^$/) exit; print}' > $metadata

	sampling_depth=12000

###############################################################################
## step-01b : preparing the database (need only once)

	## step-01b : Import reference sequences and taxonomy information into QIIME 2
		# if [ ! -f /work/groups/VEO/databases/silva/v138.1/silva-ref-seqs.qza ] ; then 
		# 	log "STARTED : step-01b : Import reference sequences and taxonomy information into QIIME 2"
		# 	qiime feature-classifier fit-classifier-naive-bayes \
		# 	--i-reference-reads /work/groups/VEO/databases/silva/v138_for_qiime/silva-138-99-seqs.qza \
		# 	--i-reference-taxonomy /work/groups/VEO/databases/silva/v138_for_qiime/silva-138-99-tax.qza \
		# 	--o-classifier /work/groups/VEO/databases/silva/v138_for_qiime/silva-138-99-classifier.qza
		# 	log "ENDED : step-01b : Import reference sequences and taxonomy information into QIIME 2"
		# 	else
		# 	log "ALREADY FINISHED : step-01b : Import reference sequences and taxonomy information into QIIME 2"
		# fi 
	
	## step-01c: Validate the classifier (optional):
		# If you want to evaluate the performance of your trained classifier, \
		# you can use the qiime feature-classifier evaluate-classifier command.
 
			# qiime feature-classifier evaluate-classifier \
			# --i-classifier /work/groups/VEO/databases/silva/v138_for_qiime/silva-138-99-classifier.qza \
			# --i-reference-reads /work/groups/VEO/databases/silva/v138_for_qiime/silva-138-99-seqs.qza \
			# --i-reference-taxonomy /work/groups/VEO/databases/silva/v138_for_qiime/silva-138-99-tax.qza


###############################################################################
## step-02: QIIME2
## step-02-01 : Importing data
	# Use the qiime tools import command to import your raw sequencing data into QIIME 2. \
	# You'll need to specify the format of your data (e.g., Casava 1.8 single-end demultiplexed \
	# or paired-end demultiplexed) and provide the appropriate file paths.

	if [ ! -f $wd/raw_files/paired-end-demux.qza ] ; then 
		log "STARTED : step-02-01 : Importing data by qiime2"
		qiime tools import \
		--type 'SampleData[PairedEndSequencesWithQuality]' \
		--input-path $manifest \
		--output-path $raw_files/paired-end-demux.qza \
		--input-format PairedEndFastqManifestPhred33V2
		log "ENDED  : step-02-01 : Importing data by qiime2"
		else
		log "ALREADY FINISHED : step-02-01 : Importing data by qiime2"
	fi 

## step-02-02 : Checking the quality of the reads
	if [ ! -f $wd/raw_files/paired-end-demux.qza.qzv ] ; then
		log "STARTED : step-02-02 : Checking the quality of the reads by qiime2"
		qiime demux summarize \
		--i-data $wd/raw_files/paired-end-demux.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.qzv ## will show you the quality of the reads
		log "ENDED : step-02-02 : Summarize the demultiplexed data by qiime2"
		else
		log "ALREADY FINISHED : step-02-02 : Checking the quality of the reads by qiime2"
	fi 
	## Visuliase $wd/raw_files/paired-end-demux.qzv on https://view.qiime2.org/
	## and then decide the cutoff for next step. 
	## There should be atleast 10K reads per sample. 
	## Distribution of eqvivalent number of reads across the samples are good. 
	## read QC>20 is recommended

	## control step-1
	# exit 

## step-02-03 : Quality control and denoising
	# Perform quality control and denoising using the DADA2 or Deblur plugin. 
	# This step involves filtering out low-quality reads, removing chimeric sequences, \
	# and dereplicating sequences to generate amplicon sequence variants (ASVs). = count abundance

	## note the --p-trunc-len-f and --p-trunc-len-f values should not be lower (otherwise there will not be overalps)
	## below step for filtering reads (and its parameter values ) is important, as it results in the final number of reads

	if [ ! -f $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza ]; then 
		log "STARTED : step-02-03 : Quality control and denoising by qiime2"
		qiime dada2 denoise-paired \
		--i-demultiplexed-seqs $wd/raw_files/paired-end-demux.qza \
		--p-trim-left-f 20 \
		--p-trim-left-r 10 \
		--p-trunc-len-f 240 \
		--p-trunc-len-r 240 \
		--p-n-threads 20 \
		--o-representative-sequences $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza \
		--o-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza \
		--o-denoising-stats $wd/raw_files/paired-end-demux.qza.stats-dada2.qza
		log "ENDED : step-02-03 : Quality control and denoising by qiime2"
		else
		log "ALREADY FINISHED : step-02-03 : Quality control and denoising by qiime2"
	fi 

## step-02-04 : FeatureTable and FeatureData summarize
	if [ ! -f $wd/raw_files/paired-end-demux.qza.stats-dada2.qza.qzv ] ; then 
		log "STARTED : step-02-04 : FeatureTable and FeatureData summarize by qiime2"
		qiime feature-table summarize \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.table-dada2.qza.qzv \
		--m-sample-metadata-file $metadata

		qiime feature-table tabulate-seqs \
		--i-data $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.qzv

		qiime metadata tabulate \
		--m-input-file $wd/raw_files/paired-end-demux.qza.stats-dada2.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.stats-dada2.qza.qzv ## important statistics to view

		log "FINISHED : step-02-04 : FeatureTable and FeatureData summarize by qiime2"
		else
		log "ALREADY FINISHED : step-02-04 : FeatureTable and FeatureData summarize by qiime2"
	fi 
	## Visuliase $wd/raw_files/paired-end-demux.qza.stats-dada2.qza.qzv on https://view.qiime2.org/
	## and then decide the cutoff for next step. 

	## control step-2
	# exit 

## step-02-05 : Taxonomic classification
	# Assign taxonomy to the representative sequences using a classifier trained on the 16S rRNA gene sequences. \
	# QIIME 2 provides pre-trained classifiers for various regions of the 16S rRNA gene (e.g., Greengenes, SILVA).

	# /work/groups/VEO/databases/silva/silva-138-99-515-806-nb-classifier.pretrained_directly_downloaded.qza
	if [ ! -f $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza.qzv ]; then
		log "STARTED : step-02-05 : Taxonomic classification by qiime2"
		qiime feature-classifier classify-sklearn \
		--p-n-jobs 20 \
		--i-classifier /work/groups/VEO/databases/silva/silva-138-99-nb-classifier.pretrained_directly_downloaded.qza \
		--i-reads $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza \
		--o-classification $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza

		# summerize taxonomy info
		qiime metadata tabulate \
		--m-input-file $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza.qzv

		## export taxonomy info 
		## this will give you the taxonomy (assignment of each id to taxonomic lineage) info in a tsv file
		qiime tools export \
		--input-path $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--output-path $wd/raw_files/taxonomy_exported

		log "ENDED : step-02-05 : Taxonomic classification by qiime2"
		else
		log "ALREADY FINISHED : step-02-05 : Taxonomic classification by qiime2"
	fi 

## step-02-06 : Remove non-bacterial sequence and singletons
	# Remove non-bacterial sequences from the feature table and representative sequences.
	# rm -rf $wd/raw_files/*.bacteria_only.*
	if [ ! -f $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.qzv ]; then 
		log "STARTED : step-02-06 : Remove non-bacterial sequence and singletons by qiime2"

		qiime taxa filter-table \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza \
		--i-taxonomy $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--p-include Bacteria,Archaea \
		--p-exclude eukaryota,mitochondria,chloroplast \
		--o-filtered-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza

		qiime taxa filter-seqs \
		--i-sequences $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza \
		--i-taxonomy $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--p-include Bacteria,Archaea \
		--p-exclude eukaryota,mitochondria,chloroplast \
		--o-filtered-sequences $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza

		## filter samples
		qiime feature-table filter-features \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza \
		--p-min-samples 1 \
		--p-min-frequency 2 \
		--o-filtered-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza

		## remove singletons sequence
		qiime feature-table filter-seqs \
		--i-data $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--o-filtered-data $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza

		# FeatureTable and FeatureData summarize
		qiime feature-table summarize \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.qzv \
		--m-sample-metadata-file $metadata

		qiime feature-table tabulate-seqs \
		--i-data $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza \
		--o-visualization $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.qzv

		log "ENDED : step-02-06 : Remove non-bacterial sequence and singletons by qiime2"
		else
		log "ALREADY FINISHED : step-02-06 : Remove non-bacterial sequence and singletons by qiime2"
	fi

## step-02-07 : Exporting feature-table, tabulate feature-table with taxonomy
	## raw unfiltered 
	if [ ! -f $wd/raw_files/exported_unfiltered/feature-table-filtered.tsv ] ; then 
		log "STARTED : step-02-06 : Exporting feature-table-filtered.tsv by qiime2" 
		mkdir -p $wd/raw_files/exported_unfiltered/
		qiime tools export \
		--input-path $wd/raw_files/paired-end-demux.qza.table-dada2.qza \
		--output-path $wd/raw_files/exported_unfiltered/

		biom convert -i $wd/raw_files/exported_unfiltered/feature-table.biom -o $wd/raw_files/exported_unfiltered/feature-table-filtered.tsv --to-tsv
	fi 

	## filtered
	if [ ! -f $wd/raw_files/exported/feature-table-filtered.tsv ] ; then 
		log "STARTED : step-02-06 : Exporting feature-table-filtered.tsv by qiime2" 
		mkdir -p $wd/raw_files/exported/
		qiime tools export \
		--input-path $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--output-path $wd/raw_files/exported/

		biom convert -i $wd/raw_files/exported/feature-table.biom -o $wd/raw_files/exported/feature-table-filtered.tsv --to-tsv
	fi 

	## step-02-06-03: tabulate feature-table with taxonomy
		if [ ! -f $wd/raw_files/exported_taxonomy/feature-table.biom.tsv ] ; then
			log "STARTED : step-02-06 : tabulate feature-table with taxonomy by qiime2"

			mkdir $wd/raw_files/exported_taxonomy

			qiime tools export \
			--input-path $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
			--output-path $wd/raw_files/exported_taxonomy/

			# qiime metadata tabulate \
			# --m-input-file $wd/raw_files/exported_taxonomy/taxonomy.tsv \
			# --m-input-file $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
			biom convert \
			-i $wd/raw_files/exported_taxonomy/feature-table.biom \
			-o $wd/raw_files/exported_taxonomy/feature-table.biom.tsv \
			--to-tsv

			log "ENDED : step-02-06 : tabulate feature-table with taxonomy by qiime2"
			else
			log "ALREADY FINISHED : step-02-06 : tabulate feature-table with taxonomy by qiime2"
		fi 

## rarefy sequences ?????????????????
## step-02-08: Phylogenetic reconstruction (optional but recommended):
	# Build a phylogenetic tree from the representative sequences using the qiime phylogeny \
	# align-to-tree-mafft-fasttree or qiime phylogeny align-to-tree-mafft-raxml command. \
	# This step is essential for downstream diversity analyses.

	if [ ! -f $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza ]; then
		log "STARTED : step-02-07 : Phylogenetic reconstruction by qiime2"
		qiime phylogeny align-to-tree-mafft-fasttree \
		--p-n-threads 40 \
		--i-sequences $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza \
		--o-alignment $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.alignment.qza \
		--o-masked-alignment $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.masked-aligned.qza \
		--o-tree $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.tree.qza \
		--o-rooted-tree $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza

		qiime tools export \
		--input-path $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza \
		--output-path $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza.nwk

		log "ENDED : step-02-07 : Phylogenetic reconstruction by qiime2"
		else
		log "ALREADY FINISHED : step-02-07 : Phylogenetic reconstruction by qiime2"
	fi 

## step-02-09 : core-metrics-phylogenetic (optional)
	# if [ ! -f $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv ] ; then
	# 	log "STARTED : step-02-09 : core-metrics-phylogenetic by qiime2"
	# 	mkdir $wd/core_metrics_results

	# 	qiime diversity core-metrics-phylogenetic \
	# 	--i-phylogeny $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza \
	# 	--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
	# 	--p-sampling-depth $sampling_depth \
	# 	--m-metadata-file $metadata \
	# 	--output-dir $wd/core_metrics_results

	# 	qiime tools export \
	# 	--input-path $wd/core_metrics_results/bray_curtis_distance_matrix.qza \
	# 	--output-path $wd/core_metrics_results/bray_curtis_distance_matrix/

	# 	qiime diversity alpha-group-significance \
	# 	--i-alpha-diversity $wd/core_metrics_results/shannon_vector.qza \
	# 	--m-metadata-file $metadata \
	# 	--o-visualization $wd/core_metrics_results/shannon-group-significance.qzv

		# qiime diversity adonis \
		# --i-distance-matrix $wd/core_metrics_results/weighted_unifrac_distance_matrix.qza \
		# --m-metadata-file $metadata \
		# --p-formula "group" \
		# --o-visualization $wd/core_metrics_results/weighted_unifrac_distance_matrix.qza.qzv

	# 	log "ENDED : step-02-09 : core-metrics-phylogenetic by qiime2"
	# 	else
	# 	log "ALREADY FINISHED : step-02-09 : core-metrics-phylogenetic by qiime2"
	# fi  
## step-02-10 : Alpha and beta diversity analysis
	# Calculate alpha diversity metrics (within-sample diversity) and beta diversity metrics \
	# (between-sample diversity) using various QIIME 2 plugins.
	if [ ! -f $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza ] ; then
		log "STARTED : step-02-09 : Alpha and beta diversity analysis by qiime2"

		## alpha diversity
		qiime diversity alpha \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-metric shannon \
		--o-alpha-diversity $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza

		qiime diversity alpha-group-significance \
		--i-alpha-diversity $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza \
		--m-metadata-file $metadata \
		--o-visualization $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qzv

		qiime tools export \
		--input-path $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza \
		--output-path $wd/raw_files/alpha_diversity_export

		## beta diversity
		qiime diversity beta \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-metric braycurtis \
		--o-distance-matrix $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza

		qiime diversity pcoa \
		--i-distance-matrix $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		--o-pcoa $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-pcoa.qza

		qiime emperor plot \
		--i-pcoa $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-pcoa.qza \
		--m-metadata-file $metadata \
		--o-visualization $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-emperor.qzv

		log "ENDED : step-02-09 : Alpha and beta diversity analysis by qiime2"
		else
		log "ALREADY FINISHED : step-02-09 : Alpha and beta diversity analysis by qiime2"
	fi 

## step-02-11: Generate taxonomic bar plots in QIIME 2
	if [ ! -f $wd/raw_files/bar-plot.qzv ] ; then
		log "STARTED : step-02-11 : Generate taxonomic bar plots in QIIME 2"
		qiime taxa barplot \
		--i-table $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--i-taxonomy $wd/raw_files/paired-end-demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--m-metadata-file $metadata \
		--o-visualization $wd/raw_files/bar-plot.qzv

		qiime tools export \
		--input-path $wd/raw_files/bar-plot.qzv \
		--output-path $wd/raw_files/bar-plot-exported

		log "ENDED : step-02-11 : Generate taxonomic bar plots in QIIME 2"
		else
		log "ALREADY FINISHED : step-02-11 : Generate taxonomic bar plots in QIIME 2"
	fi
## step-02-11: pcoa

	if [ ! -f $wd/raw_files/pcoa_output/pca_plot.qzv ] ; then
		mkdir $wd/raw_files/pcoa_output

		# Import Feature Table
		qiime tools import \
		--type 'FeatureTable[Frequency]' \
		--input-path $wd/raw_files/exported/feature-table.biom \
		--output-path $wd/raw_files/exported/feature-table.qza

		# Import Metadata
		qiime metadata tabulate \
		--m-input-file $metadata \
		--o-visualization $wd/raw_files/exported/metadata.qzv

		# Perform PCoA
		qiime diversity pcoa \
		--i-distance-matrix $wd/raw_files/paired-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		--o-pcoa $wd/raw_files/pcoa_output/pcoa.qza

		# Export PCoA Results
		qiime tools export \
		--input-path $wd/raw_files/pcoa_output/pcoa.qza \
		--output-path $wd/raw_files/pcoa_output/pcoa_output_exported

		# Convert Ordination to QZA Format
		qiime tools import \
		--type PCoAResults \
		--input-path $wd/raw_files/pcoa_output/pcoa_output_exported/ordination.txt \
		--output-path $wd/raw_files/pcoa_output/ordination.qza

		# Visualize PCA Plot
		qiime emperor plot \
		--i-pcoa $wd/raw_files/pcoa_output/ordination.qza \
		--m-metadata-file $metadata \
		--o-visualization $wd/raw_files/pcoa_output/pca_plot.qzv
	fi 

	## OPTIONAL : pcoa plot 
	## need specific metadata file for this step
	if [ ! -f $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv.png ] ; then 
		log "RUNNING : step-02-11 : customised pcoa plot by a custom-python script"
		python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0771_amplicon_sequence_analysis_by_qiime2.pcoa.py \
		--matrix_file $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv \
		--metadata_file $metadata \
		--output $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv.png
		log "ENDED : step-02-11 : customised pcoa plot by a custom-python script"
		else
		log "ALREADY FINISHED : step-02-11 : customised pcoa plot by a custom-python script"
	fi 


## incomplete barplot script /home/groups/VEO/scripts_for_users/supplementary_scripts/0771_amplicon_sequence_analysis_by_qiime2.barplot.py
###############################################################################
## footer
	log "ENDED: 0771_amplicon_sequence_analysis_by_qiime2 -----------------------------"
###############################################################################
## refrences: https://www.youtube.com/watch?v=RcdTZE8VbJg&list=PLOCEVoX6zu2Ii8RD7i9Oi7Pbot_5WF08n&ab_channel=InstituteforSystemsBiology
