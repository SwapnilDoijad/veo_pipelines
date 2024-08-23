###############################################################################
## header
    pipeline=0671_identifying_close_relative_by_ANI_by_mash
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
    echo "STARTED : $pipeline started --------------------------------------"
###############################################################################
## 00 preparations 
	ref_fasta_path=$(grep "ref_fasta_path" $parameters | awk '{print $NF}')
    fasta_path=$(grep "my_fasta_path" $parameters | awk '{print $NF}')
    ls $fasta_path/ | sed 's/.fasta//g' > list.fasta.txt
    list=list.fasta.txt

    (mkdir -p $raw_files/tmp)> /dev/null 2>&1
    (mkdir -p $raw_files/msh/distance)> /dev/null 2>&1
 
    # Specify the number of CPU cores you want to use
    num_cores=80 
###############################################################################
## step-03: sketching
    if [ ! -f $raw_files/msh/ref_mash_sketch.msh ] ; then 
        log "STARTED : $pipeline : sketching"
        ( /home/groups/VEO/tools/mash/v2.3/mash sketch -p 80 -o $raw_files/msh/ref_mash_sketch.msh $ref_fasta_path/*.fasta )> /dev/null 2>&1
		( /home/groups/VEO/tools/mash/v2.3/mash sketch -p 80 -o $raw_files/msh/mash_sketch.msh $fasta_path/*.fasta )> /dev/null 2>&1
        log "FINISHED: $pipeline : sketching"
        else
        log "ALREADY FINISHED : $pipeline : sketching"
    fi 
###############################################################################
## step-04: mashing
    if [ ! -f $raw_files/tmp/all.distance.for_R.tab ] ; then 
        log "STARTED : $pipeline : mashing"
        /home/groups/VEO/tools/mash/v2.3/mash \
		dist \
		-p 80 \
		$raw_files/msh/ref_mash_sketch.msh \
		$raw_files/msh/mash_sketch.msh \
		> $raw_files/distance/all.distance.tab
        log "FINISHED: $pipeline : mashing"
        else 
        log "ALREADY FINISHED : $pipeline : mashing"
    fi
###############################################################################
## step-05: parsing
	if [ ! -d $raw_files/msh/distance/close_relatives ] ; then 
	    (mkdir -p $raw_files/msh/distance/close_relatives )> /dev/null 2>&1
		log "STARTED : $pipeline : parsing"
		for i in $(cat $list ); do 
			if [ ! -f $raw_files/msh/distance/tmp/$i.distance.tab ] ; then 
				grep -w "$i" results/0671_identifying_close_relative_by_ANI_by_mash/raw_files/msh/distance/all.distance.tab \
				| sort -t$'\t' -k3 | head -5 | awk '{print $1}' | awk -F'/' '{print $NF}' \
				> $raw_files/msh/distance/close_relatives/$i.top5_close_relatives.tab
			fi
		done
		cat $raw_files/msh/distance/close_relatives/*.top5_close_relatives.tab | sed 's/.fasta//g' | sort -u > $raw_files/list.top5_close_relatives.txt
		log "FINISHED: $fpipeline : parsing"
		else 
		log "ALREADY FINISHED : $pipeline : parsing"
	fi
###############################################################################