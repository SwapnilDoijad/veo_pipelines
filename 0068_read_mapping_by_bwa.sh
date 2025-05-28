#!/bin/bash
###############################################################################  
## header
    pipeline=0068_read_mapping_by_bwa
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ----------------------------------"
##############################################################################  
## step-01: preparations
    SNP_analysis=$(grep -w "my_SNP_analysis" $parameters | awk '{print $2}')

    (rm $wd/tmp/slurm/*.$pipeline.txt ) > /dev/null 2>&1
    (rm $wd/tmp/sbatch/$pipeline.*.sbatch ) > /dev/null 2>&1
    (rm $wd/summary.txt ) > /dev/null 2>&1

    (mkdir -p $raw_files/index_files ) > /dev/null 2>&1
    (mkdir -p $raw_files/sam_files ) > /dev/null 2>&1
    (mkdir -p $raw_files/sam_files_sorted ) > /dev/null 2>&1
    (mkdir -p $raw_files/depth_and_coverage ) > /dev/null 2>&1

    if [ $SNP_analysis == "Yes" ]; then
        (mkdir -p $raw_files/consensus_sequences ) > /dev/null 2>&1
        (mkdir -p $raw_files/mpileup ) > /dev/null 2>&1
        (mkdir -p $raw_files/vcf ) > /dev/null 2>&1
        (mkdir -p $raw_files/InsDel ) > /dev/null 2>&1
        (mkdir -p $raw_files/tmp ) > /dev/null 2>&1

        echo -e "#ID\tCHROM\tPOS\tREF\tALT\tQUAL\tTotal_Reads_Mapped\tReads_Supporting_ALT\tReads_Supporting_REF\tSNP_Type\tAllele_Frequency\tRead_Depth_per_Base\tQualRef\tQualAllel\tSNP_Annotation" > $raw_files/summary.InsDel.tsv
        echo "#ID	CHROM	POS	ID	REF	ALT	QUAL	FILTER	AB	ABP	AC	AF	AN	AO	CIGAR	DP	DPB	DPRA	EPP	EPPR	GTI	LEN	MEANALT	MQM	MQMR	NS	NUMALT	ODDS	PAIRED	PAIREDR	PAO	PQA	PQR	PRO	QA	QR	RO	RPL	RPP	RPPR	RPR	RUN	SAF	SAP	SAR	SRF	SRP	SRR	TYPE	AD	AO	DP	GT	PL	QA	QR	RO" | tr ' ' '\t' > $raw_files/summary.InsDel.unfiltered.tsv
    fi

    create_directories_structure_1 $wd

    data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')
    if [ $data_type == "paired" ]; then
        awk '/reverse_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/paired.txt
        list=$wd/tmp/paired.txt
        elif [ $data_type == "single" ]; then
        awk '/single_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/single.txt
        list=$wd/tmp/single.txt
    fi

    snp_annotation=$(grep -w "my_snp_annotation" $parameters | awk '{print $2}')
    if [ $snp_annotation == "Yes" ]; then
        awk '/genBank_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/genBank_filepath.txt
    fi

    split_list $wd $list
    submit_jobs $wd $pipeline

###############################################################################
## footer
    log "ENDED : $pipeline ----------------------------------"
###############################################################################