#!/bin/bash
#SBATCH --job-name 0084_annotation_fungi_by_funannotate
#SBATCH --partition=long
#SBATCH --output results/0084_annotation_fungi_by_funannotate/tmp/slurm/%j.out
#SBATCH --error results/0084_annotation_fungi_by_funannotate/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=80
#-- Command section ------------------------

    # sublist=results/0084_annotation_fungi_by_funannotate/tmp/lists/ABC
    sublist=list.fungal_fasta.txt
    # fasta_file_path=XYZ
###############################################################################
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate mamba_20231112_python_3.9 && conda activate funannotate

    ##00 create directories
    for i in $(cat $sublist); do 
        ( mkdir -p results/0084_annotation_fungi_by_funannotate/raw_files/$i ) > /dev/null 2>&1
    done 
    

    ##01 funannotate clean
    for i in $(cat $sublist); do 
        if [ ! -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.fasta ] ; then  
            echo "running funannotate clean for $i"
            # -i results/0044_genome_assembly_for_illumina_by_spades/raw_files/$i/contigs.fasta \
            funannotate clean \
            # -i /home/xa73pav/projects/DB_genomics/20240219_molsys_oneFungi/results/0044_genome_assembly_for_illumina_by_spades/raw_files/NCCPF-800076/contigs.fasta \
            -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.fasta
            else
            echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.fasta already exists"
        fi 
    done 


    ##02 funannotate sort
    for i in $(cat $sublist); do 
        if [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.fasta ]; then
            if [ ! -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.fasta ] ; then 
                mkdir results/0084_annotation_fungi_by_funannotate/raw_files/$i
                funannotate sort -b scaffold  \
                -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.fasta \
                -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.fasta
                else
                echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.fasta already exists"
            fi
            else
            echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.fasta does not exist"
        fi
    done 

    ##03 funannotate mask
    for i in $(cat $sublist); do 
        if [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.fasta ]; then
            if [ ! -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.masked.fasta ] ; then 
                funannotate mask --cpus 80 \
                -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.fasta \
                -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.masked.fasta
                else
                echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.masked.fasta already exists"
            fi
            else
            echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.fasta does not exist"
        fi
    done 

    ##04 predict genes
    for i in $(cat $sublist); do 
        if [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.masked.fasta ]; then
            if [ ! -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/predict_results/*.gbk ] ; then
                mkdir results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate

                funannotate predict \
                -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.masked.fasta  \
                -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate \
                --species "Trichophyton indotineae" \
                --cpus 80
                else
                echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/predict_results/*.gbk already exists"
            fi
            else 
            echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/$i.cleaned.sorted.masked.fasta does not exist"
        fi
    done 

    ##05 annotate genes: run iprscan
        for i in $(cat $sublist); do 
            if [ -d results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate ]; then 
                if [ ! -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/iprscan.xml ] ; then 
                echo "running iprscan for $i"   

                funannotate iprscan \
                -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate \
                --iprscan_path /home/groups/VEO/tools/interproscan/v5.66-98.0/interproscan-5.66-98.0/interproscan.sh \
                -m local --cpus 80 
                else
                echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/iprscan.xml already exists"
                fi
            else
            echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate does not exist"
            fi
        done 

    ##06 annotate genes: run antismash
        # for i in $(cat $sublist); do 
        #     if [ -d results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate ]; then 
        #         if [ ! -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/antiSMASH.results.gbk ] ; then 
        #             echo "running antismash for $i"

        #             funannotate remote \
        #             -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate \
        #             -m antismash \
        #             -e swapnil.doijad@gmail.com
        #             else
        #             echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/antiSMASH.results.gbk already exists"
        #         fi 
        #         else
        #         echo "results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate does not exist"
        #     fi
        # done

    ##07 annotate genes: run final annotation command
        for i in $(cat $sublist); do 
        rm -rf results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate_final_annotations
            if [ ! -d results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate_final_annotations ] ; then
                mkdir results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate_final_annotations
                ## if antismash and iprscan present 
                # if [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/iprscan.xml ] && [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/antiSMASH.results.gbk ]; then
                #     echo "runnig final funannotate step for $i with antismash and iprscan files"
                #     funannotate annotate \
                #     -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate \
                #     -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate_final_annotations \
                #     --antismash results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/antiSMASH.results.gbk \
                #     --iprscan results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/iprscan.xml \
                #     --species "Trichophyton indotineae" --cpus 80

                    # elif [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/iprscan.xml ] ; then
                    echo "runnig final funannotate step for $i with iprscan files"
                    funannotate annotate \
                    -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate \
                    -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate_final_annotations \
                    --iprscan results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/iprscan.xml \
                    --species "Trichophyton indotineae" --cpus 80

                    # elif [ -f results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/antiSMASH.results.gbk ] ; then
                    # echo "runnig final funannotate step for $i with antismash files"
                    # funannotate annotate \
                    # -i results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate \
                    # -o results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate_final_annotations \
                    # --antismash results/0084_annotation_fungi_by_funannotate/raw_files/$i/funannotate/annotate_misc/antiSMASH.results.gbk \
                    # --species "Trichophyton indotineae" --cpus 80  
                #     else
                #     echo "antismash and iprscan files not present for $i"
                # fi
            fi
        done 
###############################################################################