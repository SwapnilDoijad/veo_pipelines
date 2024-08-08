###############################################################################
## header
	pipeline=cp0009_phage_fastq_to_assemblies
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : combined pipeline $pipeline -------------------"
###############################################################################
## step-01: 0043_genome_assembly_by_unicycler
	source /home/groups/VEO/scripts_for_users/0043_genome_assembly_by_unicycler.sh

	while ! grep -q "ENDED : 0043_genome_assembly_by_unicycler" tmp/slurm/*.$pipeline.out; do
		log "WAITING : pipeline 0043_genome_assembly_by_unicycler to be finished"
		sleep 10
	done
###############################################################################
## step-02: 0045_genome_assembly_by_canu
	source /home/groups/VEO/scripts_for_users/0045_genome_assembly_by_canu.sh

	while ! grep -q "ENDED : 0045_genome_assembly_by_canu" tmp/slurm/*.$pipeline.out; do
		log "WAITING : pipeline 0045_genome_assembly_by_canu to be finished"
		sleep 10
	done
###############################################################################
## step-03: 0048_genome_assembly_by_flye
	source /home/groups/VEO/scripts_for_users/0048_genome_assembly_by_flye.sh

	while ! grep -q "ENDED : 0048_genome_assembly_by_flye" tmp/slurm/*.$pipeline.out; do
		log "WAITING : pipeline 0048_genome_assembly_by_flye to be finished"
		sleep 10
	done
###############################################################################
## step-04: 0040_genome_assembly_QC_by_metaquast
	source /home/groups/VEO/scripts_for_users/0040_genome_assembly_QC_by_metaquast.sh

	while ! grep -q "ENDED : 0040_genome_assembly_QC_by_metaquast" tmp/slurm/*.$pipeline.out; do
		log "WAITING : pipeline 0040_genome_assembly_QC_by_metaquast to be finished"
		sleep 10
	done
###############################################################################
## step-05: 0551_genome_assembly_QC_with_ref_by_quast
	source /home/groups/VEO/scripts_for_users/0551_genome_assembly_QC_with_ref_by_quast.sh
	    /home/groups/VEO/scripts_for_users/0551_genome_assembly_QC_by_quast.sh

	while ! grep -q "ENDED : 0551_genome_assembly_QC_with_ref_by_quast" tmp/slurm/*.$pipeline.out; do
		log "WAITING : pipeline 0551_genome_assembly_QC_with_ref_by_quast to be finished"
		sleep 10
	done
###############################################################################
## step-06: send report by email (with attachment)
    echo "sending email"
    user=$(whoami)
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/cp0009_phage_fastq_to_assemblies.py -e $user_email
	       
    deactivate
###############################################################################
	log "ENDED : combined pipeline $pipeline -------------------"
###############################################################################