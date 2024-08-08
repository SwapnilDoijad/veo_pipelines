###############################################################################
## header
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : combined pipeline cp0010_phage_contigs_to_comparative -----------------------------------"
###############################################################################
## step-01: 0050_genome_assembly_QC_by_quast
	source /home/groups/VEO/scripts_for_users/0050_genome_assembly_QC_by_quast.sh
	
	log "STARTED: pipeline 0050_genome_assembly_QC_by_quast"
	while ! grep -q "ENDED : 0050_genome_assembly_QC_by_quast" tmp/slurm/*.cp0010_phage_contigs_to_comparative.out; do
		log "WAITING : 0050_genome_assembly_QC_by_quast to be finished"
		sleep 60
	done
	log "ENDED: pipeline 0050_genome_assembly_QC_by_quast"
	
###############################################################################
## step-02: 0072_QC_by_checkV
	source /home/groups/VEO/scripts_for_users/0072_QC_by_checkV.sh
	
	log "STARTED: pipeline 0072_QC_by_checkV"
	while ! grep -q "ENDED : 0072_QC_by_checkV" tmp/slurm/*.cp0010_phage_contigs_to_comparative.out; do
		log "WAITING : 0072_QC_by_checkV to be finished"
		sleep 60
	done
	log "ENDED: pipeline 0072_QC_by_checkV"
###############################################################################
## step-03: vclust
	# source /home/groups/VEO/scripts_for_users/vclust

	# log "STARTED: pipeline 0052_genome_assembly_QC_by_checkM"
	# while ! grep -q "ENDED : 0052_genome_assembly_QC_by_checkM" tmp/slurm/*.cp0010_phage_contigs_to_comparative.out; do
	# 	log "WAITING : 0052_genome_assembly_QC_by_checkM to be finished"
	# 	sleep 60
	# done
	# log "ENDED: pipeline 0052_genome_assembly_QC_by_checkM"
###############################################################################
## step-04: 0064_identification_by_genomad
	source /home/groups/VEO/scripts_for_users/0064_identification_by_genomad.sh	

	log "STARTED: pipeline 0064_identification_by_genomad"
	while ! grep -q "ENDED : 0064_identification_by_genomad" tmp/slurm/*.cp0010_phage_contigs_to_comparative.out; do
		log "WAITING : 0064_identification_by_genomad to be finished"
		sleep 60
	done	
	log "ENDED: pipeline 0064_identification_by_genomad"
###############################################################################
## step-05: 0083_annotation_prophage_by_pharokka
	source /home/groups/VEO/scripts_for_users/0083_annotation_prophage_by_pharokka.sh
	log "STARTED: pipeline 0083_annotation_prophage_by_pharokka"
	while ! grep -q "ENDED : 0083_annotation_prophage_by_pharokka" tmp/slurm/*.cp0010_phage_contigs_to_comparative.out; do
		log "WAITING : 0083_annotation_prophage_by_pharokka to be finished"
		sleep 60
	done
	log "ENDED: pipeline 0083_annotation_prophage_by_pharokka"
###############################################################################
## step-06: 0171_comparative_genomics_core-pan_by_panaroo
	source /home/groups/VEO/scripts_for_users/0171_comparative_genomics_core-pan_by_panaroo.sh
	log "STARTED: pipeline 0171_comparative_genomics_core-pan_by_panaroo"
	while ! grep -q "ENDED : 0171_comparative_genomics_core-pan_by_panaroo" tmp/slurm/*.cp0010_phage_contigs_to_comparative.out; do
		log "WAITING : 0171_comparative_genomics_core-pan_by_panaroo to be finished"
		sleep 60
	done
	log "ENDED: pipeline 0171_comparative_genomics_core-pan_by_panaroo"
###############################################################################
## step-07: send report by email (with attachment)
    log "STARTED : creating email report with attachment --------------------------------"
    user=$(whoami)
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/cp0010_phage_contigs_to_comparative.py -e $user_email
	       
    deactivate
	log "ENDED : creating email report with attachment --------------------------------"
###############################################################################
## footer
	log "ENDED : combined pipeline cp0010_phage_contigs_to_comparative -----------------------------------"
###############################################################################

##  vcontact2 IVTVREF