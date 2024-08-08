#!/bin/bash
#SBATCH --job-name m003_get_taxonomy_step-5
#SBATCH --partition=standard
#SBATCH --output tmp/step_5/slurm_out/%j.out.m003_get_taxonomy_step-5
#SBATCH --error  tmp/step_5/slurm_out/%j.err.m003_get_taxonomy_step-5
#SBATCH --ntasks=1
#-- Command section ------------------------

#!/bin/bash
## step-5: Combining OTUs of each run
run_id_unique_biom_subset=ABC


        if [ ! -d tmp/step_5/combined/$run_id_unique_biom_subset ]; then 
            echo "started $run_id_unique_biom_subset"
            mkdir tmp/step_5/combined/$run_id_unique_biom_subset

            for run_id in $(cat tmp/step_5/list_out/$run_id_unique_biom_subset ); do 
                if [ ! -f tmp/step_5/combined/$run_id_unique_biom_subset/"$run_id"_taxonomy.seperated.tsv ]; then 
                    echo running run_id $run_id
                    for OTUs_sorted_sublist in $(cat tmp/step_4/list.OTUs_sorted_sublist.txt); do
                        cat tmp/step_4/OTU_files/seperated/$OTUs_sorted_sublist/"$run_id"_taxonomy.seperated.tsv >> tmp/step_5/combined/$run_id_unique_biom_subset/"$run_id"_taxonomy.seperated.tsv
                            tmp/step_4/OTU_files/"$run_id"_taxonomy.2.tsv
                    done
                fi
            done
            echo "finished $run_id_unique_biom_subset"
        fi






