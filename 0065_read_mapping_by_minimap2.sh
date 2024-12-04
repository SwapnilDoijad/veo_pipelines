#!/bin/bash
############################################################################### 
## header
    pipeline=0065_read_mapping_by_minimap2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ----------------------------------"
##############################################################################  
## step-01: preparations

    (rm $wd/tmp/slurm/*.$pipeline.txt ) > /dev/null 2>&1
    (rm $wd/tmp/sbatch/$pipeline.*.sbatch ) > /dev/null 2>&1
    (rm $wd/summary.txt ) > /dev/null 2>&1

    (mkdir -p $raw_files/index_files ) > /dev/null 2>&1
    (mkdir -p $raw_files/sam_files ) > /dev/null 2>&1
    (mkdir -p $raw_files/sam_files_sorted ) > /dev/null 2>&1
    (mkdir -p $raw_files/depth_and_coverage ) > /dev/null 2>&1
    (mkdir -p $raw_files/consensus_sequences ) > /dev/null 2>&1
    (mkdir -p $raw_files/mpileup ) > /dev/null 2>&1
    (mkdir -p $raw_files/vcf ) > /dev/null 2>&1
    (mkdir -p $raw_files/InsDel ) > /dev/null 2>&1
    echo -e "#ID\tCHROM\tPOS\tREF\tALT\tQUAL\tTotal_Reads_Mapped\tReads_Supporting_ALT\tReads_Supporting_REF\tSNP_Type\tAllele_Frequency\tRead_Depth_per_Base\tQualRef\tQualAllel\tSNP_Annotation" > $raw_files/summary.InsDel.tsv
    echo "#ID	CHROM	POS	ID	REF	ALT	QUAL	FILTER	AB	ABP	AC	AF	AN	AO	CIGAR	DP	DPB	DPRA	EPP	EPPR	GTI	LEN	MEANALT	MQM	MQMR	NS	NUMALT	ODDS	PAIRED	PAIREDR	PAO	PQA	PQR	PRO	QA	QR	RO	RPL	RPP	RPPR	RPR	RUN	SAF	SAP	SAR	SRF	SRP	SRR	TYPE	AD	AO	DP	GT	PL	QA	QR	RO" | tr ' ' '\t' > $raw_files/summary.InsDel.unfiltered.tsv

    ## @Swapnil need to update to use the parameter file  
    ## convert_GenBank_to_GFF3_and_FASTA
    ## the names should be genes.gff and sequence.fa for snpEff to work, DON'T change 
    mkdir -p results/0065_read_mapping_by_minimap2/tmp/ref_tmp > /dev/null 2>&1
    source /home/groups/VEO/tools/biopython/myenv/bin/activate
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_GenBank_to_GFF3_and_FASTA.py \
        -i data/MN988491_1_Rhizobium_phage_RHph_Y3_36.gb \
        -g results/0065_read_mapping_by_minimap2/tmp/ref_tmp/genes.gff \
        -f results/0065_read_mapping_by_minimap2/tmp/ref_tmp/sequences.fa
    deactivate
    sed -i 's/MN988491.1 Rhizobium phage RHph_Y3_36, complete genome/MN988491_1_Rhizobium_phage_RHph_Y3_36_complete_genome/' results/0065_read_mapping_by_minimap2/tmp/ref_tmp/sequences.fa
    sed -i 's/MN988491\.1/MN988491_1_Rhizobium_phage_RHph_Y3_36_complete_genome/g' results/0065_read_mapping_by_minimap2/tmp/ref_tmp/genes.gff

    ## @Swapnil /home/xa73pav/projects/p_wallapat_phage/results/0065_read_mapping_by_minimap2/tmp/snpEff.config copy file from old
    cp snpEff.config results/0065_read_mapping_by_minimap2/tmp/
    ## need to update the codes 
    java -jar /home/groups/VEO/tools/snpeff/v5.2c/snpEff/snpEff.jar build \
    -gff3 -v \
    -dataDir /home/xa73pav/projects/p_wallapat_phage/results/0065_read_mapping_by_minimap2/tmp/ \
    -c /home/xa73pav/projects/p_wallapat_phage/results/0065_read_mapping_by_minimap2/tmp/snpEff.config \
    ref_tmp

    create_directories_structure_1 $wd

    data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')
    if [ $data_type == "paired" ]; then
        awk '/reverse_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/paired.txt
        list=$wd/tmp/paired.txt
        elif [ $data_type == "single" ]; then
        awk '/single_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > $wd/tmp/single.txt
        list=$wd/tmp/single.txt
    fi

    split_list $wd $list
    submit_jobs $wd $pipeline

############################################################################### 
## create and submit sbatch

    # for sublist in $( ls $wd/tmp/lists/ ); do 
    #     echo "creating sbatch for $sublist, and submitting"
    #     sed "s/ABC/$sublist/g" /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch \
    #     > $wd/tmp/sbatch/$pipeline.$sublist.sbatch
    #     sbatch $wd/tmp/sbatch/$pipeline.$sublist.sbatch
    # done

    # number_of_sublist=$(ls $wd/tmp/lists/ | wc -l)
    # while [ "$number_of_sublist" != "$number_of_sublist_finished" ]; do
    #     sleep 300
    #     number_of_sublist_finished=$( grep -c "The run for sublist :" $wd/tmp/slurm/*.out.$pipeline.txt  | wc -l )
    #     echo "$number_of_sublist_finished/$number_of_sublist finished by now, waiting for 5 min" 
    # done 

###############################################################################
## step-03: send report by email (with attachment)

    # echo "sending email"
    # user=$(whoami)
    # user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    # source /home/groups/VEO/tools/email/myenv/bin/activate

    # python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0065_metagenome_assembly_by_raven.py -e $user_email

    # deactivate

###############################################################################
## footer
    log "ENDED : $pipeline ----------------------------------"
###############################################################################