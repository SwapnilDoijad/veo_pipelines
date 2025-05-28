###############################################################################
## 00 Preparation
    pipeline=0993_calculate_abundance_from_fastq_new_approach
	source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh 
	## make directory

		mkdir -p $wd/tmp > /dev/null 2>&1
		mkdir -p $raw_files > /dev/null 2>&1
		fastq=/home/xa73pav/projects/p_rene_amplicon/results/0008_basecalling_demultiplexing_nanopore_singlex_by_guppy_gpu/raw_files/raw_reads.10.fastq
		list_pattern_FR_08bp=list.pattern.FR.08bp.txt

		upstream_tmp=$(echo $list_pattern_FR_08bp | awk -F'.' '{print $(NF-1)}'| sed 's/^0*//' | sed 's/bp//g')
		upstream=$(( 44 - $upstream_tmp ))
###############################################################################
## 01 convert fastq to fasta
	if [ ! -f results/0993_calculate_abundance_from_fastq_new_approach/raw_files/raw_reads.fastq.10.fasta ] ; then
		log "STARTED : converting fastq to fasta"
		python3 /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/fastq2fasta.multiprocessing.py \
		-i $fastq -o results/0993_calculate_abundance_from_fastq_new_approach/raw_files/raw_reads.fastq.10.fasta 
		log "FINISHED : converting fastq to fasta"
		else 
		log "ALREADY FINISHED : converting fastq to fasta"
		fasta=results/0993_calculate_abundance_from_fastq_new_approach/raw_files/raw_reads.fastq.10.fasta 
	fi

	## wc -l results/0008_basecalling_demultiplexing_nanopore-singlex_by_guppy-gpu/pod5_fast5_basecalled_guppy_gpu/all_fastqs/raw_reads.fastq.10

###############################################################################
## 02 get only first 150 bp
	if [ ! -f $raw_files/raw_reads.fastq.10.first_150bp.fasta ] ; then 
		log "STARTED : get only first 150 bp"
		source /home/groups/VEO/tools/python/biopython/bin/activate
		python3 $suppl_scripts/0993_calculate_abundance_from_fastq_new_approach.01.py \
		-i $fasta -o $raw_files/raw_reads.fastq.10.first_150bp.fasta
		log "FINISHED : get only first 150 bp"
		else
		log "ALREADY FINISHED : get only first 150 bp"
	fi
###############################################################################
## 03 find the pattern ($list_pattern_FR_08bp) and get the $upstream region
		# if [ ! -d $raw_files/02_reads_out ] ; then 
			log "STARTED : finding pattern "
			( mkdir $raw_files/02_reads_out ) > /dev/null 2>&1
			# if pattern match then write 45bp it to a file 
				for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
					log "STARTED : finding pattern : $barcodeprimer"
					python3 $suppl_scripts/$pipeline.02.py \
					-i $barcodeprimer \
					-f $raw_files/raw_reads.fastq.10.first_150bp.fasta \
					-u $upstream \
					-o $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna
					log "FINISHED : finding pattern : $barcodeprimer"
				done

			# clean header line (remove everything after space)
				for barcodeprimer in $(cat $list_pattern_FR_08bp); do 
					echo $barcodeprimer
					sed -i 's/ .*//g' $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna ; 
					cat $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna | grep -v ">" \
					> $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna_without_header
				done 

			## get the header ids
				for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
				    grep ">" $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna | sed "s/>//g" \
					> $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna.txt 
				done  

			## get only barcodes, and filter the files to get sequences with atleast 20 bp
				source /home/groups/VEO/tools/python/biopython/bin/activate
				while IFS= read -r line; do
				    echo "Line: $line"
				    barcodeprimer=$(echo $line | awk '{print $1}' )
				    primer_length=$(echo $line | awk '{print $2}' )

				    # sed -i 's/@//g' $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna ; 

				    python3 remove_bp_from_45.py -i $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.fna \
				    -s $barcodeprimer -r $primer_length -o $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna

					  python3 filter_fasta_file_for_length.py \
					  -i $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna \
					  -o $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna \
					  -l 20
						
				    lines=$(wc -l $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna | awk '{print $1}')
				    number_of_reads=$(( $lines / 2))
				    echo $barcodeprimer $number_of_reads

				done < $list_pattern_FR_08bp.2

			log "FINISHED : finding pattern "
		# 	else
		# 	log "ALREADY FINISHED : finding pattern "
		# fi
###############################################################################
## 04 





exit

# list_RC=list.brady.rhizo.RC.08.txt 
cutoffs=( 0.60 0.70 0.80 0.90 )
# cutoffs=( 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 )









## step-04: count how many reads we got from pattern 
    # total_reads=0
    # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
    #     number_of_reads=$(expr $(wc -l < $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna ) / 2)
    #     echo $barcodeprimer $number_of_reads
        # echo $barcodeprimer $number_of_reads >> stat.tsv
        # total_reads=$(( $total_reads + $number_of_reads ))
    # done 

    # percentage_total_reads=$(( 100 * $total_reads / 3390450 ))
    # echo "total_reads : $total_reads ($percentage_total_reads)" >> stat.tsv
## step-05: clustering
## step-05a: uclust
    # for cutoff in "${cutoffs[@]}" ; do 
    #     for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
    #         echo "uclust $barcodeprimer"
    #         /home/groups/VEO/tools/usearch/v11.0.667/usearch \
    #         --cluster_fast $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna \
    #         --uc usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_$cutoff.txt --id $cutoff  &> usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_$cutoff.log ;
                
    #         clusters=$(grep Clusters usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_$cutoff.log | awk '{print $2}')
    #         echo -e "USEARCH\t$cutoff\t$barcodeprimer\t$clusters" >> stat.tsv
    #     done 
    # done

    # ## get first 50 cluster
        # for cutoff in "${cutoffs[@]}" ; do 
        #     for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        #     echo $cutoff $barcodeprimer
        #     awk '$1 == "C" {print $3}' usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_$cutoff.txt | sort -n -r -k1,1 | head -50 | sed "1icutoff_$cutoff" > usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_$cutoff.tsv
        #     done 
        # done

        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        #     paste usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_*.tsv > usearch_out/$barcodeprimer.table.tsv ;
        # done

        ## create plots
            # source /home/groups/VEO/tools/python/pandas/bin/activate
            # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
            #     echo "plotting $barcodeprimer for uclust"
            #     python3 plot_linechart.py \
            #     -i usearch_out/$barcodeprimer.table.tsv \
            #     -o usearch_out/$barcodeprimer.table.tsv.png
            # done

            # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
            #     echo $barcodeprimer
            #     awk '$1 == "C" {print $0}' usearch_out/$list_pattern_FR_08bp.$barcodeprimer.cutoff_$cutoff.txt | sort -n -k3,3 | tail -20 
            # done 

## step-05b: cd-hit
    ## step-05b.1: cd-hit clustering
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
        #     for cutoff in "${cutoffs[@]}" ; do 
        #         echo "running cd-hit for $cutoff $barcodeprimer"
        #         /home/groups/VEO/tools/cd-hit/v4.8.1/cd-hit \
        #         -i $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna \
        #         -o cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.txt \
        #         -T 50 -M 10000 -t 5 -n 4 \
        #         -c $cutoff &> cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.log ;

        #         clusters=$(grep clusters cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.log | tail -1 | awk '{print $3}')
        #         echo -e "CD-HIT\t$cutoff\t$barcodeprimer\t$clusters" >> stat.tsv
        #         ( rm cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.tsv ) > /dev/null 2>&1
        #         python3 cdhit_count_number_of_reads.py -i cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.txt.clstr -o cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.tsv
        #         awk '{print $NF}' cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.tsv | sort -nr > cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.2.tsv
        #     done
        # done 

    ## step-05b.2: cd-hit get-first 50 clusters
        # ( rm cdhit/*.4.tsv ) > /dev/null 2>&1
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
        #     for cutoff in "${cutoffs[@]}" ; do 
        #         ## make or get 50 lines
        #             line_count=$(wc -l < "cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.2.tsv")
        #             desired_line_count=100

        #             if [ "$line_count" -lt "$desired_line_count" ]; then
        #                 lines_to_add=$((desired_line_count - line_count))
                        
        #                 rm cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.3.tsv
        #                 for ((i = 1; i <= lines_to_add; i++)); do
        #                     echo "0" >> cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.3.tsv
        #                     cat cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.2.tsv cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.3.tsv > cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.4.tsv
        #                 done

        #                 elif [ "$line_count" -gt "$desired_line_count" ]; then
        #                 head -n 50 cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.2.tsv > cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.4.tsv

        #             fi
        #             sed -i "1icutoff_$cutoff" cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.4.tsv
        #     done
        # done 

        ## combine 50 cluster 
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
        #     paste cdhit/*.$barcodeprimer.*.4.tsv > cdhit/$barcodeprimer.table.tsv ;
        # done 

    ## step-05b.3: create line plot of the data
        # source /home/groups/VEO/tools/python/pandas/bin/activate
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
        #     echo "plotting $barcodeprimer for cdhit"
        #     python3 plot_linechart.py \
        #     -i cdhit/$barcodeprimer.table.tsv \
        #     -o cdhit/$barcodeprimer.table.tsv.png
        # done

    ################ create a bar chart 
        ## first seperate reads from cluster 
            ## get read-ids from txt.clstr
                # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
                #     for cutoff in "${cutoffs[@]}" ; do 
                #         mkdir cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff
                #         python3 cdhit_seperate_read_ids.py \
                #         -i cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.txt.clstr \
                #         -o cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff/ ; 
                #     done
                # done 
            
            ## remove > sign, it take some time to write the file, so sed step can not be combined
                # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
                #     for cutoff in "${cutoffs[@]}" ; do 
                #         echo "running sed for $barcodeprimer $cutoff"
                #         find cdhit/$list_pattern_FR_08bp.$barcodeprimer.$cutoff/*.txt -type f -name "*.txt" | xargs sed -i 's/>//g' 
                #     done
                # done 

            ## get reads/sequences of each clusters in .fna files
                # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
                #     for cutoff in "${cutoffs[@]}" ; do 
                #         sed "s/ABC/$list_pattern_FR_08bp/g" tmp/sbatch_template/template.cdhit.get_reads.sbatch | sed "s/XYZ/$barcodeprimer/g" | sed "s/JKLMN/$cutoff/g" > tmp/sbatch/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.cdhit.get_reads.sbatch
                #         sbatch  tmp/sbatch/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.cdhit.get_reads.sbatch
                #     done 
                # done 

        ## create databases of the 44 bp barcode+primer sequence
            # queries=( list.barcodes.AAACAGGT.fasta list.barcodes.ATCGTCCG.fasta list.barcodes.ATCGTTGG.fasta list.barcodes.GCATTTGG.fasta )
            # for query in ${queries[@]}; do 
            #     /home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/makeblastdb \
            #     -in $query \
            #     -dbtype nucl -out tmp/databases/blast_db_$query
            # done 

        ## BLAST sequence from each cluster against each barcode to find the best match 
            # queries=( list.barcodes.AAACAGGT.fasta list.barcodes.ATCGTCCG.fasta list.barcodes.ATCGTTGG.fasta list.barcodes.GCATTTGG.fasta )
            # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
            #     for cutoff in "${cutoffs[@]}" ; do 
            #         for query in "${queries[@]}"; do 
            #             sed "s/ABC/$query/g" tmp/sbatch_template/template.cdhit.blast.FR.sbatch | sed "s/XYZ/$list_pattern_FR_08bp/g" | sed "s/JKLMN/$cutoff/g" > tmp/sbatch/$barcodeprimer.$cutoff.$query.cdhit.blast.FR.sbatch
            #             sbatch tmp/sbatch/$barcodeprimer.$cutoff.$query.cdhit.blast.FR.sbatch
            #         done 
            #     done 
            # done 

## step-05c: mmseq2
    ## need memory ## salloc --mem=80G
        # source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
        # conda activate mmseq2_v14.7e284
        # for cutoff in "${cutoffs[@]}" ; do 
        #     for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        #         echo "running mmseq2 for $barcodeprimer with $cutoff"
        #         mmseqs easy-cluster \
        #         $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna \
        #         $list_pattern_FR_08bp.$barcodeprimer.$cutoff.cluster tmp \
        #         --min-seq-id $cutoff -c 0.9 --cov-mode 1 \
        #         &> mmseq2/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.log ; 
        #         mv $list_pattern_FR_08bp.$barcodeprimer.$cutoff.cluster* mmseq2/

        #         clusters=$(grep "Number of clusters:" mmseq2/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.log | tail -1 | awk -F' ' '{print $4}' )
        #         echo -e "MMSEQ2\t$cutoff\t$barcodeprimer\t$clusters" >> stat.tsv
        #     done
        # done 

    ## get first 50 cluster
        # for cutoff in "${cutoffs[@]}" ; do 
        #     for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        #         echo $cutoff $barcodeprimer
        #         awk '{print $1}' mmseq2/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.cluster_cluster.tsv \
        #         | sort | uniq -c | sort -n -r -k1,1 | head -50 | awk '{print $1}' | sed "1icutoff_$cutoff" \
        #         > mmseq2/$list_pattern_FR_08bp.$barcodeprimer.$cutoff.2.tsv
        #     done 
        # done

        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        #     paste mmseq2/$list_pattern_FR_08bp.$barcodeprimer.*.2.tsv > mmseq2/$barcodeprimer.table.tsv ;
        # done

    ## create plots
        # source /home/groups/VEO/tools/python/pandas/bin/activate
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        #     echo "plotting $barcodeprimer for mmseq2"
        #     python3 plot_linechart.py \
        #     -i mmseq2/$barcodeprimer.table.tsv \
        #     -o mmseq2/$barcodeprimer.table.tsv.png
        # done

## step-06: BWA mapping 

    # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
    #     echo $barcodeprimer
    #     awk '/^>/{file=sprintf("%s/%s.'$barcodeprimer'.fasta", "'"tmp/bwa_index"'",substr($0,2)); print >file; next}{print >file}' "list.barcodes.$barcodeprimer.2.fasta"
    # done 

    # for fasta in $(ls tmp/bwa_index/); do 
    #     /home/groups/VEO/tools/bwa/v0.7.17/bwa index tmp/bwa_index/$fasta
    # done 


    source /home/groups/VEO/tools/python/biopython/bin/activate
    mismatches=(5 7 10)
    for mismatch in "${mismatches[@]}" ; do 
    for barcodeprimer in $(cat $list_pattern_FR_08bp ); do 
        for reference in $(ls tmp/bwa_index/*.$barcodeprimer.fasta | awk -F'/' '{print $NF}' ); do 
            # echo $barcodeprimer $reference

    #         (/home/groups/VEO/tools/bwa/v0.7.17/bwa aln \
    #         -k 7 -O 1 -E 1 -n $mismatch \
    #         tmp/bwa_index/$reference \
    #         $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna \
    #         > bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai ) > /dev/null 2>&1

    #         ( /home/groups/VEO/tools/bwa/v0.7.17/bwa samse \
    #         tmp/bwa_index/$reference \
    #         bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai \
    #         $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna \
    #         > bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam) > /dev/null 2>&1

    #         (/home/groups/VEO/tools/samtools/v1.17/bin/samtools sort \
    #         -o bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam \
    #         bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam) > /dev/null 2>&1

    #         (/home/groups/VEO/tools/samtools/v1.17/bin/samtools index \
    #         bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam) > /dev/null 2>&1

    #         count=$(/home/groups/VEO/tools/samtools/v1.17/bin/samtools \
    #         view -c -F 4 bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam)
            
            # /home/groups/VEO/tools/samtools/v1.17/bin/samtools view \
            # -F 4 bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam | cut -f 1 \
            # > bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam.mapped_read_ids.txt

            # /home/groups/VEO/tools/samtools/v1.17/bin/samtools view \
            # -f 4 bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam | cut -f 1 \
            # > bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam.unmapped_read_ids.txt

            # (/home/groups/VEO/tools/samtools/v1.17/bin/samtools view \
            # -b -F 4 bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam \
            # > bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam.mapped_read.bam) > /dev/null 2>&1

            # (/home/groups/VEO/tools/samtools/v1.17/bin/samtools fasta \
            # bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam.mapped_read.bam \
            # > bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam.mapped_read.bam.fasta) > /dev/null 2>&1

            # (python count_snps_from_sam.py \
            # -i bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam \
            # -o bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.counts.txt) > /dev/null 2>&1

            # echo $reference $mismatch $count 

            ## step-06b: weblogo
                ## first need to create equal length input (kind of alignment)
                    common_length=$(python3 filter_25_bp.py -i bwa_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$reference.$mismatch.sai.sam.bam.mapped_read.bam.fasta | sort -n -r -k2,2 | head -1 | awk '{print $1}')
                    length=$(( $common_length - 1 ))

                    python3 filter_fasta_file_for_length.py \
                    -i $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna \
                    -o $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.$length.fna \
                    -l $length

                    # lines=$(wc -l $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.$length.fna | awk '{print $1}')
                    # number_of_reads=$(( $lines / 2))
                    # echo $barcodeprimer $number_of_reads

                    echo "running weblogo for $barcodeprimer"
                        weblogo --units probability \
                        --format PDF < $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.$length.fna \
                        > weblogo/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.filtered.fna.$length.pdf
                     

        done 
    done 
    done





## step-07: find how good is clustering (the sequences of a given cluster how many match with different primers)
## step-07a: by minimap2
    ## create databases
        # queries=( list.barcodes.AAACAGGT.fasta list.barcodes.ATCGTCCG.fasta list.barcodes.ATCGTTGG.fasta list.barcodes.GCATTTGG.fasta )
        # for query in ${queries[@]}; do 
        #     /home/groups/VEO/tools/minimap2/v2.26/minimap2 \
        #     -k 7 -w 10 \
        #     -d tmp/databases/$query.mmi \
        #     $query
        # done 

    ## seperate each read to a file 
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
            # rm -rf $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer
            # source /home/groups/VEO/tools/python/biopython/bin/activate
            # mkdir $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer
            # python3 split_multifasta.py \
            # -i $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna \
            # -o $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer
        # done 

    ## alignment of each read
        ## need 80 CPus
        ## first remove @ character form file name and fasta header
            # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
            #     echo $barcodeprimer
            #     # python3 rename.py -p  $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer/
            #     # python3 replace.py -p  $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer/ -c "@"
            #     ls $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer/ | wc -l 
            # done 

    ## clustering by minimap2
        # for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
        #     sed "s/ABC/$list_pattern_FR_08bp/" tmp/sbatch_template/template.minimap2.sbatch \
        #     | sed "s/XYZ/$barcodeprimer/" > tmp/sbatch/$barcodeprimer.minimap2.sbatch
        #     sbatch tmp/sbatch/$barcodeprimer.minimap2.sbatch
        # done


###############################################################################
## discarded codes
## BLAST and find the mismatch


    ## BLAST 



        #     sed "s/ABC/$list_pattern_FR_08bp/g" tmp/sbatch_template/blast.sbatch | sed "s/XYZ/$barcodeprimer/g" > tmp/sbatch/$list_pattern_FR_08bp.$barcodeprimer.blast.sbatch
        #     sbatch tmp/sbatch/$list_pattern_FR_08bp.$barcodeprimer.blast.sbatch

        #     grep ">" $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna | sed 's/>//g' > $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna.list
        #     for partial_read in $(cat $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna.list | head -5 ) ; do 
        #         echo $partial_read
        #         python3 get_each_sequence_for_blast.py -i $raw_files/02_reads_out/$list_pattern_FR_08bp.$barcodeprimer.only_barcode.fna -H "$partial_read" -o $partial_read.fasta

        #         -db database/list.barcodes.FR.RC.fasta.db \
        #         -query $partial_read.fasta \
        #         -num_threads 80 -outfmt "6 qseqid sseqid qlen slen length mismatch qstart qend sstart send evalue bitscore qcovs pident qseq sseq"
        #         #-out blast_out/$list_pattern_FR_08bp.$barcodeprimer.tsv \

        #         rm $partial_read.fasta

        #     done 
        # done 

## step-08b: 
    # sort mmseq2/$list.$barcodeprimer.$cutoff.cluster_all_seqs.fasta | uniq > mmseq2/$list.$barcodeprimer.$cutoff.cluster_all_seqs.uniq.fasta
## step-09: analysis of complete read (700 bp )
    ## step-09a: 
        # source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate mmseq2_v14.7e284 

        # ## create databases
        #     queries=( "query_brady.fasta" "query_rhizo.fasta" )
        #     for query in ${queries[@]}; do 
        #         echo $query
        #         mmseqs createdb $query tmp/databases/$query
        #         mmseqs createindex tmp/databases/$query tmp/databases/
        #     done

        # ## run for brady
        #     for barcodeprimer in $(cat $list_pattern_FR_08bp ); do
        #         for cutoff in "${cutoffs[@]}" ; do 
        #             mmseqs easy-search examples/QUERY.fasta targetDB alnRes.m8 tmp
        #         done 
        #     done 