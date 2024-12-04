#!/bin/bash
#SBATCH --job-name=0065_read_mapping_by_minimap2
#SBATCH --partition=short,interactive,standard
#SBATCH --output=results/0065_read_mapping_by_minimap2/tmp/slurm/%j.out.txt
#SBATCH --error=results/0065_read_mapping_by_minimap2/tmp/slurm/%j.err.txt
#SBATCH --mem=40G
#SBATCH --cpus-per-task=20
###############################################################################   
pipeline=0065_read_mapping_by_minimap2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC
data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')

    while IFS= read -r line; do

        assembly_id_path=$( echo $line | awk '{print $1}' | xargs -I{} dirname {} | sort | uniq )
        assembly_id=$( echo $line | awk '{print $1}' | awk -F'/' '{print $NF}' | sed 's/\.fasta//g' | sort | uniq )
        fastq_id_path=$( echo $line | awk '{print $2}' | xargs -I{} dirname {} | sort | uniq )
        fastq_id=$( echo $line | awk '{print $2}'| awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' | sort | uniq )

        if [ ! -f $raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt ] ; then 

            ## create index ## -x map-pb pacBIO reads ## -x sr short reads ## -x map-ont Nanopore reads 
            if [ ! -f $assembly_id_path/"$assembly_id".fasta.mmi ]; then
                log "STARTED : creating index for $assembly_id"
                /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x sr -t 40 \
                -d $raw_files/index_files/$assembly_id.fasta.mmi \
                $assembly_id_path/"$assembly_id".fasta
                log "FINISHED : creating index for $assembly_id"
                else
                echo "ALREADY FINISHED : index for $assembly_id"
            fi

            ## create index for reference fasta file using samtools, needed in addition to minimap2 index, for other tools
            if [ ! -f $assembly_id_path/"$assembly_id".samtools.dict ]; then
                log "STARTED : creating Samtool index for $assembly_id"
                cp $assembly_id_path/"$assembly_id".fasta \
                $assembly_id_path/"$assembly_id".samtools.fasta

                /home/groups/VEO/tools/samtools/v1.17/bin/samtools \
                faidx $assembly_id_path/"$assembly_id".samtools.fasta
                
                conda activate gatk_v4.6.1.0
                gatk CreateSequenceDictionary \
                -R $assembly_id_path/"$assembly_id".samtools.fasta \
                -O $assembly_id_path/"$assembly_id".samtools.dict
                conda deactivate 
                else
                echo "ALREADY FINISHED : Samtool index for $assembly_id"
            fi
0
            if [ $data_type == "paired" ]; then
                ## map files ## -x map-pb pacBIO reads ## -x sr short reads ## -x map-ont Nanopore reads
                if [ ! -f $raw_files/sam_files/$assembly_id.$fastq_id.sam ] ; then
                    log "STARTED : mapping $fastq_id on $assembly_id using minimap2"
                    /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x sr -a \
                    -t $SLURM_CPUS_PER_TASK \
                    $raw_files/index_files/$assembly_id.fasta.mmi \
                    $fastq_id_path/$fastq_id.fastq.gz \
                    > $raw_files/sam_files/$assembly_id.$fastq_id.sam
                    log "FINISHED : mapping for $fastq_id on $assembly_id"
                    else 
                    log "ALREADY FINISHED : mapping for $fastq_id on $assembly_id"
                fi 

                elif [ $data_type == "single" ]; then
            
                # Check if the SAM file already exists
                if [ ! -f "$raw_files/sam_files/$assembly_id.$fastq_id.sam" ]; then
                    log "STARTED : mapping $fastq_id on $assembly_id using minimap2"

                    # Run minimap2 for paired-end reads
                    /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x sr -a \
                    $raw_files/index_files/$assembly_id.fasta.mmi \
                    -t $SLURM_CPUS_PER_TASK \
                    $fastq_id_path/$fastq_id"_R1_001.fastq.gz \
                    $fastq_id_path/$fastq_id"_R2_001.fastq.gz \
                    > "$raw_files/sam_files/$assembly_id.$fastq_id.sam"

                    check_status "Mapping $fastq_id on $assembly_id"
                else
                    log "ALREADY FINISHED : mapping for $fastq_id on $assembly_id"
                fi
            fi

            ## sort file using samtools
            /home/groups/VEO/tools/samtools/v1.17/bin/samtools sort -@ 10 -l 9 -m 5000M \
            -o $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
            $raw_files/sam_files/$assembly_id.$fastq_id.sam

            ## get summary of sorted .bam file using samtools
            /home/groups/VEO/tools/samtools/v1.17/bin/samtools flagstat \
            $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
            > $raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt

            /home/groups/VEO/tools/samtools/v1.17/bin/samtools index \
            $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam

            /home/groups/VEO/tools/samtools/v1.17/bin/samtools depth \
            $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
            > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt

            awk '{sum[$1]+=$3; count[$1]++} END {for (contig in sum) print contig, sum[contig]/count[contig]}' \
            $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt \
            > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.avg_coverage.txt

            awk '{print $1}' $raw_files/depth_and_coverage/$assembly_id.$fastq_id.depth.txt | sort | uniq -c | awk '{print $1}' \
            > $raw_files/depth_and_coverage/$assembly_id.$fastq_id.lenght.txt

            paste $raw_files/depth_and_coverage/$assembly_id.$fastq_id.avg_coverage.txt $raw_files/depth_and_coverage/$assembly_id.$fastq_id.lenght.txt | sed "s/^/$assembly_id\t/g" \
            > $raw_files/sam_files_sorted/$assembly_id.$fastq_id.avg_coverage_lenght.txt


            echo "--------------------------------------------------------------------------------" >> $wd/summary.txt
            echo $assembly_id $fastq_id >> $wd/summary.txt
            cat $raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt \
            >> $wd/summary.txt
            echo "--------------------------------------------------------------------------------" >> $wd/summary.txt
                  
        fi

                                ## Generate Pileup File (required for the variant calling and consesus calling) 
                                    # mpileup -Ou: The -O option outputs uncompressed binary (BCF) format, and -u ensures the output is uncompressed, which allows for piping.
                                        # /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools mpileup -Ou -f \
                                        # $assembly_id_path/"$assembly_id".fasta \
                                        # $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                                        # -o $raw_files/mpileup/$assembly_id.$fastq_id.bcf

                                        # /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools call -mv -Oz -o \
                                        # $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz \
                                        # $raw_files/mpileup/$assembly_id.$fastq_id.bcf

                                        # ## Generate Consensus Sequence
                                        # /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools index $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz

                                        # cat $assembly_id_path/"$assembly_id".fasta | /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools consensus \
                                        # -p $assembly_id \
                                        # $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz \
                                        # > $raw_files/consensus_sequences/$assembly_id.$fastq_id.consensus.fasta


                                        # ## Generate Insertion and Deletion File
                                        # if [ ! -f $raw_files/InsDel/$assembly_id.$fastq_id.vcf ] ; then
                                        #     echo -e "#ID\tCHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tout" > $raw_files/InsDel/$assembly_id.$fastq_id.vcf
                                        # fi

                                        # /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools \
                                        # view $raw_files/vcf/$assembly_id.$fastq_id.vcf.gz \
                                        # | grep -v "^#" | sed "s/^/$fastq_id\t/" >> $raw_files/InsDel/$assembly_id.$fastq_id.vcf

                                        # awk 'NR > 1' $raw_files/InsDel/$assembly_id.$fastq_id.vcf >> $raw_files/summary.InsDel.tsv 

        if [ ! -f $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.filtered.vcf.gz ] ; then 
            log "STARTED : freebayes variant calling for $assembly_id.$fastq_id"

            /home/groups/VEO/tools/freebayes/v1.3.6/freebayes \
                --ploidy 1 \
                --min-alternate-fraction 0.001 \
                --min-alternate-count 1 \
                --min-mapping-quality 30 \
                --min-base-quality 20 \
                --use-best-n-alleles 3 \
                -f $assembly_id_path/"$assembly_id".fasta \
                $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf
                ## --ploidy 1 : haploid genome for e.g. phage 
                ## --min-alternate-fraction 0.01 : minimum fraction of alternate bases to call a variant (at least 1% of the reads need to support the alternate allele)
                ## --min-alternate-count 2 : minimum number of alternate bases to call a variant (minimum number of reads supporting the alternate allele for it to be considered a variant.)
                ## --min-mapping-quality 10 : minimum mapping quality to consider a read for variant calling (minimum mapping quality a read must have to be considered in the variant calling process.)
                ## --min-base-quality 20 : minimum base quality to consider a base for variant calling (the minimum base quality for a base to be considered in variant calling.)
                ## --use-best-n-alleles 1: Limits the analysis to the best 1 allele per position, which can reduce noise and help in situations where one allele is dominan
            
                # 2024-11-08 16:17:53
                # compress vcf file and get normalised vcf file (complex SNPs are split into multiple lines)    
                    conda activate gatk_v4.6.1.0

                    bgzip -c $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf \
                    > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.gz

                    /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools norm \
                    -m -any $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.gz \
                    -Ov -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf


                    /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools norm \
                    -m -both -c w $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf \
                    -f $assembly_id_path/"$assembly_id".fasta \
                    -Ov -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf

                    gatk LeftAlignAndTrimVariants \
                    -R $assembly_id_path/"$assembly_id".samtools.fasta \
                    -V $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf \
                    -O $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                    --split-multi-allelics

                    conda deactivate  


                                        ## 2024-11-08 16:17:53 : NOT GIVING GOOD RESULTS (some SNOs are skipped)
                                        # conda activate vcflib_v1.0.10

                                        #     vcfbreakmulti $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf | \
                                        #     vcfallelicprimitives -k > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.final_decomposed.vcf

                                        # conda deactivate

            ## convert raw vcf to raw tsv 
            python3 $suppl_scripts/0065_read_mapping_by_minimap2.vcf_to_tsv.py \
            -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
            -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv

            # QUAL>=20: Filters variants to include only those with a quality score (QUAL) greater than or equal to 10. A higher quality score indicates a higher confidence in the variant call.
            # FORMAT/DP>=10: Filters variants to include only those with a depth of coverage (DP) of 10 or more. Depth of coverage refers to how many reads support the variant at that position.
            # INFO/NUMALT<=2: To filter out sites with more than one alternate allele (which are more likely to be complex), you can use the INFO/NUMALT field to exclude these multi-allelic calls:
            # AF>=0.3: Filters variants where the allele frequency (AF) is at least 0.3. Allele frequency represents the proportion of reads supporting the alternate allele versus the total number of reads.
            log "STARTED : filtering freebayes variants for $assembly_id.$fastq_id" 
            /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools filter \
                -i 'QUAL>=20 && FORMAT/DP>=1 && INFO/NUMALT<=2 && AF>=0.00001' \
                $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                -Oz -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

                /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools index \
                --tbi $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

            log "STARTED : generating consensus sequence for $assembly_id.$fastq_id"
            /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools consensus \
            -f $assembly_id_path/"$assembly_id".fasta \
            -o $raw_files/consensus_sequences/$assembly_id.$fastq_id.consensus.fasta \
            $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

            gunzip -k $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.gz

            ## convert raw vcf to raw tsv 
            python3 $suppl_scripts/0065_read_mapping_by_minimap2.vcf_to_tsv.py \
            -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf \
            -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.tsv
            
            rm $raw_files/vcf/*.gz
            rm $raw_files/vcf/*.gz.tbi
        fi

        ## snpEff 
        ## 2024-11-09 07:44:29 need to give the full path? Don't know. Need to check  
        java -jar /home/groups/VEO/tools/snpeff/v5.2c/snpEff/snpEff.jar \
        -c /home/xa73pav/projects/p_wallapat_phage/results/0065_read_mapping_by_minimap2/tmp/snpEff.config \
        -dataDir /home/xa73pav/projects/p_wallapat_phage/results/0065_read_mapping_by_minimap2/tmp/ \
        ref_tmp \
        $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf \
        > $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.snpEff_annotated.vcf

        log "STARTED : generating final summary file for $assembly_id.$fastq_id"
        bash /home/groups/VEO/scripts_for_users/supplementary_scripts/0065_read_mapping_by_minimap2.filter.sh \
        -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.snpEff_annotated.vcf \
        -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.snpEff_annotated.vcf.summary.tsv

        sed -i "/#/!s/^/$fastq_id\t/" $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.snpEff_annotated.vcf.summary.tsv

        awk 'NR > 1' $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.filtered.vcf.snpEff_annotated.vcf.summary.tsv >> $raw_files/summary.InsDel.tsv
        grep -v "#" $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv | sed "s/^/$fastq_id\t/" >> $raw_files/summary.InsDel.unfiltered.tsv
 
        source /home/groups/VEO/tools/biopython/myenv/bin/activate
        python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/split_complex_snps.py \
        -i $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv \
        -o $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf.tsv.split.tsv
        deactivate
            ## Optional: make count of reads mapped and unmapped to SNPs  
                # bash /home/groups/VEO/scripts_for_users/supplementary_scripts/0065_read_mapping_by_minimap2.count.sh \
                # -v $raw_files/vcf/$assembly_id.$fastq_id.freebayes_variants.vcf.simple.vcf.decomposed.vcf.output_left_aligned.vcf \
                # -b $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
                # -o $raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam.counts.txt


    done <  $wd/tmp/lists/ABC

    log "The run for sublist : $sublist is completed"


############################################################################### 
## footer
###############################################################################

# java -jar /home/groups/VEO/tools/snpeff/v5.2c/snpEff/snpEff.jar \
# -c results/0065_read_mapping_by_minimap2/tmp/snpeff.config \
# build -genbank -v MN988491_1_Rhizobium_phage_RHph_Y3_36
