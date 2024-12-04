#!/bin/bash
#SBATCH --job-name m003_get_taxonomy_step-5
#SBATCH --partition=standard
#SBATCH --output tmp/step_5/slurm/%j.out.m003_get_taxonomy_step-5
#SBATCH --error  tmp/step_5/slurm/%j.err.m003_get_taxonomy_step-5
#SBATCH --ntasks=1
#-- Command section ------------------------


run_id_unique_biom_subset=ABC

    ## below loop is working,but slow, use while loop for relatively better speed
        mkdir tmp/step_5/sublist_files/$run_id_unique_biom_subset
        touch tmp/step_5/sublist_files/$run_id_unique_biom_subset/all.for_OTU_taxa.2.tsv.tmp
        for run_id in $(cat tmp/step_5/list_out/$run_id_unique_biom_subset ); do 
            echo $run_id
            cat tmp/step_4/OTU_files/"$run_id"_taxonomy.2.tsv | sed '1i\'$run_id'' > tmp/step_5/sublist_files/$run_id_unique_biom_subset/"$run_id"_taxonomy.tmp
            paste tmp/step_5/sublist_files/$run_id_unique_biom_subset/all.for_OTU_taxa.2.tsv.tmp tmp/step_5/sublist_files/$run_id_unique_biom_subset/"$run_id"_taxonomy.tmp > tmp/step_5/sublist_files/$run_id_unique_biom_subset/"$run_id"_taxonomy.tmp.2
            mv tmp/step_5/sublist_files/$run_id_unique_biom_subset/"$run_id"_taxonomy.tmp.2 tmp/step_5/sublist_files/$run_id_unique_biom_subset/all.for_OTU_taxa.2.tsv.tmp
            rm tmp/step_5/sublist_files/$run_id_unique_biom_subset/"$run_id"_taxonomy.tmp
        done

        ## delete empty columns 
        awk -F'\t' '{ for (i=1; i<=NF; ++i) if ($i != "") { print; break } }' tmp/step_5/sublist_files/$run_id_unique_biom_subset/all.for_OTU_taxa.2.tsv.tmp > tmp/step_5/sublist_files/$run_id_unique_biom_subset.all.for_OTU_taxa.2.tsv.tmp
        rm -rf tmp/step_5/sublist_files/$run_id_unique_biom_subset
        