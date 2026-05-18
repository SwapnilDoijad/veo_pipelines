#!/bin/bash
#SBATCH --job-name=0009_demultiplexing_by_barbell
#SBATCH --partition=short,standard,long,interactive,gpu-veo,gpu,gpu-test
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
    cpus=$SLURM_CPUS_PER_TASK
    list=list.${pipeline}.txt

    export CARGO_HOME=/home/groups/VEO/tools/cargo 
    export RUSTUP_HOME=/home/groups/VEO/tools/rust 
    barbell="/home/groups/VEO/tools/barbell/v0.3.0/barbell/target/release/barbell"
    barbell="/home/groups/VEO/tools/cargo/bin/barbell" # v0.3.2

    kit=$( grep my_kit $parameters | awk '{print $2}' )
    custom_primers=$( grep my_custom_primers $parameters | awk '{print $2}' )
    F_primer=$(grep my_F_primer $parameters | awk '{print $2}')
    R_primer=$(grep my_R_primer $parameters | awk '{print $2}')
    primer_sequences=$(grep my_primer_sequences $parameters | awk '{print $2}')
    fastq=$( grep my_fastq_path $parameters | awk '{print $2}' )
    data_type=$( grep my_data_type $parameters | awk '{print $2}' )

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

        mkdir -p $raw_files
        # Annotate

        if [ $data_type == "genome" ] ; then
            $barbell kit -k $kit -i $fastq -o $raw_files/$i --maximize
        elif [ $data_type == "amplicon" ] ; then
            $barbell kit -k $kit -i $fastq -o $raw_files
        fi  
        
        # Trim
        $barbell trim \
            -i $raw_files/$i/filtered.tsv \
            -r "$raw_fastq" \
            -o $raw_files/trimmed

    fi
############################################################################### 
## for NON-kit based demultiplexing
    if [ $custom_primers == "Yes" ] ; then

        mapfile -t F_FILES < <(printf '%s\n' "$wd"/tmp/primers/mut*_F.txt | sort -V)
        mapfile -t R_FILES < <(printf '%s\n' "$wd"/tmp/primers/mut*_R.txt | sort -V)

        F_LIST=$(IFS=,; echo "${F_FILES[*]}")
        R_LIST=$(IFS=,; echo "${R_FILES[*]}")

        F_TAGS=$(printf 'Ftag,'%.0s "${F_FILES[@]}")
        R_TAGS=$(printf 'Rtag,'%.0s "${R_FILES[@]}")
        TAGS="${F_TAGS}${R_TAGS%,}"

        ## annotate reads
        if [ ! -f $raw_files/annotations.tsv ] ; then
            log "Annotating reads"

            $barbell annotate \
            -q "${F_LIST},${R_LIST}" -b "${TAGS}" \
            -i $fastq \
            -o $raw_files/annotations.tsv \
            -t $SLURM_CPUS_PER_TASK 

            awk -F'\t' '{print $13}' $raw_files/annotations.tsv | sort | uniq -c | awk '{print $2, $1}' > $raw_files/annotations.summary.tsv

            else
            log "Annotation file already exists. Skipping annotation step."
        fi
    ############################################################################### 
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

        ## * = match any sample label
        ## If there are no groups then use * (Sample_1A1_F, Sample_2A1_F, etc.)
        ## uses ~substring matching. That is mainly for mixed experiments ( for example: group1_Sample_01, group1_Sample_02, group2_Sample_01, group2_Sample_02)
    ############################################################################### 
        for primer_id in $( cat $list ); do
            sed "s/\*/~$primer_id/g" ${suppl_scripts}/$pipeline.${suffix}.txt \
            > $wd/tmp/filters/filters.${primer_id}.txt
        done
    ############################################################################### 
    ## Filter
        for primer_id in $( cat $list ); do
                mkdir -p $raw_files/${primer_id}/fastq

                $barbell filter \
                -i $raw_files/annotations.tsv \
                -f $wd/tmp/filters/filters.${primer_id}.txt \
                -o $raw_files/${primer_id}/filtered.txt \
                > $raw_files/${primer_id}/log.filter.txt 2>&1

            ## aditional step for extra barcode cost
            ## retain only reads with up to X mismatches in flanking ($11) and barcode ($12) cost 
            ## Nanopore fank should be loose 10 (as its a flank and will have low QC)
                awk -F'\t' 'NR==1 || ($11 <= 10 && $12 <= 2)' \
                "$raw_files/${primer_id}/filtered.txt" \
                > "$raw_files/${primer_id}/filtered.lowcost.txt"

                python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/0009_demultiplexing_by_barbell.count.py \
                -p results/0009_demultiplexing_by_barbell/tmp/list.primers.txt \
                -i results/0009_demultiplexing_by_barbell/raw_files/annotations.tsv \
                -o results/0009_demultiplexing_by_barbell/raw_files/annotations.tsv.F10B2.tsv \
                -f 10 \
                -b 2

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