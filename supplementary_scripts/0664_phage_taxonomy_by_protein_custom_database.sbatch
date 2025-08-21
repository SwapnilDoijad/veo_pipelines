#!/bin/bash
#SBATCH --job-name=0664_phage_taxonomy_by_protein_custom_database
#SBATCH --partition=standard,long
#SBATCH --output=results/0664_phage_taxonomy_by_protein_custom_database/tmp/slurm/%j.out
#SBATCH --error=results/0664_phage_taxonomy_by_protein_custom_database/tmp/slurm/%j.err
#SBATCH --mem=100G
#SBATCH --cpus-per-task=40
###############################################################################
## header
	pipeline=0664_phage_taxonomy_by_protein_custom_database
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_directory=$( grep my_fasta_dir $parameters | awk '{print $2}' )
	sublist=$wd/tmp/lists/ABC

	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate ictv_mmseq2_v250814
	export PATH=/home/groups/VEO/tools/mmseq/v17-b804f/mmseqs/bin/:$PATH
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: first time-database setup 
	# log "DOWNLOADING: ictv.xlsx"
	# aria2c \
	# -x 4 \
	# -o ictv.xlsx \
	# "https://ictv.global/vmr/current?fid=15873" \
	# --check-certificate=false
	# mv ictv.xlsx /veodata/03/databases/ictv/0664_ictv.xlsx

	# log "DOWNLOADING: assembly_summary_genbank.tsv"
	# aria2c \
	# -x 4 \
	# -o assembly_summary_genbank.tsv \
	# "https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_genbank.txt" \
	# --check-certificate=false
	# mv assembly_summary_genbank.tsv /veodata/03/databases/ictv/0664_assembly_summary_genbank.tsv

	# log "DOWNLOADING: assembly_summary_refseq.tsv"
	# aria2c \
	# -x 4 \
	# -o assembly_summary_refseq.tsv \
	# "https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_refseq.txt" \
	# --check-certificate=false
	# mv assembly_summary_refseq.tsv /veodata/03/databases/ictv/0664_assembly_summary_refseq.tsv

	# log "CONVERTING: ictv.xlsx to ictv.tsv"
	# csvtk xlsx2csv /veodata/03/databases/ictv/0664_ictv.xlsx \
    # | csvtk csv2tab \
    # | sed 's/\xc2\xa0/ /g' \
    # | csvtk replace -t -F -f "*" -p "^\s+|\s+$" \
    # > /veodata/03/databases/ictv/0664_ictv.tsv

	# log "CONVERTING: ictv.tsv to ictv.taxonomy.tsv"
	# csvtk cut -t -f "Realm,Subrealm,Kingdom,Subkingdom,Phylum,Subphylum,Class,Subclass,Order,Suborder,Family,Subfamily,Genus,Subgenus,Species" /veodata/03/databases/ictv/0664_ictv.tsv \
    # | csvtk uniq -t -f "Realm,Subrealm,Kingdom,Subkingdom,Phylum,Subphylum,Class,Subclass,Order,Suborder,Family,Subfamily,Genus,Subgenus,Species" \
    # | csvtk del-header -t \
    # > /veodata/03/databases/ictv/0664_ictv.taxonomy.tsv

	# log "CREATING: ictv.names.txt"
	# csvtk cut -t -H -f 1,3,5,7,9,11,13,15 \
	# /veodata/03/databases/ictv/0664_ictv.taxonomy.tsv \
    # | sed 's/\t/\n/g' \
    # | awk '!/^[[:blank:]]*$/' \
    # | sort -u \
    # > ictv.names.txt
	# mv ictv.names.txt /veodata/03/databases/ictv/0664_ictv.names.txt

	# log "DOWNLOADING: taxdump.tar.gz"
	# mkdir -p /veodata/03/databases/ictv/0064_taxdump
	# aria2c -x 4 -o taxdump.tar.gz  ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
	# tar -xzf taxdump.tar.gz -C /veodata/03/databases/ictv/0064_taxdump

	# log "CREATING: ictv-taxdump"
	# export TAXONKIT_DB=/veodata/03/databases/ictv/0064_taxdump
	# taxonkit create-taxdump -K 1 -P 3 -C 5 -O 7 -F 9 -G 11 -S 13 -T 15 \
    # --rank-names "realm","kingdom","phylum","class","order","family","genus","species" \
	# /veodata/03/databases/ictv/0664_ictv.taxonomy.tsv \
	# --out-dir /veodata/03/databases/ictv/0064_taxdump/ictv-taxdump --force

	# python3 $suppl_scripts/$pipeline.fix_taxdump.py \
	# --input-dir /veodata/03/databases/ictv/0064_taxdump/ictv-taxdump \
	# --output-dir /veodata/03/databases/ictv/0064_taxdump/ictv-taxdump

	# log "DOWNLOADING: taxdump.tar.gz"
	# mkdir -p /veodata/03/databases/ictv/0064_taxdump/ncbi-taxdump
	# aria2c -x 4 "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz" --check-certificate=false
	# tar zxfv taxdump.tar.gz -C /veodata/03/databases/ictv/0064_taxdump/ncbi-taxdump
	# rm taxdump.tar.gz

	## log "DOWNLOADING: prot.accession2taxid.FULL.gz"
	# aria2c -x 4 "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.gz" --check-certificate=false
	# gunzip -c prot.accession2taxid.FULL.gz > /veodata/03/databases/ictv/0064_protein/prot.accession2taxid.FULL


	## log "DOWNLOADING: faa files for viruses"
	# mkdir -p /veodata/03/databases/ictv/0064_protein
	# python3 $suppl_scripts/$pipeline.ncbi_download.py \
	# --refseq /veodata/03/databases/ictv/0664_assembly_summary_genbank.tsv \
	# --genbank /veodata/03/databases/ictv/0664_assembly_summary_refseq.tsv \
	# --output /veodata/03/databases/ictv/0064_proteins \
	# --threads 6

	log "STARTING: 0664_phage_taxonomy_by_protein_custom_database.ProcessProteinSeq"
	python $suppl_scripts/$pipeline.ProcessProteinSeq.py \
	--proteins_dir /veodata/03/databases/ictv/0064_proteins \
	--output_fasta /veodata/03/databases/ictv/0064_concatenated_proteins.fasta \
	--output_tsv /veodata/03/databases/ictv/0064_virus.accession2taxid.tsv
###############################################################################
	log "FINISHED: $pipeline -----------------------------" ## && clean
###############################################################################

