#!/bin/bash
###############################################################################
## header
	pipeline=m004_otu2matrix
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "ENDED : $pipeline ----------------------"
###############################################################################
	list=list.path.100.txt

	## 202040518
		## also, a single script (which will be used below also in submit job step)
		## /home/groups/VEO/scripts_for_users/supplementary_scripts/m004_otus2matrix.py
		## could handle 250,000 files in less than 9 hours, interactive node 350GB RAM amd 90 CPUs

    # create_directories_structure_1 $wd
    # split_list $wd $list
    # submit_jobs $wd $pipeline

	## manual stop: 1
	# exit 

	# Postprocessing to merge the output files form /home/groups/VEO/scripts_for_users/supplementary_scripts/m004_otus2matrix.py
	## also worked
		sbatch /home/groups/VEO/scripts_for_users/supplementary_scripts/m004_otus2matrix_combine_output.sbatch

###############################################################################
## footer
    log "ENDED : $pipeline ----------------------"
###############################################################################