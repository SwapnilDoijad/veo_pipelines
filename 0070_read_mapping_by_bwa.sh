#!/bin/bash
###############################################################################  
## header
pipeline=0070_read_mapping_by_bwa
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
log "STARTED : $pipeline ----------------------------------"
##############################################################################  
echo "Swapnil: parameters are for the SORGHUM genome"
## step-01: preparations

# Safely extract parameters
SNP_analysis=$(grep -w "my_SNP_analysis" $parameters | awk '{print $2}')
data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')
snp_annotation=$(grep -w "my_snp_annotation" $parameters | awk '{print $2}')

# Debug (optional but useful)
log "Parameters → data_type: $data_type | SNP_analysis: $SNP_analysis | snp_annotation: $snp_annotation"

# Clean old files safely
rm -f $wd/tmp/slurm/*.$pipeline.txt 2>/dev/null
rm -f $wd/tmp/sbatch/$pipeline.*.sbatch 2>/dev/null
rm -f $wd/summary.txt 2>/dev/null

# Create required directories
mkdir -p $raw_files/index_files
mkdir -p $raw_files/sam_files
mkdir -p $raw_files/sam_files_sorted
mkdir -p $raw_files/depth_and_coverage

###############################################################################
#SNP-related directories
###############################################################################
if [ "$SNP_analysis" == "Yes" ]; then
    mkdir -p $raw_files/consensus_sequences
    mkdir -p $raw_files/mpileup
    mkdir -p $raw_files/vcf
    mkdir -p $raw_files/InsDel
    mkdir -p $raw_files/tmp

    echo -e "#ID\tCHROM\tPOS\tREF\tALT\tQUAL\tTotal_Reads_Mapped\tReads_Supporting_ALT\tReads_Supporting_REF\tSNP_Type\tAllele_Frequency\tRead_Depth_per_Base\tQualRef\tQualAllel\tSNP_Annotation" \
        > $raw_files/summary.InsDel.tsv

    echo "#ID CHROM POS ID REF ALT QUAL FILTER AB ABP AC AF AN AO CIGAR DP DPB DPRA EPP EPPR GTI LEN MEANALT MQM MQMR NS NUMALT ODDS PAIRED PAIREDR PAO PQA PQR PRO QA QR RO RPL RPP RPPR RPR RUN SAF SAP SAR SRF SRP SRR TYPE AD AO DP GT PL QA QR RO" \
        | tr ' ' '\t' > $raw_files/summary.InsDel.unfiltered.tsv
fi

create_directories_structure_1 $wd

###############################################################################
#Parse input list (paired vs single)
###############################################################################
if [ "$data_type" == "paired" ]; then
    awk '/reverse_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' \
        $parameters > $wd/tmp/paired.txt
    list=$wd/tmp/paired.txt

elif [ "$data_type" == "single" ]; then
    awk '/single_fastq_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' \
        $parameters > $wd/tmp/single.txt
    list=$wd/tmp/single.txt

else
    log "ERROR: my_data_type must be 'paired' or 'single'"
    exit 1
fi

###############################################################################
#Parse GenBank mapping (only if annotation enabled)
###############################################################################
if [ "$snp_annotation" == "Yes" ]; then
    awk '/genBank_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' \
        $parameters > $wd/tmp/genBank_filepath.txt
fi

###############################################################################
# index (Note: if there is one reference, it will be indexed only once)
###############################################################################
        ## Swapnil: neeed to chage below ref_fasta as variable
        ref_fasta=/vast/xa73pav/projects/p_nishant/data/ncbi_dataset/data/GCF_000003195.3/GCF_000003195.3_Sorghum_bicolor_NCBIv3_genomic.fasta

        # BWA index → enables fast alignment
        if [ ! -f ${ref_fasta}.bwt ]; then
            log "Indexing reference (BWA)"
            /home/groups/VEO/tools/bwa/v0.7.17/bwa index $ref_fasta
        fi

        # FASTA index → needed by samtools / bcftools
        if [ ! -f ${ref_fasta}.fai ]; then
            /home/groups/VEO/tools/samtools/v1.17/bin/samtools faidx $ref_fasta
        fi

        # Sequence dictionary → required by GATK
        if [ ! -f ${ref_fasta%.fasta}.dict ]; then
            source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
            conda activate gatk_v4.6.1.0

            gatk CreateSequenceDictionary \
                -R $ref_fasta 

            conda deactivate
        fi

        wait_until_written ${ref_fasta%.fasta}.dict

###############################################################################

split_list $wd $list
submit_jobs $wd $pipeline

###############################################################################
## footer
log "ENDED : $pipeline ----------------------------------"
###############################################################################