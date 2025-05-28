#!/bin/bash
#SBATCH --job-name=0131_phylogeny_by_snippy
#SBATCH --partition=interactive
#SBATCH --output=results/0131_phylogeny_by_snippy/tmp/slurm/%j.out
#SBATCH --error=results/0131_phylogeny_by_snippy/tmp/slurm/%j.err
#SBATCH --mem=50G
#SBATCH --cpus-per-task=40
############################################################################### 
## 00: preparations
    pipeline=0131_phylogeny_by_snippy
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    sublist=$wd/tmp/lists/ABC
    
    data_type=$(grep -w "my_data_type" $parameters | awk '{print $2}')
    phylogeny=$(grep -w "my_phylogeny" $parameters | awk '{print $2}')

    log "starting $pipeline"
###############################################################################
## 01: run snippy program
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh
    conda activate snippy_v2009
    if [ "$data_type" == "paired" ] ; then
        while IFS=$'\t' read -r ref forward_read reverse_read; do
            i=$( echo $ref | awk -F'/' '{print $NF}' | sed "s/.gbk//g")
            log "RUNNING: snippy for $data_type : $i"
            log "REFERENCE: $ref"
            log "FORWARD_READ: $forward_read"
            log "REVERSE_READ: $reverse_read"

            if [ ! -d $raw_files/$i ] ; then
                log "RUNNING: snippy for $i $data_type "
                mkdir $raw_files/$i 

                get_resource_stat "$wd"/tmp/resource_log/$i.snippy.tsv \
                snippy \
                --cpus $SLURM_CPUS_PER_TASK \
                --quiet \
                --prefix $i \
                --force \
                --outdir $raw_files/$i \
                --ref "$ref" \
                --pe1 $forward_read \
                --pe2 $reverse_read
                log "FINISHED: snippy for $i $data_type"
                else
                log "ALREADY FINISHED: snippy for $i $data_type"
            fi
        done < $wd/tmp/lists/ABC
    fi

    if [ "$data_type" == "single" ] ; then
        while IFS='\t' read -r ref reads; do
            i=$( echo $ref | awk -F'/' '{print $NF}' | sed "s/.gbk//g")
            log "RUNNING: snippy for $data_type : $i"
            log "REFERENCE: $ref"
            log "READs: $reads"

            if [ ! -d $raw_files/$i ] ; then
                log "RUNNING: snippy for $i $data_type "
                mkdir $raw_files/$i 

                get_resource_stat "$wd"/tmp/resource_log/$i.snippy.tsv \
                snippy \
                --cpus $SLURM_CPUS_PER_TASK --prefix $i \
                --force --mapqual 1 \
                --basequal 1 \
                --mincov 10 \
                --outdir $raw_files/$i \
                --ref $ref \
                --se $reads
                log "FINISHED: snippy for $i $data_type"
                else
                log "ALREADY FINISHED: snippy for $i $data_type"
            fi
        done < $wd/tmp/lists/ABC
    fi

    awk 'NR > 1' $raw_files/$i/$i.csv | sed "s/^/$i\,/" >> $wd/summary.csv
    (rm list.tmp ) > /dev/null 2>&1
    for i in $(cat $sublist); do
        echo $raw_files/$i >> list.tmp
    done

    wait_till_all_job_finished 0131_phylogeny_by_snippy

    if [ "$phylogeny" == "Yes" ] ; then
        log "STARTED: phylogeny"

        snippy-core --prefix core --ref $ref_seq $(cat list.tmp)
        mv core.* $raw_files/
        (rm list.tmp)> /dev/null 2>&1

        snp-sites -o $raw_files/clean.core.aln $raw_files/clean.full.aln

        snp-dists -q $raw_files/core.full.aln > $raw_files/core.full.aln.matrix.tsv

        conda deactivate

        /home/groups/VEO/tools/fastTreeMP/v2.1.11/FastTreeMP -gtr -nt $raw_files/clean.core.aln > $raw_filesclean.core.aln.nwk

    fi


exit
###############################################################################
    #snippy-clean_full_aln $raw_files/core.full.aln > $raw_files/clean.full.aln
    #run_gubbins.py -p gubbins $raw_files/clean.full.aln
    #snp-sites -b -c -o $raw_files/clean.core.aln $raw_files/clean.full.aln
    #FastTree -gtr -nt $raw_files/clean.core.aln > $raw_filesclean.core.aln.tree

## detailed analysis
    if [ "$answer2" == "y" ] ; then

        ##extract ref LOCUS_TAG
        ref=$(ls results/00_ref/ref.*.gbk )
        (rm "$ref_seq".csv) > /dev/null 2>&1
        (ugene --task=/home/swapnil/pipeline/tools/gbk2csv-Ugene.uwl --in=$ref_seq --out="$ref_seq".csv --format=csv) > /dev/null 2>&1 ;

    
        for i in $(cat $sublist); do
            grep "CDS" $raw_files/And1463/And1463.tab | awk -F'\t' 'FNR>1 {print $12}' | sort -u -k1,1 | sed '/^\s*$/d' > $raw_files/tmp/$i.locus.tmp
        done

        for i in $(cat $sublist);do
            (mkdir $raw_files/$i/tmp)> /dev/null 2>&1
            (rm $raw_files/tmp/01_SNPs_per_genes.tmp)> /dev/null 2>&1
            echo "counting SNPs in the genes of $i"
            echo "gene length SNPs SNPs% stop_gained dN/dS product" > $raw_files/$i/$i.13_snippy.SNPs-statistics.txt
            for F2 in $(cat $raw_files/tmp/$i.locus.tmp); do
                grep "$F2" $raw_files/$i/$i.tab > $raw_files/$i/tmp/$F2.tab
                A0=$(grep "$F2" "$ref_seq".csv | awk -F',' 'FNR==1 {print $5}' | sed "s/\"//g")
                A1=$(grep -c "$F2" $raw_files/$i/tmp/$F2.tab) #SNPs per gene
                A2=$(awk "BEGIN {print 100 * $A1 / $A0 }" | awk '{printf "%.2f\n", $1, $2}'); if [ -z "$A2" ] ; then A2=$(echo "0") ; fi > /dev/null 2>&1
                A3=$(grep "$F2" "$ref_seq".csv | awk -F',' 'FNR==1 {print $9}' | sed "s/\"//g" | sed "s/ /_/g")

                G0=$(grep -c 'initiator_codon_variant' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G0" ] ; then G0=$(echo "0") ; fi
                G1=$(grep -c 'initiator_codon_variant&non_canonical_start_codon' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G1" ] ; then G1=$(echo "0") ; fi
                G2=$(grep -c 'missense_variant' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G2" ] ; then G2=$(echo "0") ; fi
                G3=$(grep -c 'non_coding_transcript_variant' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G3" ] ; then G3=$(echo "0") ; fi
                G4=$(grep -c 'splice_region_variant&stop_retained_variant' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G4" ] ; then G4=$(echo "0") ; fi
                G5=$(grep -c 'start_lost' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G5" ] ; then G5=$(echo "0") ; fi
                G6=$(grep -c 'stop_gained' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G6" ] ; then G6=$(echo "0") ; fi
                G7=$(grep -c 'stop_lost&splice_region_variant' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G7" ] ; then G7=$(echo "0") ; fi
                G8=$(grep -c 'synonymous_variant' $raw_files/$i/tmp/$F2.tab) ; if [ -z "$G8" ] ; then G8=$(echo "1") ; fi		#Synonymous
                G9=$(($G0+$G1+$G2+$G3+$G4+$G5+$G6+$G7))					#Sum of all non-synonymous SNPs
                G10=$(awk "BEGIN {print $G9 / $G8 }" | awk '{printf "%.2f\n", $1, $2}') ; if [ -z "$G10" ] ; then G10=$(echo "0") ; fi > /dev/null 2>&1	#dN/dS non-synonymous to synonnymous ratio
                echo $F2 $A0 $A1 $A2 $G6 $G10 $A3 >> $raw_files/$i/$i.13_snippy.SNPs-statistics.txt
            done
        done

        ###############################################################################
        ## genomewide

        (rm $raw_files/tmp/ref.gene.list)> /dev/null 2>&1
        cat $ref_seq.csv | head -1 > $ref_seq.CDS.csv
        cat $ref_seq.csv | grep "CDS" >> $ref_seq.CDS.csv
        cat $ref_seq.CDS.csv | tr -s ' ' ',' | csvcut -c locus_tag | sed "s/\"//g" | sed -r '/^\s*$/d' >> $raw_files/tmp/ref.gene.list
        sed -i '/locus_tag/d' $raw_files/tmp/ref.gene.list # probelm if I combine with above line

        awk 'FNR>6 {print $2}' $raw_files/core.vcf > $raw_files/tmp/total_SNVs.list
        (rm $raw_files/tmp/total_SNVs.list.gene_found)> /dev/null 2>&1
        cp $raw_files/tmp/total_SNVs.list $raw_files/tmp/total_SNVs.list.tmp

        for gene in $(cat $raw_files/tmp/ref.gene.list); do
            start=$(grep "$gene" "$ref_seq".CDS.csv | awk -F',' 'FNR==1 {print $3}' | sed "s/\"//g")
            end=$(grep "$gene" "$ref_seq".CDS.csv | awk -F',' 'FNR==1 {print $4}' | sed "s/\"//g")

                for SNV in $(cat $raw_files/tmp/total_SNVs.list.tmp); do
                    if [[ "$SNV" -ge "$start" && "$SNV" -le "$end" ]] ; then
                    V1=$(grep "$gene" "$ref_seq".CDS.csv | awk -F',' '{print $8}' | sed "s/\"//g")
                    echo "$SNV $V1"
                    echo "start"$SNV"end" $V1 >> $raw_files/tmp/total_SNVs.list.gene_found
                    fi
                done
        done

        echo "running post-processing"
        awk '{print $1}' $raw_files/tmp/total_SNVs.list.gene_found | sed "s/start//g" | sed "s/end//g" > $raw_files/tmp/total_SNVs.list.gene_found.2
        cat $raw_files/tmp/total_SNVs.list.gene_found.2 $raw_files/tmp/total_SNVs.list.tmp | awk '{!seen[$0]++};END{for(i in seen) if(seen[i]==1)print i}' | sort -n | awk 'NF{print "start"$1"end" " intergenic"}' > $raw_files/tmp/total_SNVs.list.not_found
        cat $raw_files/tmp/total_SNVs.list.gene_found $raw_files/tmp/total_SNVs.list.not_found > $raw_files/tmp/total_SNVs.list.all

        echo "running post-processing: creating total_SNVs.list.all.final"
        (rm $raw_files/tmp/total_SNVs.list.all.final)> /dev/null 2>&1
        awk 'NF{print "start"$0"end"}' $raw_files/tmp/total_SNVs.list > $raw_files/tmp/total_SNVs.list.2
        for i in $(cat $raw_files/tmp/total_SNVs.list.2); do
            grep "$i" $raw_files/tmp/total_SNVs.list.all | awk 'FNR==1 {print $0}' >> $raw_files/tmp/total_SNVs.list.all.final
        done
        sed -i "s/start//g" $raw_files/tmp/total_SNVs.list.all.final
        sed -i "s/end//g" $raw_files/tmp/total_SNVs.list.all.final

        awk 'FNR>6 {print $0}' $raw_files/core.vcf > $raw_files/tmp/core.vcf.tmp

        paste $raw_files/tmp/total_SNVs.list.all.final $raw_files/tmp/core.vcf.tmp > $raw_files/core.vcf.annotated

        ##---------------------------------------------------
        cat $ref_seq.CDS.csv | tr -s ' ' ',' | csvcut -c product | sed "s/\"//g" | sed -r '/^\s*$/d' | sed "s/,/_/g" > $raw_files/tmp/ref.gene_product.list ;
        sed -i '1d' $raw_files/tmp/ref.gene_product.list ;
        paste $raw_files/tmp/ref.gene.list $raw_files/tmp/ref.gene_product.list > $raw_files/tmp/ref.gene_product.list.2
        total_number_of_column=$(awk 'FNR>6 {print NF; exit}' $raw_files/core.vcf)
        total_number_of_strains=$(( $total_number_of_column - 9 ))
        awk '{for(i=12;i<=NF;i++) t+=$i; print $2, $1, t; t=0}' $raw_files/core.vcf.annotated > $raw_files/tmp/core.vcf.2

        (rm $raw_files/tmp/gene_locus.Poly_sites.tab) > /dev/null 2>&1
        for gene_locus in $(cat $raw_files/tmp/ref.gene.list); do
            length=$(grep "$gene_locus" "$ref_seq".CDS.csv | awk -F',' '{print $5}' | sed "s/\"//g") ;
            gene_product=$(grep "$gene_locus" $raw_files/tmp/ref.gene_product.list.2 | awk '{print $2}' | sed "s/\"//g");
            Number_of_Polymorphic_sites=$(grep -c "$gene_locus" $raw_files/tmp/total_SNVs.list.all.final)
            Number_of_Polymorphic_sites_percentage=$(bc <<< "scale = 2; 100*$Number_of_Polymorphic_sites/$length") 
            total_number_of_mutation=$(grep "$gene_locus" $raw_files/tmp/core.vcf.2 | awk '{sum += $3} END {print sum}' ) ; if [ -z "$total_number_of_mutation" ] ; then total_number_of_mutation=$(echo "0") ; fi
            total_number_of_mutation_percentage=$(bc <<< "scale = 2; 100*$total_number_of_mutation/$length") ; 
            echo $gene_locus $gene_product $length $Number_of_Polymorphic_sites $Number_of_Polymorphic_sites_percentage $total_number_of_mutation $total_number_of_mutation_percentage >> $raw_files/tmp/gene_locus.Poly_sites.tab
        done
        ##---------------------------------------------------
        echo "running dN/dS"
        for i in $(cat $sublist); do
            (rm $raw_files/tmp/"$i".dNdS.tmp)> /dev/null 2>&1 
            echo $i > $raw_files/"$i"/tmp/"$i".dNdS.tmp
            for gene in $(cat $raw_files/tmp/ref.gene.list); do
                echo $i $gene
                V1=$(grep "$gene" $raw_files/"$i"/"$i".13_snippy.SNPs-statistics.txt | awk '{print $6}') ; if [ -z "$V1" ] ; then V1=$(echo "0") ; fi #dN/dS
                #V2=$(grep "$gene" $raw_files/"$i"/"$i".13_snippy.SNPs-statistics.txt | awk '{print $3}') ; if [ -z "$V1" ] ; then V1=$(echo "0") ; fi #SNVs
                echo "$V1" >> $raw_files/tmp/"$i".dNdS.tmp
                #echo "$V2" >> $raw_files/tmp/"$i".SNV.tmp
            done
        done

        paste $raw_files/tmp/*.dNdS.tmp > $raw_files/tmp/all.dNdS.tmp
        #paste $raw_files/tmp/*.SNV.tmp > $raw_files/tmp/all.SNV.tmp

        awk '{sum = 0; for (i = 1; i <= NF; i++) sum += $i; sum /= NF; print sum}' $raw_files/tmp/all.dNdS.tmp > $raw_files/tmp/all.dNdS.tmp.2
        awk '{sum = 0; for (i = 1; i <= NF; i++) sum += $i; sum /= NF; print sum}' $raw_files/tmp/all.SNV.tmp > $raw_files/tmp/all.SNV.tmp.2

        paste $raw_files/tmp/gene_locus.Poly_sites.tab $raw_files/tmp/all.dNdS.tmp.2 $raw_files/tmp/all.SNV.tmp.2 > $raw_files/results.csv

        sed -i '1 i\gene_locus gene_product length Number_of_Polymorphic_sites $Number_of_Polymorphic_sites_percentage total_number_of_mutation total_number_of_mutation_percentage dNdS SNVs' $raw_files/results.csv
        sed -i "s/\t/ /g" $raw_files/results.csv

        ssconvert $raw_files/results.csv $raw_files/results.csv.xlsx
        ###############################################################################
        # calculate transition by tranversion ratio

        (java -jar /home/swapnil/pipeline/tools/SnpSift.jar tstv $raw_files/core.vcf > $raw_files/tmp/tstv.csv) > /dev/null 2>&1
        awk 'NR==3 || NR==6' $raw_files/tmp/tstv.csv > $raw_files/tmp/tstv.csv.tmp
        sed -i 's/,/\t/g' $raw_files/tmp/tstv.csv.tmp

        ##-------------------
        awk '
        { 
            for (i=1; i<=NF; i++)  {
                a[NR,i] = $i
            }
        }
        NF>p { p = NF }
        END {    
            for(j=1; j<=p; j++) {
                str=a[1,j]
                for(i=2; i<=NR; i++){
                    str=str" "a[i,j];
                }
                print str
            }
        }' $raw_files/tmp/tstv.csv.tmp > $raw_files/tmp/tstv.csv.transposed.tmp
        ##-------------------

        for i in $(cat $sublist); do
            A1=$(grep $i $raw_files/tmp/tstv.csv.transposed.tmp)
            echo $A1 > $raw_files/tmp/$i.tstv.txt
        done

        rm $raw_files/tmp/tstv.csv.tmp
        rm $raw_files/tmp/tstv.csv.transposed.tmp
    fi
###############################################################################
echo "completed.... step-13 snippy -------------------------------------------"
############################################################################### 
