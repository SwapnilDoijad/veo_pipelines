#!/bin/bash
#SBATCH --job-name=0664_phage_taxonomy_by_protein_custom_database
#SBATCH --partition=long,standard
#SBATCH --output=results/0664_phage_taxonomy_by_protein_custom_database/tmp/slurm/%j.out
#SBATCH --error=results/0664_phage_taxonomy_by_protein_custom_database/tmp/slurm/%j.err
#SBATCH --mem=125G
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
	seqkit="/home/groups/VEO/tools/seqkit/v2.8.2/seqkit"
	mmseqs="/home/groups/VEO/tools/mmseq/v17-b804f/mmseqs/bin/mmseqs"
###############################################################################
	log "STARTED: $pipeline -----------------------------"
###############################################################################
## step-01: database creation

	log "DOWNLOADING: ictv.xlsx"

	setsid \
	aria2c \
	-x 4 \
	-o ictv.xlsx \
	"https://ictv.global/vmr/current?fid=15873" \
	--check-certificate=false \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/aria2v.ictv.tsv 1

	mv ictv.xlsx /veodata/03/databases/ictv/0664_ictv.xlsx 

	log "DOWNLOADING: assembly_summary_genbank.tsv"
	setsid \
	aria2c \
	-x 4 \
	-o assembly_summary_genbank.tsv \
	"https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_genbank.txt" \
	--check-certificate=false \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/aria2c.assembly_summary_genbank.tsv 1

	mv assembly_summary_genbank.tsv /veodata/03/databases/ictv/0664_assembly_summary_genbank.tsv

	log "DOWNLOADING: assembly_summary_refseq.tsv"
	setsid \
	aria2c \
	-x 4 \
	-o assembly_summary_refseq.tsv \
	"https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_refseq.txt" \
	--check-certificate=false \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/aria2c.assembly_summary_refseq.tsv 1

	mv assembly_summary_refseq.tsv /veodata/03/databases/ictv/0664_assembly_summary_refseq.tsv 

	log "CONVERTING: ictv.xlsx to ictv.tsv"
	setsid \
	csvtk xlsx2csv -i 2 /veodata/03/databases/ictv/0664_ictv.xlsx \
    | csvtk csv2tab \
    | sed 's/\xc2\xa0/ /g' \
    | csvtk replace -t -F -f "*" -p "^\s+|\s+$" \
    > /veodata/03/databases/ictv/0664_ictv.tsv \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/csvtk.xlsx2csv.ictv.tsv 1

	log "CONVERTING: ictv.tsv to ictv.taxonomy.tsv"
	setsid \
	csvtk cut -t -f "Realm,Subrealm,Kingdom,Subkingdom,Phylum,Subphylum,Class,Subclass,Order,Suborder,Family,Subfamily,Genus,Subgenus,Species" /veodata/03/databases/ictv/0664_ictv.tsv \
    | csvtk uniq -t -f "Realm,Subrealm,Kingdom,Subkingdom,Phylum,Subphylum,Class,Subclass,Order,Suborder,Family,Subfamily,Genus,Subgenus,Species" \
    | csvtk del-header -t \
    > /veodata/03/databases/ictv/0664_ictv.taxonomy.tsv \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/csvtk.cut1.ictv.taxonomy.tsv 1

	log "CREATING: ictv.names.txt"
	setsid \
	csvtk cut -t -H -f 1,3,5,7,9,11,13,15 \
	/veodata/03/databases/ictv/0664_ictv.taxonomy.tsv \
    | sed 's/\t/\n/g' \
    | awk '!/^[[:blank:]]*$/' \
    | sort -u \
    > ictv.names.txt  \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/csvtk.cut2.ictv.names.txt.tsv 1

	mv ictv.names.txt /veodata/03/databases/ictv/0664_ictv.names.txt

	log "DOWNLOADING: taxdump.tar.gz"
	mkdir -p /veodata/03/databases/ictv/0664_taxdump

	setsid \
	aria2c -x 4 -o taxdump.tar.gz  ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/aria2c.taxdump.tar.gz.tsv 1	

	tar -xzf taxdump.tar.gz -C /veodata/03/databases/ictv/0664_taxdump  

	log "CREATING: ictv-taxdump"
	export TAXONKIT_DB=/veodata/03/databases/ictv/0664_taxdump
	setsid \
	taxonkit create-taxdump -K 1 -P 3 -C 5 -O 7 -F 9 -G 11 -S 13 -T 15 \
    --rank-names "realm","kingdom","phylum","class","order","family","genus","species" \
	/veodata/03/databases/ictv/0664_ictv.taxonomy.tsv \
	--out-dir /veodata/03/databases/ictv/0664_taxdump/taxdump --force \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/taxonkit.create-taxdump.tsv 1	

	setsid \
	python3 $suppl_scripts/$pipeline.fix_taxdump.py \
	--input-dir /veodata/03/databases/ictv/0664_taxdump/ictv-taxdump \
	--output-dir /veodata/03/databases/ictv/0664_taxdump/ictv-taxdump \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/fix_taxdump.tsv 1

	log "DOWNLOADING: taxdump.tar.gz"
	mkdir -p /veodata/03/databases/ictv/0664_taxdump/ncbi-taxdump

	setsid \
	aria2c -x 4 "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz" --check-certificate=false
	tar zxfv taxdump.tar.gz -C /veodata/03/databases/ictv/0664_taxdump/ncbi-taxdump \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/aria2c.ncbi-taxdump.tsv 1

	rm taxdump.tar.gz 

	log "DOWNLOADING: prot.accession2taxid.FULL.gz"
	setsid \
	aria2c -x 4 "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.FULL.gz" --check-certificate=false \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/aria2c.accession2taxid.FULL.gz.tsv 1

	gunzip -c prot.accession2taxid.FULL.gz > /veodata/03/databases/ictv/0664_prot.accession2taxid.FULL 

	log "DOWNLOADING: faa files for viruses"
	mkdir -p /veodata/03/databases/ictv/0664_protein
	setsid \
	python3 $suppl_scripts/$pipeline.ncbi_download.py \
	--refseq /veodata/03/databases/ictv/0664_assembly_summary_genbank.tsv \
	--genbank /veodata/03/databases/ictv/0664_assembly_summary_refseq.tsv \
	--output /veodata/03/databases/ictv/0664_proteins \
	--threads $SLURM_CPUS_PER_TASK \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/ncbi_download.tsv 1

	log "STARTING: 0664_phage_taxonomy_by_protein_custom_database.ProcessProteinSeq"
	setsid \
	python $suppl_scripts/$pipeline.ProcessProteinSeq.py \
	--proteins_dir /veodata/03/databases/ictv/0664_proteins \
	--output_fasta /veodata/03/databases/ictv/0664_concatenated_proteins.fasta \
	--output_tsv /veodata/03/databases/ictv/0664_virus.accession2taxid.tsv \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/ProcessProteinSeq.tsv 1

	log "CREATING: /veodata/03/databases/ictv/0664_virus_taxid.list"
	setsid \
	awk '{print $2}' \
	/veodata/03/databases/ictv/0664_prot.accession2taxid.FULL \
    | sort -u \
    | taxonkit \
	--data-dir /veodata/03/databases/ictv/0664_taxdump/ncbi-taxdump \
	lineage \
    | rg "\tViruses;" \
    | awk '{print $1}' \
    > /veodata/03/databases/ictv/0664_virus_taxid.list \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/awk.0664_virus_taxid.tsv 1

	log "CREATING: /veodata/03/databases/ictv/0664_virus.accession2taxid"
	setsid \
	csvtk grep --quiet -t -f 2 \
	-P /veodata/03/databases/ictv/0664_virus_taxid.list \
	/veodata/03/databases/ictv/0664_prot.accession2taxid.FULL \
	> /veodata/03/databases/ictv/0664_virus.accession2taxid \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/csvtk.grep.0664_virus.accession2taxid.tsv 1

	log "STARTING: $pipeline.virus.accession2taxid.ictv"
	setsid \
	python $suppl_scripts/$pipeline.virus.accession2taxid.ictv.py \
    --ictv_names /veodata/03/databases/ictv/0664_ictv.names.txt \
    --ncbi_nodes /veodata/03/databases/ictv/0664_taxdump/ncbi-taxdump/nodes.dmp \
    --ncbi_names /veodata/03/databases/ictv/0664_taxdump/ncbi-taxdump/names.dmp \
    --ncbi_merged /veodata/03/databases/ictv/0664_taxdump/ncbi-taxdump/merged.dmp \
    --ictv_nodes /veodata/03/databases/ictv/0664_taxdump/ictv-taxdump/nodes.dmp \
    --ictv_names_dmp /veodata/03/databases/ictv/0664_taxdump/ictv-taxdump/names.dmp \
    --accession_file /veodata/03/databases/ictv/0664_virus.accession2taxid.tsv \
    --output_file /veodata/03/databases/ictv/0664_virus.accession2taxid.ictv \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/0664_virus.accession2taxid.ictv.tsv 1

	## Create a list containing the accessions of the proteins of ICTV viruses
	setsid \
	cut -f 1 /veodata/03/databases/ictv/0664_virus.accession2taxid.ictv \
	> /veodata/03/databases/ictv/0664_virus.accession.txt \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/cut.0664_virus.accession.txt.tsv 1

	## Filter the NR proteins to keep the proteins encoded by ICTV viruses
	$seqkit \
	grep -j 4 -f /veodata/03/databases/ictv/0664_virus.accession.txt \
	/veodata/03/databases/ictv/0664_concatenated_proteins.fasta \
	| $seqkit \
	seq -i -w 0 -o /veodata/03/databases/ictv/0664_nr.virus.faa.gz \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/seqkit.0664_nr.virus.faa.gz.tsv 1

	setsid \
	$seqkit \
	fx2tab \
	-n \
	-i /veodata/03/databases/ictv/0664_nr.virus.faa.gz \
	> /veodata/03/databases/ictv/0664_nr.virus.list.txt \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/seqkit.fx2tab.tsv 1	

	setsid \
	csvtk grep \
	-t -H -f 1 \
	-P /veodata/03/databases/ictv/0664_nr.virus.list.txt \
	/veodata/03/databases/ictv/0664_virus.accession2taxid.ictv \
	> /veodata/03/databases/ictv/0664_nr.virus.accession2taxid.ictv \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/csvtk.grep.virus.accession2taxid.tsv 1

	setsid \
	mkdir -p /veodata/03/databases/ictv/0664_ictv
	$mmseqs \
	createdb --dbtype 1 /veodata/03/databases/ictv/0664_nr.virus.faa.gz \
	/veodata/03/databases/ictv/0664_ictv/virus_tax_db \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/mmseqs.createdb.0664_nr.virus.faa.gz.tsv 1

	setsid \
	$mmseqs \
	createtaxdb /veodata/03/databases/ictv/0664_ictv/virus_tax_db \
	tmp \
	--ncbi-tax-dump /veodata/03/databases/ictv/0664_taxdump/ictv-taxdump \
	--tax-mapping-file /veodata/03/databases/ictv/0664_nr.virus.accession2taxid.ictv \
	& my_pid=$!
	pgid=$(ps -o pgid= -p $my_pid | tr -d ' ')
	accurate_log_usage_by_pgid "$pgid" ${resource_log}/mmseqs.createtaxdb.0664_ictv.tsv 1

###############################################################################
## step-02: actual taxonomical classificatio steps 
		# find $fasta_directory/ -name "*.fasta" -print0 \
		# | xargs -0 /home/groups/VEO/tools/seqkit/v2.8.2/seqkit stats \
		# > $raw_files/stats.info \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/0664.seqkit.stats.tsv

		# $mmseqs \
		# createdb data/combined_fasta/all59907.fasta \
		# $raw_files/mmdb \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/0664.mmseq.createdb.all59907.tsv

		# mkdir $raw_files/taxonomy_results
		# $mmseqs \
		# taxonomy \
		# $raw_files/mmdb \
		# /veodata/03/databases/ictv/0664_ictv/virus_tax_db \
		# $raw_files/taxonomy_results/resdb2 \
		# tmp -e 0.001 -s 7 --blacklist "" \
		# --tax-lineage 1 --threads 14 \
		# --lca-ranks superkingdom,kingdom,subkingdom,superphylum,phylum,subphylum,class,subclass,order,suborder,family,subfamily,genus,subgenus,species \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/0664.mmseq.taxonomy.all59907.tsv

			# depreceated
				# $mmseqs \
				# createtsv \
				# $raw_files/taxonomy_results/resdb2 \
				# $raw_files/taxonomyResult.tsv \
				# & my_pid=$!
				# get_resource_stat $my_pid $resource_log/0664.mmseq.createtsv.all59907.tsv
			# above did not work, so run below, as suggested by chatGPT

		# $mmseqs \
		# createtsv \
		# $raw_files/mmdb \
		# /veodata/03/databases/ictv/0664_ictv/virus_tax_db \
		# $raw_files/taxonomy_results/resdb2 \
		# $raw_files/taxonomyResult.tsv \
		# & my_pid=$!
		# get_resource_stat $my_pid $resource_log/0664.mmseq.createtsv.all59907.tsv

		python3 $suppl_scripts/0664_phage_taxonomy_by_protein_custom_database.format.py \
		--taxonomy-result $raw_files/taxonomyResult.tsv \
		--ictv-vmr /veodata/03/databases/ictv/0664_ictv.tsv \
		--fasta $fasta_directory/all59907.fasta \
		--out $raw_files/submission_ictv.csv \
		& my_pid=$!
		get_resource_stat $my_pid $resource_log/0664.format.all59907.tsv

###############################################################################
	log "FINISHED: $pipeline -----------------------------" ## && clean
###############################################################################


mmseqs taxonomy mmdb virus_tax_db resdb2 tmp -e 0.001 -s 7 --blacklist "" --tax-lineage 1 --threads 14 --lca-ranks superkingdom,kingdom,subkingdom,superphylum,phylum,subphylum,class,subclass,order,suborder,family,subfamily,genus,subgenus,species 