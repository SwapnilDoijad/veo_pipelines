#!/bin/bash
#SBATCH --job-name=0321_geneDNAstat_by_variscan
#SBATCH --partition=standard,short,long,interactive
#SBATCH --output=results/0321_geneDNAstat_by_variscan/tmp/slurm/%j.out.0071_QC_by_checkM
#SBATCH --error=results/0321_geneDNAstat_by_variscan/tmp/slurm/%j.err.0071_QC_by_checkM
#SBATCH --cpus-per-task=25
###############################################################################
## step-01: preparation
    pipeline=0321_geneDNAstat_by_variscan
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
    aligned_gene_sequences=$(grep my_aligned_gene_sequences $parameters | awk '{print $2}' )
    core_gene_list=$(grep my_core_gene_list $parameters | awk '{print $2}' )
###############################################################################
    source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    conda activate

    > $wd/genes.stat.tab
    for core_gene in $(cat $core_gene_list ); do
        log "running $core_gene"

        grep ">" $aligned_gene_sequences/$core_gene.aln.fas | sed 's/>//g'  | sed 's/;/_/g' > $raw_files/$core_gene.list
        names=$(cat $raw_files/$core_gene.list | tr "\n" " " )

        sed 's/IndivNames\ =\ /IndivNames\ =\ '"$names"'/g' \
        /home/groups/VEO/scripts_for_users/supplementary_scripts/parameter_files/variscan_conf.conf \
        > $raw_files/$core_gene.conf

        /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/convert_sequence_format.py \
        -i $aligned_gene_sequences/$core_gene.aln.fas \
        -o $raw_files/$core_gene.maf 

        sed -i 's/;/_/g' $raw_files/$core_gene.maf 

        ( /home/groups/VEO/tools/variscan/v1.0.1/src/variscan \
        $raw_files/$core_gene.maf \
        $raw_files/$core_gene.conf \
        > $raw_files/$core_gene.variscan.out ) > /dev/null 2>&1

        length=$(grep "#End in reference sequence:" $raw_files/$core_gene.variscan.out | awk '{print $NF}')
        num_of_analysed_sites=$(grep "#Num of analysed sites:" $raw_files/$core_gene.variscan.out | awk '{print $NF}')
        discarded_sites=$(grep "#Num of discarded sites:" $raw_files/$core_gene.variscan.out | awk '{print $NF}')
        num_of_segregating_sites=$(tail -1 $raw_files/$core_gene.variscan.out )

        if [ $length == 0 ] || [ -z $length ] ; then 
            length=na
        fi
        
        if [ $num_of_analysed_sites == 0 ] || [ -z $num_of_analysed_sites ]; then 
            num_of_analysed_sites=na
        fi
        
        if [ $discarded_sites == 0 ] || [ -z $discarded_sites ]; then 
            discarded_sites=na
        fi

        echo $core_gene $length $num_of_analysed_sites $discarded_sites $num_of_segregating_sites >> $wd/genes.stat.tab

        rm $raw_files/$core_gene.conf

    done

    conda deactivate
###############################################################################