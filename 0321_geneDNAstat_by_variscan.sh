#!/bin/bash
###############################################################################
## header
    pipeline=0321_geneDNAstat_by_variscan
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    echo "STARTED : $pipeline ---------------------------------"
###############################################################################
## step-01: file and directory preparation

    create_directories_structure_1 $wd

    cp $suppl_scripts/0321_geneDNAstat_by_variscan.sbatch \
    $wd/tmp/sbatch/0321_geneDNAstat_by_variscan.sbatch

    sbatch $wd/tmp/sbatch/0321_geneDNAstat_by_variscan.sbatch
    results/0321_geneDNAstat_by_variscan/tmp/sbatch

###############################################################################
## footer
    log "FINISHED : $pipeline ---------------------------------"
###############################################################################