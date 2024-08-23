#!/bin/bash
#SBATCH --job-name 0771_amplicon_sequence_analysis_by_qiime2
#SBATCH --partition=short,interactive,standard,long,gpu
#SBATCH --output results/0771_amplicon_sequence_analysis_by_qiime2/tmp/slurm/%J.out
#SBATCH --error results/0771_amplicon_sequence_analysis_by_qiime2/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com
###############################################################################
## header
	pipeline=0771_amplicon_sequence_analysis_by_qiime2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-00a: preparation

	# source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate qiime2-2023.5 #&& qiime --help  
		## compatible database : /work/groups/VEO/databases/silva/silva-138-99-nb-classifier.pretrained_directly_downloaded.qza
		## compatible database : /work/groups/VEO/databases/silva/silva-138-99-515-806-nb-classifier.pretrained_directly_downloaded.qza ## Don't use
	 	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh && conda activate qiime2-amplicon-2024.5 #&& qiime --help
		## compatible database : /work/groups/VEO/databases/silva/v2024.5_qiime2/silva-138-99-nb-classifier.qza

	( mkdir -p $raw_files/ ) > /dev/null 2>&1

	manifest="data/manifest.tsv"
	metadata="data/metadata.tsv"
 	cat $parameters | grep -v "##" | awk '/forward-absolute-filepath/ {flag=1} flag {print} /^$/ {flag=0}' | sed 's/ /\t/g' > $manifest
	cat $parameters | grep -v "##" | awk '/group/{flag=1} flag{if (/^$/) exit; print}' | sed 's/ /\t/g' > $metadata
	my_p_min_samples=$( cat $parameters | grep "my_p-min-samples" | awk '{print $2}')
	my_p_min_frequency=$( cat $parameters | grep "my_p-min-frequency" | awk '{print $2}')

	my_p_trim_left_f=$(cat $parameters | grep "my_p-trim-left-f" | awk '{print $2}')
	my_p_trim_left_r=$(cat $parameters | grep "my_p-trim-left-r" | awk '{print $2}')
	my_p_trunc_len_f=$(cat $parameters | grep "my_p-trunc-len-f" | awk '{print $2}')
	my_p_trunc_len_r=$(cat $parameters | grep "my_p-trunc-len-r" | awk '{print $2}')
	classifier=$(cat $parameters | grep "my_database" | awk '{print $2}')
	paired=$(sed -n '2p' $manifest | awk -F'\t' '{print $3}' )

	# sampling_depth=12000

###############################################################################
## step-00b : preparing the database (need only once)

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
## QIIME2
## step-01a: Importing data
	mkdir $raw_files/01_imported_data > /dev/null 2>&1

	# Use the qiime tools import command to import your raw sequencing data into QIIME 2.

	if [ -n "$paired" ]; then
		log "processing paired end files"

		if [ ! -f $raw_files/01_imported_data/demux.qza ] ; then 
			log "STARTED : step-01a : Importing data by qiime2"
			qiime tools import \
			--type 'SampleData[PairedEndSequencesWithQuality]' \
			--input-path $manifest \
			--output-path $raw_files/01_imported_data/demux.qza \
			--input-format PairedEndFastqManifestPhred33V2
			log "ENDED  : step-01a : Importing data by qiime2"
			else
			log "ALREADY FINISHED : step-01a : Importing data by qiime2"
		fi

	else
		log "processing single end files"
		sed -i 's/forward-//g' $manifest
		sed -i 's/reverse-absolute-filepath//g' $manifest
		if [ ! -f $raw_files/01_imported_data/demux.qza ] ; then 
			log "STARTED : step-01a : Importing data by qiime2"
			qiime tools import \
			--type 'SampleData[SequencesWithQuality]' \
			--input-path $manifest \
			--output-path $raw_files/01_imported_data/demux.qza \
			--input-format SingleEndFastqManifestPhred33V2
			log "ENDED  : step-01a : Importing data by qiime2"
			else
			log "ALREADY FINISHED : step-01a : Importing data by qiime2"
		fi 
	fi


## step-01b: Checking the quality of the reads
	if [ ! -f $raw_files/01_imported_data/demux.qza.qzv ] ; then
		log "STARTED : step-01b : Checking the quality of the reads by qiime2"
		qiime demux summarize \
		--i-data $raw_files/01_imported_data/demux.qza \
		--o-visualization $raw_files/01_imported_data/demux.qza.qzv ## will show you the quality of the reads
		log "ENDED : step-01b : Summarize the demultiplexed data by qiime2"
		else
		log "ALREADY FINISHED : step-01b : Checking the quality of the reads by qiime2"
	fi 
	## Visuliase $raw_files/demux.qzv on https://view.qiime2.org/
	## and then decide the cutoff for next step. 
	## There should be atleast 10K reads per sample. 
	## Distribution of eqvivalent number of reads across the samples are good. 
	## read QC>20 is recommended

	## control step-1
	# exit 
###############################################################################
## step-02 : Quality control and denoising
	mkdir $raw_files/02_QC_denoising > /dev/null 2>&1

	# Perform quality control and denoising using the DADA2 or Deblur plugin. 
	# This step involves filtering out low-quality reads, removing chimeric sequences, \
	# and dereplicating sequences to generate amplicon sequence variants (ASVs). = count abundance

	## note the --p-trunc-len-f and --p-trunc-len-f values should not be lower (otherwise there will not be overalps)
	## below step for filtering reads (and its parameter values ) is important, as it results in the final number of reads


	if [ -n "$paired" ]; then
		if [ ! -f $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza ]; then 
			log "STARTED : step-02a : Quality control and denoising by qiime2"
			qiime dada2 denoise-paired \
			--i-demultiplexed-seqs $raw_files/01_imported_data/demux.qza \
			--p-trim-left-f $my_p_trim_left_f \
			--p-trim-left-r $my_p_trim_left_r \
			--p-trunc-len-f $my_p_trunc_len_f \
			--p-trunc-len-r $my_p_trunc_len_r \
			--p-n-threads $SLURM_CPUS_PER_TASK \
			--o-representative-sequences $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza \
			--o-table $raw_files/02_QC_denoising/demux.qza.table-dada2.qza \
			--o-denoising-stats $raw_files/02_QC_denoising/demux.qza.stats-dada2.qza
			log "ENDED : step-02a : Quality control and denoising by qiime2"
			else
			log "ALREADY FINISHED : step-02a : Quality control and denoising by qiime2"
		fi 

		else

		if [ ! -f $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza ]; then 
			log "STARTED : step-02a : Quality control and denoising by qiime2"

			qiime dada2 denoise-single \
			--i-demultiplexed-seqs $raw_files/01_imported_data/demux.qza \
			--p-trim-left $my_p_trim_left_f \
			--p-trunc-len $my_p_trim_left_f \
			--o-representative-sequences $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza \
			--o-table $raw_files/02_QC_denoising/demux.qza.table-dada2.qza \
			--o-denoising-stats $raw_files/02_QC_denoising/demux.qza.stats-dada2.qza
			log "ENDED : step-02a : Quality control and denoising by qiime2"
			else
			log "ALREADY FINISHED : step-02a : Quality control and denoising by qiime2"
		fi
	fi

###############################################################################
## step-03 : FeatureTable and FeatureData summarize
	mkdir $raw_files/03_FeatureTable > /dev/null 2>&1
	if [ ! -f $raw_files/03_FeatureTable/demux.qza.stats-dada2.qza.qzv ] ; then 
		log "STARTED : step-03 : FeatureTable and FeatureData summarize by qiime2"
		qiime feature-table summarize \
		--i-table $raw_files/02_QC_denoising/demux.qza.table-dada2.qza \
		--o-visualization $raw_files/03_FeatureTable/demux.qza.table-dada2.qza.qzv \
		--m-sample-metadata-file $metadata

		qiime feature-table tabulate-seqs \
		--i-data $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza \
		--o-visualization $raw_files/03_FeatureTable/demux.qza.rep-seqs-dada2.qza.qzv

		qiime metadata tabulate \
		--m-input-file $raw_files/02_QC_denoising/demux.qza.stats-dada2.qza \
		--o-visualization $raw_files/03_FeatureTable/demux.qza.stats-dada2.qza.qzv ## important statistics to view

		log "FINISHED : step-03 : FeatureTable and FeatureData summarize by qiime2"
		else
		log "ALREADY FINISHED : step-03 : FeatureTable and FeatureData summarize by qiime2"
	fi 
	## Visuliase $raw_files/demux.qza.stats-dada2.qza.qzv on https://view.qiime2.org/
	## and then decide the cutoff for next step. 

	## control step-2
	# exit 
###############################################################################
## step-04 : Taxonomic classification
	mkdir $raw_files/04_TaxClassif > /dev/null 2>&1
	# Assign taxonomy to the representative sequences using a classifier trained on the 16S rRNA gene sequences. \
	# QIIME 2 provides pre-trained classifiers for various regions of the 16S rRNA gene (e.g., Greengenes, SILVA).

	## @Swapnil: qiime feature-classifier classify-sklearn is time consuming and need resources. 
	## can reduce --p-n-jobs $SLURM_CPUS_PER_TASK to lower the memory requirements

	if [ ! -f $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza.qzv ]; then
		log "STARTED : step-04 : Taxonomic classification by qiime2"
		qiime feature-classifier classify-sklearn \
		--p-n-jobs $SLURM_CPUS_PER_TASK \
		--i-classifier $classifier \
		--i-reads $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza \
		--o-classification $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza

		# summerize taxonomy info
		qiime metadata tabulate \
		--m-input-file $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--o-visualization $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza.qzv

		## export taxonomy info 
		## this will give you the taxonomy (assignment of each id to taxonomic lineage) info in a tsv file
		qiime tools export \
		--input-path $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--output-path $raw_files/04_TaxClassif

		log "ENDED : step-04 : Taxonomic classification by qiime2"
		else
		log "ALREADY FINISHED : step-04 : Taxonomic classification by qiime2"
	fi 

###############################################################################
## step-05 : Remove non-bacterial sequence and singletons
	mkdir $raw_files/05_Filt_NonBacterial_Singletons > /dev/null 2>&1
	# Remove non-bacterial sequences from the feature table and representative sequences.
	# rm -rf $raw_files/*.bacteria_only.*

	## guidelines to choose --pmin-frequency and --p-min-samples
		# 	The ideal values for `--p-min-samples` and `--p-min-frequency` in the QIIME 2 `filter-features` step depend on your specific dataset, research goals, and the characteristics of the microbial community you are studying. However, I can provide some general guidelines:

		# ### 1. `--p-min-samples`:
		# - **Default/Low Stringency (`1`)**: Retains features that are present in at least one sample. This setting is often used when you want to keep as many features as possible, even those that may be rare.
		# - **Moderate Stringency**: You might choose a value that corresponds to a feature being present in a reasonable proportion of your samples (e.g., 5-10% of your samples). For example, if you have 100 samples, setting `--p-min-samples 5` would retain features that appear in at least 5 samples.
		# - **High Stringency**: Use a higher number if you want to focus only on features that are more consistently present across many samples. This might be used when you are interested in more commonly occurring features and want to reduce noise from very rare features.

		# ### 2. `--p-min-frequency`:
		# - **Default/Low Stringency (`1` or `2`)**: By setting this parameter to 1 or 2, you retain features that appear at least once or twice across all samples. This setting is useful if you want to retain very rare features, possibly including those that might be biologically relevant but infrequent.
		# - **Moderate Stringency**: Choose a value that reflects a reasonable level of abundance across your dataset. For example, setting this to 10 or 20 would remove features that are exceptionally rare, helping to reduce noise.
		# - **High Stringency**: Use a higher value (e.g., 50, 100, or more) if you want to focus on features that are more abundant. This could be relevant in studies where you are only interested in the core microbiome or the most abundant members of the community.

		# ### Considerations:
		# - **Dataset Size**: Larger datasets might allow for higher thresholds without losing too many features, while smaller datasets might require lower thresholds to retain sufficient data for analysis.
		# - **Research Goals**: If you are interested in rare taxa, use lower thresholds. If your focus is on dominant community members, higher thresholds are more appropriate.
		# - **Noise Reduction**: Higher thresholds can help in reducing the influence of sequencing noise or contaminants, especially in low-biomass samples.

		# ### Common Practice:
		# - **For Exploratory Analysis**: Start with `--p-min-samples 1` and `--p-min-frequency 2` to retain as much data as possible. Then, adjust based on the initial analysis results.
		# - **For Focused Analysis**: After exploring your data, you may choose to filter more stringently (e.g., `--p-min-samples 10` and `--p-min-frequency 20`), especially if you observe a lot of low-abundance, potentially noisy features.

		# In summary, the ideal numbers for these parameters depend on balancing the retention of biologically meaningful features with the need to reduce noise and focus on the most relevant data for your study. You may need to try a few different values and assess how they impact your downstream analyses.

	if [ ! -f $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.qzv ]; then 
		log "STARTED : step-05 : Remove non-bacterial sequence and singletons by qiime2"

		qiime taxa filter-table \
		--i-table $raw_files/02_QC_denoising/demux.qza.table-dada2.qza \
		--i-taxonomy $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--p-include Bacteria,Archaea \
		--p-exclude eukaryota,mitochondria,chloroplast \
		--o-filtered-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza

		qiime taxa filter-seqs \
		--i-sequences $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza \
		--i-taxonomy $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--p-include Bacteria,Archaea \
		--p-exclude eukaryota,mitochondria,chloroplast \
		--o-filtered-sequences $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza

		## filter samples
		qiime feature-table filter-features \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza \
		--p-min-samples $my_p_min_samples \
		--p-min-frequency $my_p_min_frequency \
		--o-filtered-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza

		## remove singletons sequence
		qiime feature-table filter-seqs \
		--i-data $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--o-filtered-data $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza

		# FeatureTable and FeatureData summarize
		qiime feature-table summarize \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--o-visualization $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.qzv \
		--m-sample-metadata-file $metadata

		qiime feature-table tabulate-seqs \
		--i-data $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza \
		--o-visualization $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.qzv

		log "ENDED : step-05 : Remove non-bacterial sequence and singletons by qiime2"
		else
		log "ALREADY FINISHED : step-05 : Remove non-bacterial sequence and singletons by qiime2"
	fi
 
###############################################################################
## step-06 : Exporting feature-table, tabulate feature-table with taxonomy
	mkdir $raw_files/06_FeatureTable > /dev/null 2>&1
	## raw unfiltered 
	if [ ! -f $raw_files/06_FeatureTable/feature-table-unfiltered.tsv ] ; then 
		log "STARTED : step-06 : Exporting feature-table-filtered.tsv by qiime2" 
		mkdir -p $raw_files/06_FeatureTable/unfiltered
		qiime tools export \
		--input-path $raw_files/02_QC_denoising/demux.qza.table-dada2.qza \
		--output-path $raw_files/06_FeatureTable/unfiltered

		biom convert -i $raw_files/06_FeatureTable/unfiltered/feature-table.biom -o $raw_files/06_FeatureTable/feature-table-unfiltered.tsv --to-tsv
	fi 

	## filtered
	if [ ! -f $raw_files/06_FeatureTable/feature-table-filtered.tsv ] ; then 
		log "STARTED : step-06 : Exporting feature-table-filtered.tsv by qiime2" 
		mkdir -p $raw_files/06_FeatureTable/filtered
		qiime tools export \
		--input-path $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--output-path $raw_files/06_FeatureTable/filtered

		biom convert -i $raw_files/06_FeatureTable/filtered/feature-table.biom -o $raw_files/06_FeatureTable/feature-table-filtered.tsv --to-tsv
	fi 

	## collapsed
	## collpasing combines all the features that have the same taxonomic assignment at a given rank into a single feature
	if [ ! -f $raw_files/06_FeatureTable/feature-table-filtered-collapsed.tsv ] ; then
		qiime taxa collapse \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--i-taxonomy $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--p-level 6 \
		--o-collapsed-table $raw_files/06_FeatureTable/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.collapsed_level6.qza

		qiime tools export \
		--input-path $raw_files/06_FeatureTable/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.collapsed_level6.qza \
		--output-path $raw_files/06_FeatureTable/collapsed_level6

		biom convert -i $raw_files/06_FeatureTable/collapsed_level6/feature-table.biom -o $raw_files/06_FeatureTable/feature-table-filtered-collapsed.tsv --to-tsv
	fi

###############################################################################
## rarefy sequences ?????????????????
###############################################################################
## step-07: Phylogenetic reconstruction (optional but recommended):
	mkdir $raw_files/07_Phylogenetic > /dev/null 2>&1
	# Build a phylogenetic tree from the representative sequences using the qiime phylogeny \
	# align-to-tree-mafft-fasttree or qiime phylogeny align-to-tree-mafft-raxml command. \
	# This step is essential for downstream diversity analyses.

	if [ ! -f $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza ]; then
		log "STARTED : step-07 : Phylogenetic reconstruction by qiime2"
		qiime phylogeny align-to-tree-mafft-fasttree \
		--p-n-threads $SLURM_CPUS_PER_TASK \
		--i-sequences $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza \
		--o-alignment $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.alignment.qza \
		--o-masked-alignment $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.masked-aligned.qza \
		--o-tree $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.tree.qza \
		--o-rooted-tree $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza

		qiime tools export \
		--input-path $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza \
		--output-path $raw_files/07_Phylogenetic/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza.nwk

		log "ENDED : step-07 : Phylogenetic reconstruction by qiime2"
		else
		log "ALREADY FINISHED : step-07 : Phylogenetic reconstruction by qiime2"
	fi 

###############################################################################
## step-08 : Alpha and beta diversity analysis
	mkdir $raw_files/08_Alpha_Beta_Diversity > /dev/null 2>&1
	# Calculate alpha diversity metrics (within-sample diversity) and beta diversity metrics \
	# (between-sample diversity) using various QIIME 2 plugins.
	if [ ! -f $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-emperor.qzv ] ; then
		log "STARTED : step-08 : Alpha and beta diversity analysis by qiime2"

		## alpha diversity
		qiime diversity alpha \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-metric shannon \
		--o-alpha-diversity $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza

		qiime diversity alpha-group-significance \
		--i-alpha-diversity $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza \
		--m-metadata-file $metadata \
		--o-visualization $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qzv

		qiime tools export \
		--input-path $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.shannon-alpha.qza \
		--output-path $raw_files/08_Alpha_Beta_Diversity

		## beta diversity
		qiime diversity beta \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--p-metric braycurtis \
		--o-distance-matrix $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza

		## 240810 enhancement possible for visualisatoin: need manual input
		# qiime diversity beta-group-significance \
		# --i-distance-matrix $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		# --m-metadata-file $metadata \
		# --m-metadata-column TreatmentGroup \
		# --o-visualization $raw_files/08_Alpha_Beta_Diversity/braycurtis-permanova.qzv \
		# --p-method permanova

		qiime tools export \
		--input-path $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		--output-path $raw_files/08_Alpha_Beta_Diversity

		qiime diversity pcoa \
		--i-distance-matrix $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		--o-pcoa $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-pcoa.qza

		qiime emperor plot \
		--i-pcoa $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-pcoa.qza \
		--m-metadata-file $metadata \
		--o-visualization $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-emperor.qzv

		log "ENDED : step-08 : Alpha and beta diversity analysis by qiime2"
		else
		log "ALREADY FINISHED : step-08 : Alpha and beta diversity analysis by qiime2"
	fi 

###############################################################################
## step-09: Generate taxonomic bar plots in QIIME 2
	mkdir $raw_files/09_BarPlot > /dev/null 2>&1
	if [ ! -f $raw_files/09_BarPlot/bar-plot.qzv ] ; then
		log "STARTED : step-09 : Generate taxonomic bar plots in QIIME 2"
		qiime taxa barplot \
		--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
		--i-taxonomy $raw_files/04_TaxClassif/demux.qza.rep-seqs-dada2.qza.taxonomy.qza \
		--m-metadata-file $metadata \
		--o-visualization $raw_files/09_BarPlot/bar-plot.qzv

		qiime tools export \
		--input-path $raw_files/09_BarPlot/bar-plot.qzv \
		--output-path $raw_files/09_BarPlot/bar-plot-exported

		log "ENDED : step-09 : Generate taxonomic bar plots in QIIME 2"
		else
		log "ALREADY FINISHED : step-09 : Generate taxonomic bar plots in QIIME 2"
	fi

###############################################################################
## step-10: pcoa

	if [ ! -f $raw_files/10_pcoa_output/pca_plot.qzv ] ; then
		mkdir $raw_files/10_pcoa_output > /dev/null 2>&1

		# Import Feature Table
		qiime tools import \
		--type 'FeatureTable[Frequency]' \
		--input-path $raw_files/06_FeatureTable/filtered/feature-table.biom \
		--output-path $raw_files/10_pcoa_output/feature-table.qza

		# Import Metadata
		qiime metadata tabulate \
		--m-input-file $metadata \
		--o-visualization $raw_files/10_pcoa_output/metadata.qzv

		# Perform PCoA (on beta diversity)
		qiime diversity pcoa \
		--i-distance-matrix $raw_files/08_Alpha_Beta_Diversity/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza.braycurtis-distance.qza \
		--o-pcoa $raw_files/10_pcoa_output/pcoa.qza

		# Export PCoA Results
		qiime tools export \
		--input-path $raw_files/10_pcoa_output/pcoa.qza \
		--output-path $raw_files/10_pcoa_output

		# Convert Ordination to QZA Format
		qiime tools import \
		--type PCoAResults \
		--input-path $raw_files/10_pcoa_output/ordination.txt \
		--output-path $raw_files/10_pcoa_output/ordination.qza

		# Visualize PCA Plot
		qiime emperor plot \
		--i-pcoa $raw_files/10_pcoa_output/ordination.qza \
		--m-metadata-file $metadata \
		--o-visualization $raw_files/10_pcoa_output/pca_plot.qzv
	fi 
###############################################################################
## step-11: picrust2
	if [ ! -d $raw_files/11_picrust2 ] ; then
		echo "STARTED : step-11 : picrust2"

		qiime picrust2 full-pipeline \
		--i-table $raw_files/02_QC_denoising/demux.qza.table-dada2.qza \
		--i-seq $raw_files/02_QC_denoising/demux.qza.rep-seqs-dada2.qza \
		--output-dir $raw_files/11_picrust2 \
		--p-placement-tool sepp \
		--p-threads $SLURM_CPUS_PER_TASK \
		--p-hsp-method mp \
		--p-max-nsti 2 \
		--verbose

		## ko
		qiime feature-table summarize \
		--i-table $raw_files/11_picrust2/ko_metagenome.qza \
		--o-visualization $raw_files/11_picrust2/ko.qzv

		qiime tools export \
		--input-path $raw_files/11_picrust2/ko_metagenome.qza \
		--output-path $raw_files/11_picrust2/exported_ko

		biom convert -i $raw_files/11_picrust2/exported_ko/feature-table.biom \
		-o $raw_files/11_picrust2/feature-table-ko.tsv --to-tsv

		## ec
		qiime feature-table summarize \
		--i-table $raw_files/11_picrust2/ec_metagenome.qza \
		--o-visualization $raw_files/11_picrust2/ec.qzv

		qiime tools export \
		--input-path $raw_files/11_picrust2/ec_metagenome.qza \
		--output-path $raw_files/11_picrust2/exported_ec

		biom convert -i $raw_files/11_picrust2/exported_ec/feature-table.biom \
		-o $raw_files/11_picrust2/feature-table-ec.tsv --to-tsv

		## pathway
		qiime feature-table summarize \
		--i-table $raw_files/11_picrust2/pathway_abundance.qza \
		--o-visualization $raw_files/11_picrust2/pathway_abundance.qzv

		qiime tools export \
		--input-path $raw_files/11_picrust2/pathway_abundance.qza \
		--output-path $raw_files/11_picrust2/exported_pathway_abundance

		biom convert -i $raw_files/11_picrust2/exported_pathway_abundance/feature-table.biom \
		-o $raw_files/11_picrust2/feature-table-pathway_abundance.tsv --to-tsv

		## 240811 enhacenment possible
		## If you are interested in specific KEGG Orthologs (KOs) or pathways, you can filter the feature table:
			# qiime feature-table filter-features \
			# --i-table $raw_files/11_picrust2/pathway_abundance.qza \
			# --m-metadata-file pathway-of-interest.tsv \
			# --o-filtered-table $raw_files/11_picrust2/filtered_pathway_abundance.qza

			# qiime composition ancom \
			# --i-table $raw_files/11_picrust2/pathway_abundance.qza \
			# --m-metadata-file $metadata \
			# --m-metadata-column age \
			# --o-visualization $raw_files/11_picrust2/ancom_pathway_abundance.qzv

			# qiime composition ancom \
			# --i-table $raw_files/11_picrust2/pathway_abundance.qza \
			# --m-metadata-file $metadata \
			# --m-metadata-column group \
			# --o-visualization $raw_files/11_picrust2/ancom_pathway_abundance.qzv

		echo "ENDED : step-11 : picrust2"
		else
		log "ALREADY FINISHED : step-11 : picrust2"
	fi

###############################################################################

	## step-09 : core-metrics-phylogenetic (optional)
		# if [ ! -f $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv ] ; then
		# 	log "STARTED : step-09 : core-metrics-phylogenetic by qiime2"
		# 	mkdir $wd/core_metrics_results

		# 	qiime diversity core-metrics-phylogenetic \
		# 	--i-phylogeny $raw_files/demux.qza.rep-seqs-dada2.qza.bacteria_only.qza.singleton_filtered_seq.qza.rooted-tree.qza \
		# 	--i-table $raw_files/05_Filt_NonBacterial_Singletons/demux.qza.table-dada2.qza.bacteria_only.qza.singleton_filtered-table.qza \
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

		# 	log "ENDED : step-09 : core-metrics-phylogenetic by qiime2"
		# 	else
		# 	log "ALREADY FINISHED : step-09 : core-metrics-phylogenetic by qiime2"
		# fi


	## OPTIONAL : pcoa plot 
	## need specific metadata file for this step
		# if [ ! -f $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv.png ] ; then 
		# 	log "RUNNING : step-11 : customised pcoa plot by a custom-python script"
		# 	python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0771_amplicon_sequence_analysis_by_qiime2.pcoa.py \
		# 	--matrix_file $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv \
		# 	--metadata_file $metadata \
		# 	--output $wd/core_metrics_results/bray_curtis_distance_matrix/distance-matrix.tsv.png
		# 	log "ENDED : step-11 : customised pcoa plot by a custom-python script"
		# 	else
		# 	log "ALREADY FINISHED : step-11 : customised pcoa plot by a custom-python script"
		# fi 

	## incomplete barplot script /home/groups/VEO/scripts_for_users/supplementary_scripts/0771_amplicon_sequence_analysis_by_qiime2.barplot.py

###############################################################################
# email
	# echo "sending email"
    # user=$(whoami)
    user_email=$(grep xa73pav /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/$pipeline.py -e $user_email

    deactivate
###############################################################################
## footer
	log "ENDED: 0771_amplicon_sequence_analysis_by_qiime2 -----------------------------"
###############################################################################
## refrences: https://www.youtube.com/watch?v=RcdTZE8VbJg&list=PLOCEVoX6zu2Ii8RD7i9Oi7Pbot_5WF08n&ab_channel=InstituteforSystemsBiology

