#!/bin/bash
#SBATCH --job-name 0061_identification_by_gtdbtk
#SBATCH --partition=gpu,gpu-veo,gpu-test,fat,standard,long
#SBATCH --output results/0061_identification_by_gtdbtk/tmp/slurm/%j.out.0061_identification_by_gtdbtk.txt
#SBATCH --error results/0061_identification_by_gtdbtk/tmp/slurm/%j.err.0061_identification_by_gtdbtk.txt
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
###############################################################################
## header
    pipeline=0061_identification_by_gtdbtk
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fasta_file_dir=$(grep "my_fasta_dir" $parameters | awk '{print $2}')
    tree_choise=$(grep "my_tree_choise" $parameters | awk '{print $2}')
    custom_taxonomy_file=$(grep "my_custom_taxonomy_file" $parameters | awk '{print $2}')
    # sublist=$wd/tmp/lists/ABC
    sublist=list.$pipeline.tmp
###############################################################################
    log "STARTED: $pipeline : $list"
###############################################################################
## notes
    ## 2025-02-16 05:00:55 conda env config vars set GTDBTK_DATA_PATH="/veodata/03/databases/gtdbtk/r214/release214";
    ## for more conda env config see https://ecogenomics.github.io/GTDBTk/installing/bioconda.html (conda env config vars set GTDBTK_DATA_PATH="/path/to/unarchived/gtdbtk/data";)
    ## https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#setting-environment-variables

    export GTDBTK_DATA_PATH=/veodata/03/databases/gtdbtk/release226/

    # source /home/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    # conda activate gtdbtk_v2.1.1
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate gtdbtk_v2.4.1

    if [ "$tree_choise" == "identification" ]; then
            log "RUNNING: classify_wf $pipeline"

            gtdbtk classify_wf \
            --cpus $SLURM_CPUS_PER_TASK \
            --batchfile $sublist \
            --out_dir $raw_files/$sublist \
            --extension fasta \
            --mash_db /veodata/03/databases/gtdbtk/release226/mash_file.msh \
            & my_pid=$! 
            get_resource_stat $my_pid $wd/tmp/resource_log/$sublist.gtdbtk.tsv 

            log "FINISHED: classify_wf $pipeline"

        elif [ "$tree_choise" == "study_genomes" ]; then
            log "RUNNING: de_novo_wf $pipeline"

            gtdbtk de_novo_wf \
            --batchfile $sublist \
            --cpus $SLURM_CPUS_PER_TASK \
            --extension fasta \
            --bacteria \
            --outgroup_taxon p__Firmicutes \
            --out_dir $raw_files/$sublist \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/$sublist.gtdbtk_denovo.tsv

            gunzip $raw_files/list.0061_identification_by_gtdbtk.tmp/align/gtdbtk.bac120.user_msa.fasta.gz

            /home/groups/VEO/tools/iqtree/1.6.12/bin/iqtree \
            -s $raw_files/list.0061_identification_by_gtdbtk.tmp/align/gtdbtk.bac120.user_msa.fasta \
            -m MFP \
            -nt $SLURM_CPUS_PER_TASK \
            -bb 1000 \
            & my_pid=$!
            get_resource_stat $my_pid $wd/tmp/resource_log/$sublist.iqtree.tsv

            log "FINISHED: de_novo_wf $pipeline"

        elif [ "$tree_choise" == "tree_for_study_isolates" ]; then

            ## Run GTDB identify (only marker detection)
            log "RUNNING: tree_for_study_isolates $pipeline"
                gtdbtk identify \
                --genome_dir $fasta_file_dir \
                --extension fasta \
                --out_dir $raw_files \
                --cpus $SLURM_CPUS_PER_TASK
            log "FINISHED: tree_for_study_isolates $pipeline"
            ## Align markers (no classification!)
            log "RUNNING: gtdbtk align $pipeline"
                gtdbtk align \
                --identify_dir $raw_files \
                --out_dir $raw_files \
                --cpus $SLURM_CPUS_PER_TASK

                gunzip $raw_files/align/gtdbtk.bac120.user_msa.fasta.gz
                gunzip $raw_files/align/gtdbtk.bac120.msa.fasta.gz
            log "FINISHED: gtdbtk align $pipeline"
                ## Build Tree with IQ-TREE (Recommended)
                log "RUNNING: iqtree $pipeline"
                    ## this takes time (but robust)
                        /home/groups/VEO/tools/iqtree/1.6.12/bin/iqtree \
                        -s $raw_files/align/gtdbtk.bac120.user_msa.fasta \
                        -st AA \
                        -m MFP \
                        -bb 1000 \
                        -alrt 1000 \
                        -nt AUTO            

                    ## relatively faster with fixed model (GTR+G) and no alrt support values
                        # /home/groups/VEO/tools/iqtree/1.6.12/bin/iqtree \
                        #     -s gtdb_trim/bac120.trimmed.fasta \
                        #     -m GTR+G \
                        #     -bb 1000 \
                        #     -nt AUTO
                log "FINISHED: iqtree $pipeline"
        
        else
        log "ERROR: Invalid tree choice specified in parameters file. Please use 'study_genomes' or 'combined_genomes'."
        exit 1
    fi
###############################################################################
## footer
    log "FINISHED: $pipeline : $list"
###############################################################################
