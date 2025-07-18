#!/bin/bash
###############################################################################
## header 
    pipeline=0050_genome_assembly_QC_by_quast
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED: 0050_genome_assembly_QC_by_quast --------------------"
###############################################################################
## step-01: preparation
    fasta_directory=$(grep -w "my_fasta_directory" $parameters | awk -F'\t' '{print $2}')
    ls $fasta_directory | grep .fasta | grep -v "samtools" | grep -v ".fai" | sed 's/\.fasta//g' > list.fasta.txt
    result_choise=$(grep -w "my_result_choise" $parameters | awk -F'\t' '{print $2}')

    create_directories_structure_1 $wd

    if [ $result_choise == "combined" ]; then
        log "STARTED : $pipeline for combined results"
        cp $suppl_scripts/$pipeline.combined.sbatch $wd/tmp/sbatch
        sbatch $wd/tmp/sbatch/$pipeline.combined.sbatch
    else
        log "STARTED : $pipeline for separated results"
        split_list $wd $list
        echo "Assembly	# contigs (>= 0 bp)	# contigs (>= 1000 bp)	# contigs (>= 5000 bp)	# contigs (>= 10000 bp)	# contigs (>= 25000 bp)	# contigs (>= 50000 bp)	Total length (>= 0 bp)	Total length (>= 1000 bp)	Total length (>= 5000 bp)	Total length (>= 10000 bp)	Total length (>= 25000 bp)	Total length (>= 50000 bp)	# contigs	Largest contig	Total length	GC (%)	N50	N90	auN	L50	L90	# N's per 100 kbp" > $wd/summary.tsv
        submit_jobs $wd $pipeline
    fi

###############################################################################
log "ENDED : 0050_genome_assembly_QC_by_quast ----------------------"
###############################################################################
