#!/bin/bash
###############################################################################
## header
    pipeline=0171_comparative_genomics_core_pan_by_panaroo
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    log "STARTED : 0171_comparative_genomics_core_pan_by_panaroo ---------------"
###############################################################################
## step-01: preparation 

    wd=results/0171_comparative_genomics_core_pan_by_panaroo

    if [ -f list.prophage_fasta.txt ]; then 
        list=list.prophage_fasta.txt
        gff_dir=results/0083_annotation_prophage_by_pharokka/raw_files
        elif [ -f list.bacterial_fasta.txt ]; then
        list=list.bacterial_fasta.txt
        gff_dir=results/0081_annotation_by_prokka/raw_files
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g' | sed 's/list\.//g' | sed 's/\.txt//g'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi

    #echo "Wish to run ClonalFrameML?"
    #read CFML_ans

    create_directories_structure_1 $wd
    (mkdir -p $wd/tmp/gff) > /dev/null 2>&1

    log "Copying gff files to $wd/raw_files"
    for F1 in $(cat $list);do
        cp $gff_dir/$F1/$F1.gff $wd/tmp/gff/$F1.gff 
    done

    ## parameter file 
    
    
###############################################################################
## step-02: run panaroo through sbatch (80 CPUs, 200 GB memory)

    cp /home/groups/VEO/scripts_for_users/supplementary_scripts/0171_comparative_genomics_core_pan_by_panaroo.sbatch \
    $wd/tmp/sbatch/0171_comparative_genomics_core_pan_by_panaroo.sbatch
    
    sbatch $wd/tmp/sbatch/0171_comparative_genomics_core_pan_by_panaroo.sbatch > /dev/null 2>&1

    log "SUBMITTED : panaroo sbatch --------------------------------------------"

    while [ ! -f "$wd/raw_files/summary_statistics.txt" ]; do
        log "WAITING : panaroo to finish"
        sleep 60
    done
    log "FINISHED : panaroo"
    cp "$wd/raw_files/summary_statistics.txt" $wd/summary.txt

###############################################################################
## footer
    log "ENDED : 0171_comparative_genomics_core_pan_by_panaroo -----------------"
###############################################################################


    # snp-sites -m -p -o $wd/extracted-snps  $wd/raw_files/core_gene_alignment.aln

    # (fasttree -nt -gtr < $wd/extracted-snps.snp_sites.aln > $wd/extracted-snps.snp_sites.aln.fasttree.tree)> /dev/null 2>&1

    # (fastme -i $wd/extracted-snps.phylip -o $wd/tree.fastme.nwk -b 100 -n -d)> /dev/null 2>&1

    # (raxmlHPC -f a -m GTRGAMMA -p 12345 -x 12345 -# 100 -s $wd/extracted-snps.phylip -n T20 )> /dev/null 2>&1

    # mv RAxML_bipartitions.T20 $wd/

    # rm *.T20
    # rm *.T19

    # rm *.phy_fastme_stat.txt
    # rm *.phy_fastme_boot.txt

    # Core_genome_Rec_unfiltered_length=$(bioawk -c fastx '{ print $name, length($seq) }' <$wd/raw_files/core_gene_alignment.aln | awk 'NR==1 {print $2}' )
    # Core_genome_Rec_unfiltered_SNVs=$(bioawk -c fastx '{ print $name, length($seq) }' <$wd/extracted-snps.snp_sites.fasta | awk 'NR==1 {print $2}' )

    # echo "$Core_genome_length $Core_genome_Rec_unfiltered_SNVs" > $wd/ClonalFrameML/stat.tab
    # rm -rf $wd/gff
    # echo "completed.... step-16 panaroo --------------------------------------------"

###############################################################################
##Run ClonanFrameML
    # if [ "$CFML_ans" = "y" ] ; then
    #     echo "running clonalFrameML"
    #     (mkdir $wd/ClonalFrameML) > /dev/null 2>&1
    #     ClonalFrameML $wd/extracted-snps.snp_sites.aln.fasttree.tree $wd/raw_files/core_gene_alignment.aln $wd/ClonalFrameML/ClonalFrameML_output
    #     Rscript /home/swapnil/tools/ClonalFrameML-master/src/cfml_results.R $wd/ClonalFrameML/ClonalFrameML_output
    #     /home/swapnil/tools/maskrc-svg-master/maskrc-svg.py --aln $wd/raw_files/core_gene_alignment.aln --out $wd/ClonalFrameML/core_gene_alignment.aln.maskrc.fasta $wd/ClonalFrameML/ClonalFrameML_output
    #     snp-sites -m -o $wd/ClonalFrameML/core_gene_alignment.aln.maskrc.fasta.snp_sites.fasta $wd/ClonalFrameML/core_gene_alignment.aln.maskrc.fasta
    #     fasttree -nt -gtr < $wd/ClonalFrameML/core_gene_alignment.aln.maskrc.fasta.snp_sites.fasta > $wd/ClonalFrameML/core_gene_alignment.aln.maskrc.fasta.snp_sites.fasta.fasttree.tree
    #     Core_genome_Rec_filtered_SNVs=$(bioawk -c fastx '{ print $name, length($seq) }' <$wd/ClonalFrameML/core_gene_alignment.aln.maskrc.fasta.snp_sites.fasta | awk 'NR==1 {print $2}' )
    #     echo "$Core_genome_length $Core_genome_Rec_unfiltered_SNVs $Core_genome_Rec_filtered_SNVs" > $wd/ClonalFrameML/stat.tab
    # fi
###############################################################################

