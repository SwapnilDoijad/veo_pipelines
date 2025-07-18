#!/bin/bash
#SBATCH --job-name=0069_identification_by_ANI_by_mash
#SBATCH --partition=standard,long,gpu,gpu-test,gpu-veo
#SBATCH --output=results/0069_identification_by_ANI_by_mash/tmp/slurm/%j.out
#SBATCH --error=results/0069_identification_by_ANI_by_mash/tmp/slurm/%j.err
#SBATCH --cpus-per-task=80
#SBATCH --mem=200G
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com
############################################################################### 
## 00 preparations 
    pipeline=0069_identification_by_ANI_by_mash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    fasta_directory=$( grep my_fasta_path $parameters | awk '{print $2}' )
    type_strain_fasta_directory=$( grep my_type_strain_fasta_path $parameters | awk '{print $2}' )
###############################################################################
    log "STARTED : $pipeline --------------------------------------"
###############################################################################
## step-01: sketching
    if [ ! -f $raw_files/msh/type_strains.msh ] ; then 
        log "STARTED : $pipeline : sketching"

        ( /home/groups/VEO/tools/mash/v2.3/mash \
        sketch -p 80 \
        -o $raw_files/msh/fasta.msh \
        $fasta_directory/*.fasta \
        )> /dev/null 2>&1

        ( /home/groups/VEO/tools/mash/v2.3/mash \
        sketch -p 80 \
        -o $raw_files/msh/type_strains.msh \
        $type_strain_fasta_directory/*.fasta \
        )> /dev/null 2>&1

        log "FINISHED: $pipeline : sketching"
        else
        log "ALREADY FINISHED : $pipeline : sketching"
    fi 
###############################################################################
## step-02: mashing
    if [ ! -f $raw_files/msh/distance/all.distance.tab ] ; then 
        log "STARTED : $pipeline : mashing"
        /home/groups/VEO/tools/mash/v2.3/mash \
		dist \
		-p 80 \
		$raw_files/msh/fasta.msh \
		$raw_files/msh/type_strains.msh \
		> $raw_files/msh/distance/all.distance.tab
        log "FINISHED: $pipeline : mashing"
        else 
        log "ALREADY FINISHED : $pipeline : mashing"
    fi
    sed -i "s|"$fasta_directory"/||g" $raw_files/msh/distance/all.distance.tab 
    sed -i "s|"$type_strain_fasta_directory"/||g" $raw_files/msh/distance/all.distance.tab
    sed -i 's|.fasta||g' $raw_files/msh/distance/all.distance.tab
###############################################################################
## step-02: parsing
	if [ ! -d $raw_files/msh/distance/tmp ] ; then 
	    (mkdir -p $raw_files/msh/distance/tmp )> /dev/null 2>&1
		log "STARTED : $pipeline : parsing"

		for fasta in $(cat list.$pipeline.txt ); do 
			if [ ! -f $raw_files/msh/distance/tmp/$fasta.distance.tab ] ; then 
				grep -w "$fasta" $raw_files/msh/distance/all.distance.tab \
				| sort -t$'\t' -k3,3 -k5,5  | awk '$3 < 0.050000 {print}' \
                > $raw_files/msh/distance/tmp/$fasta.tab

                cat $raw_files/msh/distance/tmp/$fasta.tab \
                awk '$3 < 0.05' | head -1 \
                > $raw_files/msh/distance/tmp/$fasta.species.tab 

			fi
		done

        for id in $(ls $raw_files/msh/distance/tmp/*.species.tab ); do 
            i=$(echo $id | sed 's/.species.tab//g' | awk -F'/' '{print $NF}')
            if [ -s $raw_files/msh/distance/tmp/$i.species.tab ] ; then 
                ANI=$(cat $raw_files/msh/distance/tmp/$i.species.tab | awk '{print (1-$3)*100}' )
                species=$(cat $raw_files/msh/distance/tmp/$i.species.tab | awk '{print $2}' )           
                echo -e "$i\t$species\t$ANI" \
                >> $raw_files/identification.txt
                else
                echo -e "$i\tunclassified\t0" \
                >> $raw_files/identification.txt
            fi
        done 

		log "FINISHED: $pipeline : parsing"
		else
		log "ALREADY FINISHED : $pipeline : parsing"
	fi
# ###############################################################################
    log "FINISHED : $pipeline --------------------------------------"
###############################################################################