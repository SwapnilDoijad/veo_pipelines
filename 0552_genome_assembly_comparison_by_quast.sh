#!/bin/bash
###############################################################################
## header
    pipeline=0552_genome_assembly_comparison_by_quast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: 0552_genome_assembly_comparison_by_quast --------------------"
###############################################################################
## step-01: preparation

    create_directories_structure_1 $wd

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch  > /dev/null 2>&1

###############################################################################
log "ENDED : 0552_genome_assembly_comparison_by_quast ----------------------"
###############################################################################
