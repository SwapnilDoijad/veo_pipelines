#!/bin/bash
#SBATCH --job-name=0227_gene_detection_by_lsBSR
#SBATCH --partition=standard,long,interactive
#SBATCH --output=results/0227_gene_detection_by_lsBSR/tmp/slurm/%j.out
#SBATCH --error=results/0227_gene_detection_by_lsBSR/tmp/slurm/%j.err
#SBATCH --cpus-per-task=20
#SBATCH --mem=100G
###############################################################################
## step-01: preparation
    pipeline=0227_gene_detection_by_lsBSR
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    gene_path=$( grep my_gene_path $parameters | awk '{print $2}' )
    gene_id=$( basename $gene_path .fasta)  

###############################################################################
## step-02:
    log "STARTED : $pipeline : $sublist"
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate ls_bsr_v1.03 

    python /home/groups/VEO/tools/ls-bsr/v1.03/LS-BSR/ls_bsr.py \
    -d $fasta_dir/ \
    -p $SLURM_CPUS_PER_TASK \
    -g $gene_path \
    -x $raw_files/$gene_id \
    & my_pid=$!
    get_resource_stat $my_pid $wd/tmp/resource_log/lsBSR.tsv


    ## transpose the matrix
    sed -i '1s/^[^\t]*/gene/' $raw_files/"$gene_id"_bsr_matrix.txt

    awk '
    {
        for (i = 1; i <= NF; i++)  {
            a[NR,i] = $i
        }
    }
    NF > p { p = NF }
    END {
        for(j = 1; j <= p; j++) {
            str = a[1,j]
            for(i = 2; i <= NR; i++){
                str = str "\t" a[i,j]
            }
            print str
        }
    }'  $raw_files/"$gene_id"_bsr_matrix.txt \
    > $raw_files/"$gene_id"_bsr_matrix.txt.transposed.tsv

    log "FINISHED : $pipeline : $sublist"
###############################################################################
exit 
/home/groups/VEO/tools/blast/v2.14.0/bin/makeblastdb -in /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/data/discarded/fasta_esp_unarranged/i2_7.fasta -dbtype nucl

/home/groups/VEO/tools/blast/v2.14.0/bin/blastn \
  -query /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/data/gene/nod_all_core_N741.fasta \
  -db /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/data/discarded/fasta_esp_unarranged/i2_7.fasta \
  -outfmt "6 qseqid sseqid pident length evalue bitscore" \
  -evalue 1e-5 \
  -num_threads $SLURM_CPUS_PER_TASK \
  > nod_hits.tsv

/home/groups/VEO/tools/blast/v2.14.0/bin/makeblastdb -in /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/data/discarded/fasta_esp_unarranged/Y2_6.fasta -dbtype nucl

/home/groups/VEO/tools/blast/v2.14.0/bin/blastn \
  -query /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/data/gene/nod_all_core_N741.fasta \
  -db /vast/xa73pav/projects/p_swapnil_rhizobium_paper_250101/data/discarded/fasta_esp_unarranged/Y2_6.fasta \
  -outfmt "6 qseqid sseqid pident length qlen qcovs evalue bitscore sstart send sstrand" \
  -evalue 1e-5 \
  -num_threads $SLURM_CPUS_PER_TASK \
  > nod_hits.tsv