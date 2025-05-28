#!/bin/bash
###############################################################################
pipeline=0412_genome_assembly_polish_by_polypolish
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
echo "STARTED : $pipeline -------------------------------------------"
###############################################################################
## step-01: preparation

	awk '/sam_filepath/ {flag=1; next} flag && /^$/ {flag=0} flag' $parameters > list.$pipeline.txt
	list=list.$pipeline.txt

    create_directories_structure_1 $wd
    split_list $wd $list
    submit_jobs $wd $pipeline

##############################################################################
echo "COMPLETED: $pipeline -----------------------------------------"
###############################################################################
