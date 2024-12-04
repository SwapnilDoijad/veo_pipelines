#!/bin/bash
#SBATCH --job-name 0138_phylogeny_by_kSNP4
#SBATCH --partition=gpu
#SBATCH --output results/0138_phylogeny_by_kSNP4/tmp/slurm/%j.out
#SBATCH --error  results/0138_phylogeny_by_kSNP4/tmp/slurm/%j.err
#SBATCH --cpus-per-task=80
#SBATCH --mem=200G
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com
###############################################################################
## header
	pipeline=0138_phylogeny_by_kSNP4
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED : $pipeline"
###############################################################################
## 01 preparation
    fasta_dir=$(grep "my_fasta_dir" $parameters | awk '{print $NF}')
###############################################################################
## 01 run kSNP4
	## create inFile for kSNP4
	log "STARTED : $pieline : create inFile for kSNP4 infile"
	if [ ! -f $wd/tmp/kSNP4.infile ] ; then 
		/home/groups/VEO/tools/kSNP/v4.1/MakeKSNP4infile \
		-indir $fasta_dir -outfile $wd/tmp/kSNP4.infile 
	fi

	log "STARTED : $pieline : run kSNP4 tool"
	source /home/groups/VEO/tools/biopython/myenv/bin/activate
	/home/groups/VEO/tools/kSNP/v4.1/kSNP4 \
	-in $wd/tmp/kSNP4.infile \
	-k 21 \
	-CPU $SLURM_CPUS_PER_TASK \
	-core \
	-ML -NJ \
	-min_frac 0.25 \
	-outdir $raw_files 
	
	deactivate
	log "FINISHED : $pieline : run kSNP4 tool"
###############################################################################
	log "FINISHED : $pipeline"
###############################################################################