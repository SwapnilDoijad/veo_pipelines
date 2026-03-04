#!/bin/bash
#SBATCH --job-name=0009_demultiplexing_by_barbell
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu
#SBATCH --output=results/0009_demultiplexing_by_barbell/tmp/slurm/%j.out
#SBATCH --error=results/0009_demultiplexing_by_barbell/tmp/slurm/%j.err
#SBATCH --cpus-per-task=40
###############################################################################
echo "SBATCH STARTED : 0009_demultiplexing_by_barbell"
###############################################################################  
## step-01: preparation
    pipeline=0009_demultiplexing_by_barbell
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    fastq_file_path=$(grep "my_fastq_path" $parameters | awk '{print $2}')
    sublist=$wd/tmp/lists/ABC
    cpus=$SLURM_CPUS_PER_TASK

    export CARGO_HOME=/home/groups/VEO/tools/cargo 
    export RUSTUP_HOME=/home/groups/VEO/tools/rust 
    barbell="/home/groups/VEO/tools/barbell/v0.3.0/barbell/target/release/barbell"
    kit=$( grep my_kit $parameters | awk '{print $2}' )
    custom_primers=$( grep my_custom_primers $parameters | awk '{print $2}' )
    F_primer=$(grep my_F_primer $parameters | awk '{print $2}')
    R_primer=$(grep my_R_primer $parameters | awk '{print $2}')
    primer_sequences=$(grep my_primer_sequences $parameters | awk '{print $2}')
    fastq=$( grep my_fastq_path $parameters | awk '{print $2}' )

    if [ $primer_sequences == "Single" ] ; then
        filters="/home/groups/VEO/scripts_for_users/supplementary_scripts/0009_demultiplexing_by_barbell.single_end_FR_RC.txt"
        suffix="single_end_FR_RC"
    elif [ $primer_sequences == "Dual" ] ; then
        filters="/home/groups/VEO/scripts_for_users/supplementary_scripts/0009_demultiplexing_by_barbell.dual.txt"
        suffix="dual"
    elif [ $primer_sequences == "Both" ] ; then
        filters="/home/groups/VEO/scripts_for_users/supplementary_scripts/0009_demultiplexing_by_barbell.single_end_FR_RC_and_dual.txt"
        suffix="single_end_FR_RC_and_dual"
    else
        ## default
        filters="/home/groups/VEO/scripts_for_users/supplementary_scripts/0009_demultiplexing_by_barbell.single_end_FR_RC_and_dual.txt"
    fi
###############################################################################
	log "STARTED: $pipeline: $kit -----------------------------" 
###############################################################################
## kit-based demultiplexing
    if [ $custom_primers == "No" ] ; then

        for i in $( cat $sublist ) ; do
            mkdir -p $raw_files/$i
            # Annotate
            $barbell kit -k $kit -i $fastq_file_path/$i.fastq -o $raw_files/$i --maximize
            
            # Trim
            $barbell trim \
                -i $raw_files/$i/filtered.tsv \
                -r "$raw_fastq" \
                -o $raw_files/trimmed
        done 

    fi
############################################################################### 
## for NON-kit based demultiplexing
    if [ $custom_primers == "Yes" ] ; then

    for primer_id in $(cat $sublist ); do 
    	echo $primer_id

        mkdir $raw_files/${primer_id}
        mkdir $raw_files/${primer_id}/fastq

        F_FILES=($wd/tmp/primers/mut*_F.txt)
        R_FILES=($wd/tmp/primers/mut*_R.txt)

        F_LIST=$(IFS=,; echo "${F_FILES[*]}")
        R_LIST=$(IFS=,; echo "${R_FILES[*]}")

        F_TAGS=$(printf 'Ftag,'%.0s "${F_FILES[@]}")
        R_TAGS=$(printf 'Rtag,'%.0s "${R_FILES[@]}")
        TAGS="${F_TAGS}${R_TAGS%,}"

        barbell annotate -q "${F_LIST},${R_LIST}" -b "${TAGS}"

        ## annotate reads
            $barbell annotate \
            -i $fastq \
            -q $wd/tmp/primers/${primer_id}_F_primers.txt,$wd/tmp/primers/${primer_id}_R_primers.txt \
            -b Ftag,Rtag \
            -o $raw_files/${primer_id}/annotations.tsv \
            -t 16 > $raw_files/${primer_id}/log.annotate.txt 2>&1

                ## Optional : inspect patterns per read and manually create filters
                    ## genereally
                            ## Single-end left Ftag
                            ## Ftag[fw, *, @left(0..250), >>]

                            ## Single-end left Rtag
                            ## Rtag[fw, *, @left(0..250), >>]

                            ## Dual-end: F on left, R on right
                            ## Ftag[fw, *, @left(0..250), >>]__Rtag[<<, rc, *, @right(0..250)]

                            ## Dual-end: R on left, F on right
                            ## Rtag[fw, *, @left(0..250), >>]__Ftag[<<, rc, *, @right(0..250)]

                    #     $barbell  inspect \
                    #     -i $raw_files/${primer_id}/annotations.tsv \
                    #     -o $raw_files/${primer_id}/pattern_per_read.tsv \
                    #     >> $raw_files/${primer_id}/log.txt 2>&1

        ## create filters file by replacing * with the primer sequence id in the template filters file 
        ## This is important to ensure that only the reads with the specific primer ids are retained
        ## else reads with other primer ids will also be retained
        ## for e.g 
            # 79278 mut1_1_F
            # 79279 mut1_1_R
            # 5 mut1_4_F        # wrong reads due to * in filter
            # 3 mut1_4_R        # wrong reads due to * in filter
            # 9 mut1_5_F        # wrong reads due to * in filter
            # 10 mut1_5_R       # wrong reads due to * in filter

                sed "s/\*/~$primer_id/g" $suppl_scripts/$pipeline.${suffix}.txt \
                > $wd/tmp/filters/filters.${primer_id}.txt

                $barbell filter \
                -i $raw_files/${primer_id}/annotations.tsv \
                -f $wd/tmp/filters/filters.${primer_id}.txt \
                -o $raw_files/${primer_id}/filtered.txt \
                > $raw_files/${primer_id}/log.filter.txt 2>&1

            ## retain only reads with up to 2 mismatches in barcode and flanking regions 
                awk -F'\t' 'NR==1 || $12 <= 2 || $11 <= 2' $raw_files/${primer_id}/filtered.txt \
                > $raw_files/${primer_id}/filtered.lowcost.txt 

    
        if [ $primer_sequences == "Single" ] ; then
            ## single-end trimming
            	$barbell trim \
            	-i $raw_files/${primer_id}/filtered.lowcost.txt \
            	-r $fastq \
            	-o $wd/fastq \
            	>> $raw_files/${primer_id}/log.trim.${suffix}.txt 2>&1

        elif [ $primer_sequences == "Dual" ] || [ $primer_sequences == "Both" ] ; then
            ## dual-end or both trimming
            	$barbell trim \
            	-i $raw_files/${primer_id}/filtered.lowcost.txt \
            	-r $fastq \
            	-o $raw_files/${primer_id}/fastq \
            	>> $raw_files/${primer_id}/log.trim.${suffix}.txt 2>&1
        fi


        ## combine files and reverse complement as needed
            mkdir -p $raw_files/${primer_id}/fastq2
            for i in $( ls $fastq/raw_files/${primer_id}/fastq | awk -F'_' '{print $1"_"$2}' | sort | uniq ); do 
                echo $primer_id $i

                cp $raw_files/${primer_id}/fastq/${i}_F_fw.trimmed.fastq \
                $raw_files/${primer_id}/fastq2/${i}_F_fw.trimmed.fastq

                if [ -f $raw_files/${primer_id}/fastq/${i}_R_fw.trimmed.fastq ]; then
                    python3 $suppl_scripts/$pipeline.RC_fastq.py \
                    -i $raw_files/${primer_id}/fastq/${i}_R_fw.trimmed.fastq \
                    -o $raw_files/${primer_id}/fastq2/${i}_R_fw.trimmed.rc.fastq
                fi

                if [ -f $raw_files/${primer_id}/fastq/${i}_F_fw__${i}_R_rc.trimmed.fastq ]; then
                    cp $raw_files/${primer_id}/fastq/${i}_F_fw__${i}_R_rc.trimmed.fastq \
                    $raw_files/${primer_id}/fastq2/${i}_F_fw__${i}_R_rc.trimmed.rc.fastq
                fi


                if [ -f $raw_files/${primer_id}/fastq/${i}_R_fw__${i}_F_rc.trimmed.fastq ]; then
                    python3 $suppl_scripts/$pipeline.RC_fastq.py \
                    -i $raw_files/${primer_id}/fastq/${i}_R_fw__${i}_F_rc.trimmed.fastq \
                    -o $raw_files/${primer_id}/fastq2/${i}_R_fw__${i}_F_rc.trimmed.rc.fastq
                fi

                cat $raw_files/${primer_id}/fastq2/${i}_*.fastq \
                > $wd/fastq/${i}.fastq

                reads=$( count_reads_from_fastq	$wd/fastq/${i}.fastq )
        	    echo -e "${primer_id}\t${i}\t${reads}" >> $wd/summary.reads_per_primer.${suffix}.txt
            done

    done
    fi

###############################################################################
## just trimp adapters. 
    # barbell annotate -q adapters.fasta -b Fflank -i reads.fastq -o anno.tsv -t 10
    # barbell filter -i anno.tsv -o filtered.tsv
    # barbell trim -i filtered.tsv -r reads.fastq -o trimmed
###############################################################################
	log "FINISHED: $pipeline -----------------------------" # && clean
###############################################################################