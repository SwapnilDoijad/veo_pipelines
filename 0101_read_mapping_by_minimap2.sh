#!/bin/bash
###############################################################################
## header
    pipeline=0101_read_mapping_by_minimap2
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : $pipeline ------------------------"
###############################################################################
## step-01: file preparations

    create_directories_structure_nextflow $wd

	## test nextflow pipeline for minimap2 read mapping
	source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
	conda activate nextflow_v25.10.2

	nextflow run \
	${wd}/tmp/${pipeline}.nf \
	-c ${wd}/tmp/${pipeline}.nf.config \
	-params-file ${wd}/tmp/${pipeline}.nf.params.yaml \
	-profile local -resume
	# -profile local


	# nextflow clean -f
	# mv .nextflow.log results/$pipeline/tmp/log
	# rm -rf work/

###############################################################################
## footer
    log "ENDED : $pipeline ------------------------"
###############################################################################
