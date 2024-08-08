#!/bin/bash
###############################################################################
## header
	pipeline=0772_amplicon_sequence_analysis_by_qiime2_for_nanopore
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline -----------------------------"
###############################################################################
## step-01: preparation

	( mkdir -p $raw_files/ ) > /dev/null 2>&1
	source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate qiime2-2023.5 #&& qiime --help  

	manifest=data/manifest.tsv
	fasta_path=/home/xa73pav/projects/p_xiu/results/0992_calculate_abundance_from_degenerative_primer/raw_files/read_ids_extracted_fastq
	# metadata=data/metadata.sham-pci.2.tsv
	# sampling_depth=5000
	mkdir -p $wd/tmp/sbatch
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
		
		if [ ! -f $raw_files/sequences.qza ] ; then 
			log "STARTED : step-02-01 : Importing data by qiime2"

			# import fastq files
				qiime tools import \
				--type 'SampleData[SequencesWithQuality]' \
				--input-path $manifest \
				--output-path $raw_files/sequences.qza \
				--input-format SingleEndFastqManifestPhred33V2

							## import fasta files
							## deblur did not work on 20240626 on fasta data as QC score needed

								# for file in $fasta_path/*.fastq.fasta.filtered ; do

								# 	sample_id=$(basename "$file" .fastq.fasta.filtered | awk -F'.' '{print $2}' )
								# 	log "importing sample $sample_id"
									
								# 	sed "s|my_file|$file|g" $suppl_scripts/$pipeline.import.sbatch \
								# 	| sed "s/my_sample_id/$sample_id/g" \
								# 	> $wd/tmp/sbatch/$sample_id.import.sbatch

								# 	sbatch $wd/tmp/sbatch/$sample_id.import.sbatch
								# done
								# wait_till_all_job_finished qiime2_import

								# my_dir=$(pwd)
								# inputs=""
								# for qza in $my_dir/$raw_files/qza/*.qza; do
								# 	echo $qza
								# 	inputs+=" --i-data $qza"
								# done

								# qiime feature-table merge-seqs $inputs \
								# --o-merged-data $raw_files/sequences.qza
				

			log "ENDED  : step-02-01 : Importing data by qiime2"
			else
			log "ALREADY FINISHED : step-02-01 : Importing data by qiime2"
		fi 	

## step-02-02 : Checking the quality of the reads
	## not to run for fasta input
	if [ -f $raw_files/sequences.qza ] && [ ! -f $raw_files/sequences.qza.qzv ] ; then
		log "STARTED : step-02-02 : Checking the quality of the reads by qiime2"
		qiime demux summarize \
		--i-data $raw_files/sequences.qza \
		--o-visualization $raw_files/sequences.qza.qzv ## will show you the quality of the reads
		log "ENDED : step-02-02 : Summarize the demultiplexed data by qiime2"
		else
		log "ALREADY FINISHED : step-02-02 : Checking the quality of the reads by qiime2"
	fi 
	## Visuliase $raw_files/single-end-demux.qza on https://view.qiime2.org/
	## and then decide the cutoff for next step. 
	## There should be atleast 10K reads per sample. 
	## Distribution of equivivalent number of reads across the samples are good. 
	## read QC>20 is recommended

## step-02-03 : Quality control and denoising
	# Perform quality control and denoising using Deblur plugin. For Nanopore data, DADA2 might not be optimal.
	# This step involves filtering out low-quality reads, removing chimeric sequences, \
	# and dereplicating sequences to generate amplicon sequence variants (ASVs). = count abundance

	if [ ! -f $raw_files/sequences.rep_seqs_deblur.qza ]; then 
		log "STARTED : step-02-03 : Quality control and denoising by qiime2"
		qiime deblur denoise-16S \
		--i-demultiplexed-seqs $raw_files/sequences.qza \
		--p-trim-length 1300 \
		--p-sample-stats \
		--p-min-reads 1 \
		--p-min-size 1 \
		--p-jobs-to-start 40 \
		--o-representative-sequences $raw_files/sequences.rep_seqs_deblur.qza \
		--o-table $raw_files/sequences.deblur_table.qza \
		--o-stats $raw_files/sequences.deblur_stats.qza
		log "ENDED : step-02-03 : Quality control and denoising by qiime2"
		else
		log "ALREADY FINISHED : step-02-03 : Quality control and denoising by qiime2"
	fi 

## step-02-04 : FeatureTable and FeatureData summarize
	if [ ! -f $raw_files/sequences.deblur_table.qza.qzv ] ; then 
		log "STARTED : step-02-04 : FeatureTable and FeatureData summarize by qiime2"
		qiime feature-table summarize \
		--i-table $raw_files/sequences.deblur_table.qza \
		--o-visualization $raw_files/sequences.deblur_table.qza.qzv \
		--m-sample-metadata-file $metadata

		qiime feature-table tabulate-seqs \
		--i-data $raw_files/sequences.rep_seqs_deblur.qza \
		--o-visualization $raw_files/sequences.rep_seqs_deblur.qza.qzv

		## Artifacts with type DeblurStats cannot be viewed as QIIME 2 metadata.
			# qiime metadata tabulate \
			# --m-input-file $raw_files/sequences.deblur_stats.qza \
			# --o-visualization $raw_files/sequences.deblur_stats.qza.qzv ## important statistics to view

		qiime deblur visualize-stats \
		--i-deblur-stats $raw_files/sequences.deblur_stats.qza \
		--o-visualization $raw_files/sequences.deblur_stats.qzv

		log "FINISHED : step-02-04 : FeatureTable and FeatureData summarize by qiime2"
		else
		log "ALREADY FINISHED : step-02-04 : FeatureTable and FeatureData summarize by qiime2"
	fi 
	## Visuliase $raw_files/single-end-demux.qza.stats-dada2.qza.qzv on https://view.qiime2.org/
	## and then decide the cutoff for next step. 
 exit 
## step-02-05 : Taxonomic classification
	# Assign taxonomy to the representative sequences using a classifier trained on the 16S rRNA gene sequences. \
	# QIIME 2 provides pre-trained classifiers for various regions of the 16S rRNA gene (e.g., Greengenes, SILVA).

	# /work/groups/VEO/databases/silva/silva-138-99-515-806-nb-classifier.pretrained_directly_downloaded.qza
	if [ ! -f $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.taxonomy.qza.qzv ]; then
		log "STARTED : step-02-05 : Taxonomic classification by qiime2"
		qiime feature-classifier classify-sklearn \
		--p-n-jobs 40 \
		--i-classifier /work/groups/VEO/databases/silva/silva-138-99-nb-classifier.pretrained_directly_downloaded.qza \
		--i-reads $raw_files/sequences.rep_seqs_deblur.qza \
		--o-classification $raw_files/sequences.rep_seqs_deblur.qza.taxonomy.qza

		# summerize taxonomy info
		qiime metadata tabulate \
		--m-input-file $raw_files/sequences.rep_seqs_deblur.qza.taxonomy.qza \
		--o-visualization $raw_files/sequences.rep_seqs_deblur.qza.taxonomy.qza.qzv

		log "ENDED : step-02-05 : Taxonomic classification by qiime2"
		else
		log "ALREADY FINISHED : step-02-05 : Taxonomic classification by qiime2"
	fi 
exit 
## step-02-06 : Remove non-bacterial sequence and singletons
	# Remove non-bacterial sequences from the feature table and representative sequences.
	# rm -rf $raw_files/*.bacteria_only.*
	if [ ! -f $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.qzv ]; then 
		log "STARTED : step-02-06 : Remove non-bacterial sequence and singletons by qiime2"

		qiime taxa filter-table \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza \
		--i-taxonomy $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.taxonomy.qza \
		--p-include Bacteria \
		--p-exclude archaea,eukaryota,mitochondria,chloroplast \
		--o-filtered-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza

		qiime taxa filter-seqs \
		--i-sequences $raw_files/single-end-demux.qza.rep-seqs-deblur.qza \
		--i-taxonomy $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.taxonomy.qza \
		--p-include Bacteria \
		--p-exclude archaea,eukaryota,mitochondria,chloroplast \
		--o-filtered-sequences $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza

		## remove singletons table
		qiime feature-table filter-features \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza \
		--p-min-samples 2 \
		--o-filtered-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza

		## remove singletons sequence
		qiime feature-table filter-seqs \
		--i-data $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--o-filtered-data $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza

		# FeatureTable and FeatureData summarize
		qiime feature-table summarize \
		--i-table  $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--o-visualization  $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.qzv \
		--m-sample-metadata-file $metadata

		qiime feature-table tabulate-seqs \
		--i-data $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza \
		--o-visualization $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.qzv

		log "ENDED : step-02-06 : Remove non-bacterial sequence and singletons by qiime2"
		else
		log "ALREADY FINISHED : step-02-06 : Remove non-bacterial sequence and singletons by qiime2"
	fi

## step-02-07 : Exporting feature-table, tabulate feature-table with taxonomy
	## raw unfiltered 
	if [ ! -f $raw_files/exported_unfiltered/feature-table-filtered.tsv ] ; then 
		log "STARTED : step-02-06 : Exporting feature-table-filtered.tsv by qiime2" 
		mkdir -p $raw_files/exported_unfiltered/
		qiime tools export \
		--input-path $raw_files/single-end-demux.qza.table-dada2.qza \
		--output-path $raw_files/exported_unfiltered/

		biom convert -i $raw_files/exported_unfiltered/feature-table.biom -o $raw_files/exported_unfiltered/feature-table-filtered.tsv --to-tsv
	fi 

	## filtered
	if [ ! -f $raw_files/exported/feature-table-filtered.tsv ] ; then 
		log "STARTED : step-02-06 : Exporting feature-table-filtered.tsv by qiime2" 
		mkdir -p $raw_files/exported/
		qiime tools export \
		--input-path $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--output-path $raw_files/exported/

		biom convert -i $raw_files/exported/feature-table.biom -o $raw_files/exported/feature-table-filtered.tsv --to-tsv
	fi 

	## step-02-06-03: tabulate feature-table with taxonomy
		if [ ! -f $raw_files/exported_taxonomy/feature-table.biom.tsv ] ; then
			log "STARTED : step-02-06 : tabulate feature-table with taxonomy by qiime2"

			mkdir $raw_files/exported_taxonomy

			qiime tools export \
			--input-path $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
			--output-path $raw_files/exported_taxonomy/

			# qiime metadata tabulate \
			# --m-input-file $raw_files/exported_taxonomy/taxonomy.tsv \
			# --m-input-file $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
			biom convert \
			-i $raw_files/exported_taxonomy/feature-table.biom \
			-o $raw_files/exported_taxonomy/feature-table.biom.tsv \
			--to-tsv

			log "ENDED : step-02-06 : tabulate feature-table with taxonomy by qiime2"
			else
			log "ALREADY FINISHED : step-02-06 : tabulate feature-table with taxonomy by qiime2"
		fi 

## rarefy sequences ?????????????????

## step-02-07: Phylogenetic reconstruction (optional but recommended):
	# Build a phylogenetic tree from the representative sequences using the qiime phylogeny \
	# align-to-tree-mafft-fasttree or qiime phylogeny align-to-tree-mafft-raxml command. \
	# This step is essential for downstream diversity analyses.

	if [ ! -f $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza ]; then
		log "STARTED : step-02-07 : Phylogenetic reconstruction by qiime2"
		qiime phylogeny align-to-tree-mafft-fasttree \
		--p-n-threads 40 \
		--i-sequences $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza \
		--o-alignment $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.alignment.qza \
		--o-masked-alignment $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.masked-aligned.qza \
		--o-tree $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.tree.qza \
		--o-rooted-tree $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza

		qiime tools export \
		--input-path $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza \
		--output-path $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza.nwk

		log "ENDED : step-02-07 : Phylogenetic reconstruction by qiime2"
		else
		log "ALREADY FINISHED : step-02-07 : Phylogenetic reconstruction by qiime2"
	fi 

## step-02-09 : core-metrics-phylogenetic 
	if [ ! -f $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv ] ; then

		qiime diversity core-metrics-phylogenetic \
		--i-phylogeny $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-sampling-depth $sampling_depth \
		--m-metadata-file $metadata \
		--output-dir $wd/core_metrics_results

		qiime tools export \
		--input-path $wd/core_metrics_results/bray_curtis_distance_matrix.qza \
		--output-path $wd/core_metrics_results/bray_curtis_distance_matrix/

		qiime diversity alpha-group-significance \
		--i-alpha-diversity $wd/core_metrics_results/shannon_vector.qza \
		--m-metadata-file $metadata \
		--o-visualization $wd/core_metrics_results/shannon-group-significance.qzv

		# qiime diversity adonis \
		# --i-distance-matrix $wd/core_metrics_results/weighted_unifrac_distance_matrix.qza \
		# --m-metadata-file $metadata \
		# --p-formula "group" \
		# --o-visualization $wd/core_metrics_results/weighted_unifrac_distance_matrix.qza.qzv
	fi 
	
## step-02-09 : Alpha and beta diversity analysis
	# Calculate alpha diversity metrics (within-sample diversity) and beta diversity metrics \
	# (between-sample diversity) using various QIIME 2 plugins.
	if [ ! -f $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza ] ; then
		log "STARTED : step-02-09 : Alpha and beta diversity analysis by qiime2"

		qiime diversity alpha \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-metric shannon \
		--o-alpha-diversity $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza

		qiime diversity beta \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-metric braycurtis \
		--o-distance-matrix $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza

		log "ENDED : step-02-09 : Alpha and beta diversity analysis by qiime2"
		else
		log "ALREADY FINISHED : step-02-09 : Alpha and beta diversity analysis by qiime2"
	fi 


## step-02-10: Generate taxonomic bar plots in QIIME 2
	if [ ! -f $raw_files/bar-plot.qzv ] ; then
		log "STARTED : step-02-10 : Generate taxonomic bar plots in QIIME 2"
		qiime taxa barplot \
		--i-table $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--i-taxonomy $raw_files/single-end-demux.qza.rep-seqs-deblur.qza.taxonomy.qza \
		--m-metadata-file $metadata \
		--o-visualization $raw_files/bar-plot.qzv

		qiime tools export \
		--input-path $raw_files/bar-plot.qzv \
		--output-path $raw_files/bar-plot-exported

		log "ENDED : step-02-10 : Generate taxonomic bar plots in QIIME 2"
		else
		log "ALREADY FINISHED : step-02-10 : Generate taxonomic bar plots in QIIME 2"
	fi

## step-02-11: pcoa

	if [ ! -f $raw_files/pcoa_output/pca_plot.qzv ] ; then
		mkdir $raw_files/pcoa_output

		# Import Feature Table
		qiime tools import \
		--type 'FeatureTable[Frequency]' \
		--input-path $raw_files/exported/feature-table.biom \
		--output-path $raw_files/exported/feature-table.qza

		# Import Metadata
		qiime metadata tabulate \
		--m-input-file $metadata \
		--o-visualization $raw_files/exported/metadata.qzv

		# Perform PCoA
		qiime diversity pcoa \
		--i-distance-matrix $raw_files/single-end-demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		--o-pcoa $raw_files/pcoa_output/pcoa.qza

		# Export PCoA Results
		qiime tools export \
		--input-path $raw_files/pcoa_output/pcoa.qza \
		--output-path $raw_files/pcoa_output/pcoa_output_exported

		# Convert Ordination to QZA Format
		qiime tools import \
		--type PCoAResults \
		--input-path $raw_files/pcoa_output/pcoa_output_exported/ordination.txt \
		--output-path $raw_files/pcoa_output/ordination.qza

		# Visualize PCA Plot
		qiime emperor plot \
		--i-pcoa $raw_files/pcoa_output/ordination.qza \
		--m-metadata-file $metadata \
		--o-visualization $raw_files/pcoa_output/pca_plot.qzv
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
