#!/bin/bash
#SBATCH --job-name=0088_annotation_prokaryote_by_pgap
#SBATCH --partition=gpu,gpu-test,gpu-veo,standard,long
#SBATCH --output=results/0088_annotation_prokaryote_by_pgap/tmp/slurm/%j.out
#SBATCH --error=results/0088_annotation_prokaryote_by_pgap/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
#SBATCH --mem=100G
###############################################################################
## 00: preparations
    pipeline=0088_annotation_prokaryote_by_pgap
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    fasta_dir=$(grep "my_fasta_dir" tmp/parameters/$pipeline.* | awk '{print $2}')
###############################################################################
	log "SBATCH STARTED : $pipeline : $sublist"
###############################################################################
## 01: run phold
    source /home/groups/VEO/tools/pgap/v2025-05-06.build7983/pgap/pgap-env/bin/activate
    export PGAP_INPUT_DIR=/veodata/03/databases/pgap/
    export http_proxy=http://internet4nzm.rz.uni-jena.de:3128
    export https_proxy=http://internet4nzm.rz.uni-jena.de:3128
    for i in $(cat $sublist); do
        log "STARTED : $pipeline : $i"

        ## cpus: by default will use maxiumum available CPUS.
        python /home/groups/VEO/tools/pgap/v2025-05-06.build7983/pgap/scripts/pgap.py \
        -g $fasta_dir/$i.fasta \
        -s "Escherichia coli" \
        --taxcheck \
        --auto-correct-tax \
        --prefix $i \
        -m 100G \
        -n -v -d \
        --container-path /vast/xa73pav/projects/p_swapnil_Enterobacter/pgap_2025-05-06.build7983.sif \
        -o $raw_files/$i \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.pgap.tsv 
        
    done
###############################################################################
	log "SBATCH FINISHED : $pipeline : $sublist" && clean
###############################################################################



