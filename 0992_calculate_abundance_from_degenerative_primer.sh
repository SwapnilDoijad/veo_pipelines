#!/bin/bash
###############################################################################
## header
    pipeline=0992_calculate_abundance_from_degenerative_primer
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: $pipeline --------------------"
###############################################################################
## step-01: preparation
	(mkdir -p $wd/tmp/list_BarcodePrimers/samples ) > /dev/null 2>&1
    create_directories_structure_1 $wd
    
    awk '/# ----------/{flag=!flag; next} flag' $parameters > tmp/parameters/$pipeline.my_barcode.txt

    sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/$pipeline.sbatch  > /dev/null 2>&1

###############################################################################
    log "ENDED : $pipeline ----------------------"
###############################################################################
