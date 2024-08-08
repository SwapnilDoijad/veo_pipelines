#!/bin/bash
#SBATCH --job-name 0066_getSNPs_from_BAM_by_bcftools
#SBATCH --partition=long
#SBATCH --output results/0066_getSNPs_from_BAM_by_bcftools/tmp/slurm/%j.out.0066_getSNPs_from_BAM_by_bcftools.txt
#SBATCH --error results/0066_getSNPs_from_BAM_by_bcftools/tmp/slurm/%j.err.0066_getSNPs_from_BAM_by_bcftools.txt
#SBATCH --mem=40G
#SBATCH --cpus-per-task=10
###############################################################################
## header
    start_time=$(date +"%Y%m%d_%H%M%S")
###############################################################################

fastq_path=XYZ
fasta_path=JKL
list=results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists/ABC

echo $sublist
    while IFS= read -r line; do
        assembly_id=$( echo $line | awk '{print $1}')
        fastq_id=$( echo $line | awk '{print $2}')

        ## bcftool
        /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools mpileup \
        -f data/all_fasta_splitted/$assembly_id.fasta \
        results/0066_getSNPs_from_BAM_by_bcftools/sam_files_sorted/$fastq_id.sam.sorted.bam \
        | /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools call -mv \
        -o results/0066_getSNPs_from_BAM_by_bcftools/raw_files/$assembly_id.$fastq_id.vcf

        echo -e "CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO/DP\tINFO/AC\tINFO/AN\tINFO/DP4\tINFO/MQ\tFORMAT/GT\tFORMAT/PL" \
        > results/0066_getSNPs_from_BAM_by_bcftools/raw_files/$assembly_id.$fastq_id.tsv

        /home/groups/VEO/tools/bcftools/v1.17/bin/bcftools \
        query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%QUAL\t%FILTER\t%INFO/DP\t%INFO/AC\t%INFO/AN\t%INFO/DP4\t%INFO/MQ\t[%GT]\t[%PL]\n' \
        results/0066_getSNPs_from_BAM_by_bcftools/raw_files/$assembly_id.$fastq_id.vcf \
        >> results/0066_getSNPs_from_BAM_by_bcftools/raw_files/$assembly_id.$fastq_id.tsv


    done <  results/0066_getSNPs_from_BAM_by_bcftools/tmp/lists/ABC

    echo "The run for sublist : $sublist is completed"

###############################################################################
## footer
    end_time=$(date +"%Y%m%d_%H%M%S")
    bash /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/time_calculations.sh "$start_time" "$end_time"
###############################################################################