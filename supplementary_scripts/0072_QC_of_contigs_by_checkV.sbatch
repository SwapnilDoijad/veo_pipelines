#!/bin/bash
#SBATCH --job-name 0072_QC_of_contigs_by_checkV
#SBATCH --partition=standard
#SBATCH --output results/0072_QC_of_contigs_by_checkV/tmp/slurm/%j.out
#SBATCH --error  results/0072_QC_of_contigs_by_checkV/tmp/slurm/%j.err
#SBATCH --cpus-per-task=25
#-- Command section ------------------------
pipeline=0072_QC_of_contigs_by_checkV
source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
sublist=$wd/tmp/lists/ABC

    log "running : $pipeline for $sublist"

		source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh ;
		conda activate checkv_v1.0.1

		for i in $(cat $sublist); do
			if [ ! -f $wd/raw_files/$i/quality_summary.tsv.tmp ] ; then 
                log "running : checkV for $i"
                (mkdir $wd/raw_files/$i) > /dev/null 2>&1

                checkv end_to_end $fasta_dir_path/$i.fasta $wd/raw_files/$i \
                -t 22 -d /work/groups/VEO/databases/checkv/v1.5 ;

				awk 'NR>1 {print $0}' $wd/raw_files/$i/quality_summary.tsv | sed -e 's/^/'"$i\t"'/g ' > $wd/raw_files/$i/quality_summary.tsv.tmp
				cat "$wd/raw_files/$i/quality_summary.tsv.tmp" >> "$wd/summary.tsv"
				else
				log "already finished: checkV for $i"
			fi 
		done
		
    log "finished : $pipeline for $sublist"