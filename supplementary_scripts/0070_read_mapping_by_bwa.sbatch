#!/bin/bash
#SBATCH --job-name=0070_read_mapping_by_bwa
#SBATCH --partition=standard,long,fat
#SBATCH --output=results/0070_read_mapping_by_bwa/tmp/slurm/%j.out.txt
#SBATCH --error=results/0070_read_mapping_by_bwa/tmp/slurm/%j.err.txt
#SBATCH --mem=200G
#SBATCH --cpus-per-task=40
#SBATCH --exclusive
###############################################################################
#Load custom functions + parameters
###############################################################################
echo "Swapnil: parameters are for the SORGHUM genome"

pipeline=0070_read_mapping_by_bwa
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC

SNP_analysis=$(grep -w "my_SNP_analysis" $parameters | awk '{print $2}')
snp_annotation=$(grep -w "my_snp_annotation" $parameters | awk '{print $2}')

# Absolute paths to tools
bwa=/home/groups/VEO/tools/bwa/v0.7.17/bwa
samtools=/home/groups/VEO/tools/samtools/v1.17/bin/samtools
bcftools=/home/groups/VEO/tools/bcftools/v1.17/bin/bcftools
###############################################################################
log "Pipeline started"
###############################################################################
source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
conda activate gatk_v4.6.1.0

while IFS= read -r line; do

    ###########################################################################
    #INPUT PARSING
    ###########################################################################
        assembly=$(echo $line | awk '{print $1}')   # reference genome (FASTA)
        R1=$(echo $line | awk '{print $2}')         # forward reads
        R2=$(echo $line | awk '{print $3}')         # reverse reads

        assembly_id=$(basename $assembly | sed 's/.fasta//')
        fastq_id=$(basename $R1 | sed 's/_R1.fastq.gz//')

        log "Processing: $assembly_id | $fastq_id"

        ref_fasta=$assembly
        bam_prefix=$raw_files/sam_files_sorted/$assembly_id.$fastq_id

    ###############################################################################
    #STEP 1 — PREPARE REFERENCE (if we have more than one reference, each reference will be indexed only once)
    ## if we have same reference for multiple samples, it will be indexed only once in launcher script
    ###############################################################################
                            #     # Required for all downstream tools (BWA, samtools, GATK)

                            #     # BWA index → enables fast alignment
                            #     if [ ! -f ${ref_fasta}.bwt ]; then
                            #         log "Indexing reference (BWA)"
                            #         $bwa index $ref_fasta
                            #     fi

                            #     # FASTA index → needed by samtools / bcftools
                            #     if [ ! -f ${ref_fasta}.fai ]; then
                            #         $samtools faidx $ref_fasta
                            #     fi

                            #     # Sequence dictionary → required by GATK
                            #     if [ ! -f ${ref_fasta%.fasta}.dict ]; then
                            #         gatk CreateSequenceDictionary \
                            #             -R $ref_fasta \
                            #             -O ${ref_fasta%.fasta}.dict
                            #     fi

                            # ###############################################################################
                            # #STEP 2 — READ MAPPING (BWA-MEM)
                            # ###############################################################################
                            #     if [ ! -f ${bam_prefix}.sorted.bam ]; then

                            #         log "Mapping reads with BWA-MEM"

                            #         $bwa mem -t $SLURM_CPUS_PER_TASK \
                            #             -R "@RG\tID:$fastq_id\tSM:$fastq_id\tPL:ILLUMINA" \
                            #             $ref_fasta $R1 $R2 | \
                                    
                            #         # Convert SAM → BAM and filter low-quality alignments
                            #         # -q 20 → removes poorly mapped reads (important in plant repeats)
                            #         $samtools view -b -q 20 --no-PG | \
                                    
                            #         # Sort BAM → required for indexing and variant calling
                            #         $samtools sort -@ $SLURM_CPUS_PER_TASK --no-PG \
                            #             -o ${bam_prefix}.sorted.bam

                            #         log "Mapping completed"
                            #     fi

                            # ###############################################################################
                            # #STEP 3 — MARK DUPLICATES
                            # ###############################################################################
                            #     # Removes PCR duplicates (very important for Illumina)
                            #     # Prevents false SNPs from amplification bias

                            #     if [ ! -f ${bam_prefix}.dedup.bam ]; then
                            #         log "Marking duplicates"

                            #         gatk MarkDuplicates \
                            #             -I ${bam_prefix}.sorted.bam \
                            #             -O ${bam_prefix}.dedup.bam \
                            #             -M ${bam_prefix}.metrics.txt

                            #         # Index BAM for fast random access
                            #         $samtools index ${bam_prefix}.dedup.bam
                            #     fi

                            # ###############################################################################
                            # #STEP 4 — QC METRICS
                            # ###############################################################################
                            #     # Alignment statistics
                            #     $samtools flagstat ${bam_prefix}.dedup.bam \
                            #         > ${bam_prefix}.summary.txt

                            #     # Per-contig read counts
                            #     $samtools idxstats ${bam_prefix}.dedup.bam \
                            #         > ${bam_prefix}.idxstats.txt

                            #     # Depth calculation
                            #     # -aa → include all positions
                            #     # -s → avoid double counting overlapping read pairs
                            #     $samtools depth -aa -s ${bam_prefix}.dedup.bam \
                            #         > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt

                                    # ###############################################################################
                                    # #STEP 5 — VARIANT CALLING (GATK HaplotypeCaller)
                                    # ###############################################################################
                                    #     if [ "$SNP_analysis" = "Yes" ]; then

                                    #         gvcf=$raw_files/vcf/$assembly_id.$fastq_id.g.vcf.gz

                                    #         if [ ! -f $gvcf ]; then
                                    #             log "Running HaplotypeCaller"

                                    #             gatk --java-options "-Xmx100g" HaplotypeCaller \
                                    #                 -R $ref_fasta \
                                    #                 -I ${bam_prefix}.dedup.bam \
                                    #                 -O $gvcf \
                                    #                 -ERC GVCF \
                                    #                 --native-pair-hmm-threads $SLURM_CPUS_PER_TASK

                                    #             # -ERC GVCF → enables joint genotyping later
                                    #             # HaplotypeCaller performs local assembly → better indel calling
                                    #         fi

                                        # ###############################################################################
                                        # #STEP 6 — GENOTYPING
                                        # ###############################################################################
                                        #         raw_vcf=$raw_files/vcf/$assembly_id.$fastq_id.raw.vcf.gz

                                        #         gatk GenotypeGVCFs \
                                        #             -R $ref_fasta \
                                        #             -V $gvcf \
                                        #             -O $raw_vcf

                                        # ###############################################################################
                                        # #STEP 7 — VARIANT FILTERING
                                        # ###############################################################################
                                        #         filtered_vcf=$raw_files/vcf/$assembly_id.$fastq_id.filtered.vcf.gz

                                        #         gatk VariantFiltration \
                                        #             -R $ref_fasta \
                                        #             -V $raw_vcf \
                                        #             -O $filtered_vcf \
                                        #             --filter-name "QD_filter" --filter-expression "QD < 2.0" \
                                        #             --filter-name "FS_filter" --filter-expression "FS > 60.0" \
                                        #             --filter-name "MQ_filter" --filter-expression "MQ < 40.0" \
                                        #             --filter-name "SOR_filter" --filter-expression "SOR > 3.0" \
                                        #             --filter-name "DP_filter" --filter-expression "DP < 10 || DP > 600"

                                        #         # Explanation:
                                        #         # QD → quality normalized by depth
                                        #         # FS → strand bias (high = bad)
                                        #         # MQ → mapping quality
                                        #         # SOR → strand bias (alternative metric)
                                        #         # DP → depth filter (600 fits your 80–150× data)

                                        # ###############################################################################
                                        # #STEP 8 — EXTRACT HIGH-QUALITY SNPs
                                        # ###############################################################################
                                        #         $bcftools view -f PASS $filtered_vcf \
                                        #             -Oz -o ${filtered_vcf%.vcf.gz}.pass.vcf.gz

                                        # ###############################################################################
                                        # #STEP 9 — CONSENSUS SEQUENCE
                                        # ###############################################################################
                                        #         $bcftools consensus \
                                        #             -f $ref_fasta \
                                        #             ${filtered_vcf%.vcf.gz}.pass.vcf.gz \
                                        #             > $raw_files/consensus_sequences/$assembly_id.$fastq_id.consensus.fasta
                                        #     fi

    ###############################################################################
    #STEP 10 — SNP ANNOTATION (SnpEff)
    ###############################################################################
        if [ "$snp_annotation" = "Yes" ]; then

            log "Running SnpEff annotation"

            java -Xmx16g -jar /home/groups/VEO/tools/snpeff/v5.2c/snpEff/snpEff.jar \
                $assembly_id \
                ${filtered_vcf%.vcf.gz}.pass.vcf.gz \
                > ${filtered_vcf%.vcf.gz}.snpeff.vcf
        fi

    ###############################################################################
        log "Finished: $assembly_id | $fastq_id"
        echo "------------------------------------------------------------"

done < $sublist

###############################################################################
log "Pipeline completed"
###############################################################################