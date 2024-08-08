#!/bin/bash
#SBATCH --job-name 0065_read_mapping_by_minimap2
#SBATCH --partition=standard
#SBATCH --output results/0065_read_mapping_by_minimap2/tmp/slurm/%j.out.0065_read_mapping_by_minimap2.txt
#SBATCH --error results/0065_read_mapping_by_minimap2/tmp/slurm/%j.err.0065_read_mapping_by_minimap2.txt
#SBATCH --mem=40G
#SBATCH --cpus-per-task=20
###############################################################################
pipeline=0065_read_mapping_by_minimap2
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
list=$wd/tmp/lists/ABC

echo $sublist
    while IFS= read -r line; do
        assembly_id_path=$( echo $line | awk '{print $1}' | xargs -I{} dirname {} )
        assembly_id=$( echo $line | awk '{print $1}' | awk -F'/' '{print $NF}' | sed 's/\.fasta//g')
        fastq_id_path=$( echo $line | awk '{print $2}' | xargs -I{} dirname {} )
        fastq_id=$( echo $line | awk '{print $2}'| awk -F'/' '{print $NF}' | sed 's/\.fastq\.gz//g' )

        ## create index
        if [ ! -f $wd/raw_files/index_files/$assembly_id.fasta.mmi ]; then
            log "STARTED : creating index for $assembly_id"
            /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x map-pb -t 40 \
            -d $wd/raw_files/index_files/$assembly_id.fasta.mmi \
            $assembly_id_path/"$assembly_id".fasta
            log "FINISHED : creating index for $assembly_id"
            else
            echo "ALREADY FINISHED : index for $assembly_id"
        fi

        ## map files
        if [ ! -f $wd/raw_files/sam_files/$assembly_id.$fastq_id.sam ] ; then
            log "STARTED : mapping $fastq_id on $assembly_id using minimap2"
            /home/groups/VEO/tools/minimap2/v2.26/minimap2 -x map-pb -a \
            $wd/raw_files/index_files/$assembly_id.fasta.mmi \
            $fastq_id_path/$fastq_id.fastq.gz \
            > $wd/raw_files/sam_files/$assembly_id.$fastq_id.sam
            log "FINISHED : mapping for $fastq_id on $assembly_id"
            else 
            log "ALREADY FINISHED : mapping for $fastq_id on $assembly_id"
        fi 

        ## sort file using samtools
        /home/groups/VEO/tools/samtools/v1.17/bin/samtools sort -@ 10 -l 9 -m 5000M \
        -o $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
        $wd/raw_files/sam_files/$assembly_id.$fastq_id.sam

        ## get summary of sorted .bam file using samtools
        /home/groups/VEO/tools/samtools/v1.17/bin/samtools flagstat \
        $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.sam.sorted.bam \
        > $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt

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
        cat $wd/raw_files/sam_files_sorted/$assembly_id.$fastq_id.summary.txt \
        >> $wd/summary.txt
        echo "--------------------------------------------------------------------------------" >> $wd/summary.txt

    done <  $wd/tmp/lists/ABC

    log "The run for sublist : $sublist is completed"

###############################################################################
## footer
###############################################################################