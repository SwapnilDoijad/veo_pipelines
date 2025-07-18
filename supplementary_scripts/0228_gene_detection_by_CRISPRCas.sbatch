#!/bin/bash
#SBATCH --job-name=0228_gene_detection_by_CRISPRCas
#SBATCH --partition=short,standard,long,interactive,gpu,gpu-veo
#SBATCH --output=results/0228_gene_detection_by_CRISPRCas/tmp/slurm/%j.out
#SBATCH --error=results/0228_gene_detection_by_CRISPRCas/tmp/slurm/%j.err
#SBATCH --cpus-per-task=10
#SBATCH --mem=10G
###############################################################################
## step-01: preparation
    pipeline=0228_gene_detection_by_CRISPRCas
    source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	fasta_dir=$( grep my_fasta_dir $parameters | awk '{print $2}' )
    sublist=$wd/tmp/lists/ABC
    workdir=$(pwd)
    source /vast/groups/VEO/tools/miniconda3_2024/etc/profile.d/conda.sh 
    conda activate crisprcasfinder_v4.3.2
###############################################################################
## step-02:
    log "STARTED : $pipeline : $sublist"
    
    echo "Ids	Strain	Sequence	Sequence_basename	Duplicated_Spacers	CRISPR_Id	CRISPR_Start	CRISPR_End	CRISPR_Length	Potential_Orientation (AT%)	CRISPRDirection	Consensus_Repeat	Repeat_ID (CRISPRdb)	Nb_CRISPRs_with_same_Repeat (CRISPRdb)	Repeat_Length	Spacers_Nb	Mean_size_Spacers	Standard_Deviation_Spacers	Nb_Repeats_matching_Consensus	Ratio_Repeats_match/TotalRepeat	Conservation_Repeats (% identity)	EBcons_Repeats	Conservation_Spacers (% identity)	EBcons_Spacers	Repeat_Length_plus_mean_size_Spacers	Ratio_Repeat/mean_Spacers_Length	CRISPR_found_in_DB (if sequence IDs are similar)	Evidence_Level" \
    | tr ' ' '_'> results/0228_gene_detection_by_CRISPRCas/Crisprs_REPORT.tsv

	for i in $(cat $sublist); do
    if [ ! -d $raw_files/$i ]; then
        mkdir -p $raw_files/$i
        log "STARTED : $pipeline : $i : CRISPRCasFinder step"

        cd $raw_files/$i
        perl /home/groups/VEO/tools/crisprcasfinder/v4.3.2/CRISPRCasFinder.pl \
        -in $fasta_dir/$i.fasta \
        -out $workdir/results/0228_gene_detection_by_CRISPRCas/raw_files/$i/crisprcas \
        -q \
        -soFile /home/groups/VEO/tools/crisprcasfinder/v4.3.2/sel392v2.so \
        & my_pid=$!
        get_resource_stat $my_pid $wd/tmp/resource_log/$i.CRISPRCasFinder.tsv 

        cd $workdir

        ## create combined Crisprs_REPORT.tsv
        out=$(awk 'NR>1' $raw_files/$i/crisprcas/TSV/Crisprs_REPORT.tsv \
        | sed '/^$/d' | sed 's/ /_/g' | sed "s/^/$i	/g" )
        if [[ -n "$out" ]]; then
            echo -e "$out" \
            | awk -F'\t' '{ for(i=1; i<=NF; i++) {if($i == "") $i = "NA"} OFS="\t"; print}' \
            >> $wd/Crisprs_REPORT.tsv
            else
                na_row=$(printf '\tNA%.0s' {1..27})
                echo -e "$i$na_row" >> $wd/Crisprs_REPORT.tsv
        fi
    done

    log "FINISHED : $pipeline : $sublist"
###############################################################################
# source /home/groups/VEO/tools/biopython/myenv/bin/activate
# python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/cluster_consensus_repeat.py \
# -i $wd/Crisprs_REPORT.tsv \
# -o1 $wd/consensus_repeats.fasta \
# -o2 $wd/clusters.tsv
# deactivate