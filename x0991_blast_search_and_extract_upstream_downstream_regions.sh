#!/bin/bash
###############################################################################
echo "script 0991 extract upstream downstream region started -------------------------"
###############################################################################
## step-01: preparation

    blastn=/home/groups/VEO/tools/ncbi-blast/v2.14.0+/bin/blastn
    fasta_formatter=/home/groups/VEO/tools/fastx_toolkit/v0.0.14/bin/fasta_formatter
    bedtool=/home/groups/VEO/tools/bedtools2/v2.31.0/bin/bedtools

    # if [ -f list.prophage_fasta.txt ]; then 
    #     list=list.prophage_fasta.txt
    # elif [ -f list.bacteria_fasta.txt ]; then 
    #     list=list.bacteria_fasta.txt
    # else
    #     echo "provide list file (for e.g. all)"
    #     echo "-------------------------------------------------------------------------"
    #     ls list.*.txt | sed 's/ /\n/g'
    #     echo "-------------------------------------------------------------------------"
    #     read l
    #     list=$(echo "list.$l.txt")
    # fi 

    if [ -f list.query_subject.tsv ]; then 
        input_file=list.query_subject.tsv 
        else
        echo "-------------------------------------------------------------------------"
        echo "provide a tab-seperated file listing path of query fasta (usually genes) and respective subject fasta (usually genomes)"
        echo -e "data/genes/query_1.fasta\tdata/genomes/subject_5.fasta"
        echo -e "data/genes/query_2.fasta\tdata/genomes/genome3.fasta"
        echo -e "data/genes/query_3.fasta\tdata/genomes/genome-2.fasta"
        echo "-------------------------------------------------------------------------"
        read input_file 
    fi

    queries=$(awk '{print $1}' $input_file)
    subjects=$(awk '{print $2}' $input_file)

    #echo how much bp upstream and downstream?
    #read UpDown
    UpDown=$(echo 500)

    path1=results/0991_extract_U_D

    (mkdir -p $path1/tmp)> /dev/null 2>&1
    (mkdir -p $path1/fasta)> /dev/null 2>&1
    (mkdir -p $path1/fasta_extracted/discarded)> /dev/null 2>&1

###############################################################################
## step-02: BLAST 

    for query in $( echo $queries | tr ' ' '\n'); do 
        subject=$(grep $query $input_file | awk '{print $2}')
        query_id=$( echo $query | awk -F'/' '{print $NF}' | sed 's/\.fasta//g' )
        subject_id=$( echo $subject | awk -F'/' '{print $NF}' | sed 's/\.fasta//g' )
        ## format fasta 
        sed 's/>.*/NNNNNNNNNN/g' $query | sed '0,/NNNNNNNNNN/s///' | sed "1i "'>'$query_id"" | sed '/^$/d' | sed 's/ /_/g' > $path1/fasta/"$query_id".fasta2
        $fasta_formatter -i $path1/fasta/"$query_id".fasta2 -o $path1/fasta/"$query_id".fasta ;
        rm $path1/fasta/"$query_id".fasta2 

        sed 's/>.*/NNNNNNNNNN/g' $subject | sed '0,/NNNNNNNNNN/s///' | sed "1i "'>'$subject_id"" | sed '/^$/d' | sed 's/ /_/g' > $path1/fasta/"$subject_id".fasta2
        $fasta_formatter -i $path1/fasta/"$subject_id".fasta2 -o $path1/fasta/"$subject_id".fasta ;
        rm $path1/fasta/"$subject_id".fasta2  

        ## blast the query against the subject
        ($blastn -subject $subject -query $query -out $path1/tmp/"$query_id"."$subject_id".custom-gene-blast.tmp -max_target_seqs 1 -max_hsps 1 -evalue 1e-10 -outfmt "6 sseqid qseqid sstart send qstart qend slen qlen evalue bitscore length mismatch gaps pident qcovs")> /dev/null 2>&1
       
        if [ -s "$path1/tmp/"$query_id"."$subject_id".custom-gene-blast.tmp" ]; then
            start=$(awk 'NR==1 {print $3}' $path1/tmp/"$query_id"."$subject_id".custom-gene-blast.tmp )
            end=$(awk 'NR==1 {print $4}' $path1/tmp/"$query_id"."$subject_id".custom-gene-blast.tmp )
            if [ "$start" -gt "$end" ]; then
                echo "query: $query_id subject: $subject_id in 5'-3' direction, reverse-complementing"
                Forw=$(( $end - $UpDown ))
                Revr=$(( $start + $UpDown))
                if [ $Forw -lt 0 ] ; then Forw=0 ; fi
                if [ $Revr -lt 0 ] ; then Revr=$(awk '/^>/ {if (seq) print length(seq); seq="";next;} { seq = seq $0 } END { if (seq) print length(seq); }' $path1/fasta/"$subject_id".fasta ) ; fi
                (rm $path1/fasta/$subject_id.fasta.fai )> /dev/null 2>&1
                echo -e "$subject_id\t$Forw\t$Revr\t"$subject_id"_region" > $path1/tmp/$query_id.$subject_id.bed
                ($bedtool getfasta -fi $path1/fasta/$subject_id.fasta -bed $path1/tmp/$query_id.$subject_id.bed -name > $path1/fasta_extracted/"$query_id"_"$subject_id"_region.RC.fasta)> /dev/null 2>&1
                sed '1d' $path1/fasta_extracted/"$query_id"_"$subject_id"_region.RC.fasta | perl -pe 'chomp;tr/ACGTNacgtn/TGCANtgcan/;$_=reverse."\n"' | sed '1i >'$query_id'' > $path1/fasta_extracted/"$query_id"_"$subject_id"_region.fasta
                mv $path1/fasta_extracted/"$query_id"_"$subject_id"_region.RC.fasta $path1/fasta_extracted/discarded/
                else
                echo "query: $query_id subject: $subject_id in 5'-3' direction"
                Forw=$(( $start - $UpDown ))
                Revr=$(( $end + $UpDown ))
                if [ $Forw -lt 0 ] ; then Forw=0 ; fi
                if [ $Revr -lt 0 ] ; then Revr=$(awk '/^>/ {if (seq) print length(seq); seq="";next;} { seq = seq $0 } END { if (seq) print length(seq); }' $path1/fasta/"$subject_id".fasta ) ; fi
                (rm $path1/fasta/$subject_id.fasta.fai )> /dev/null 2>&1
                echo -e "$subject_id\t$Forw\t$Revr\t"$subject_id"_region" > $path1/tmp/$query_id.$subject_id.bed
                $bedtool getfasta -fi $path1/fasta/$subject_id.fasta -bed $path1/tmp/$query_id.$subject_id.bed -name > $path1/fasta_extracted/"$query_id"_"$subject_id"_region.fasta #)> /dev/null 2>&1
            fi  

            ## annotate the region
            # if [ "$annot" == "y" ]; then
            # prokka --quiet --outdir $path1/annotations/raw_files/$query_id --force --prefix $query_id --locustag $query_id --strain $query_id --rnammer $path1/fasta_extracted/"$query_id"_region.fasta
            # cp $path1/annotations/raw_files/$query_id/$query_id.gbk $path1/annotations/gbk/$query_id.gbk
            # fi

            echo "$query_id $subject_id" >> $path1/region_present_in_strains.list
            else
            echo "$query_id $subject_id" >> $path1/region_absent_in_strains.list
        fi
    done


###############################################################################
echo "script 0991 extract upstream downstrema region ended ---------------------------"
###############################################################################