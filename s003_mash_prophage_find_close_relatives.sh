
#!/bin/bash
###############################################################################
#3 minhash prophage
###############################################################################
echo "started.... step-03 minhash prophage -------------------------------------------"
###############################################################################
## step-0: file and directory preparations
    if [ -f list.prophage_fasta.txt ]; then 
        list=list.prophage_fasta.txt

        else
        echo "provide prophage genome list file (for e.g. alalll)"
        echo "-------------------------------------------------------------------------"
        ls list.*.txt | sed 's/ /\n/g'
        echo "-------------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
        echo "--------------------------------------------------------------------------------"
    fi

    if [ -f result_summary.read_me.txt ]; then
        fasta_file_path=$(grep fasta result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fasta_file_path"
        read fasta_file_path
    fi

    #------------------------------------------------------------------------------
    ( mkdir -p results/03_minhash_prophage_close_relatives/sketches )> /dev/null 2>&1
    ( mkdir -p results/03_minhash_prophage_close_relatives/distance )> /dev/null 2>&1
    my_dir=results/03_minhash_prophage_close_relatives

    # # read options for the database
    #     while getopts ":d:" option; do
    #         case "$option" in
    #             d)
    #                 database="$OPTARG"
    #                 ;;
    #             \?)
    #                 echo "Invalid option: -$OPTARG" >&2
    #                 exit 1
    #                 ;;
    #             :)
    #                 echo "Option -$OPTARG requires an argument." >&2
    #                 exit 1
    #                 ;;
    #         esac
    #     done

    #     # Check if the database variable is empty
    #     if [ -z "$database" ]; then
    #         echo "Database name not provided: -d database_name" >&2
    #         exit 1
    #     fi

    # choose the database
        # if [ -z "$database" ] ; then
        #     echo "please provide database name"
        #     exit
        #     elif [ "$database" == "millardlab_1Mar2023" ] ; then
            database=/work/groups/VEO/databases/genomes_phage_millardlab/v202303/millardlab_1Mar2023_genomes.fa.msh
            header_file=/work/groups/VEO/databases/genomes_phage_millardlab/v202303/millardlab_1Mar2023_genomes.fa.header
        # fi

###############################################################################
if [ ! -f my_dir/closest_relative_SGC-ANI.tab ] ; then 
## step-1: sketching
    for fasta in $(cat $list); do
        echo "sketching $fasta"
        ( /home/groups/VEO/tools/mash/v2.3/mash sketch -p 50 \
        -o $my_dir/sketches/$fasta.msh \
        $fasta_file_path/$fasta.fasta )> /dev/null 2>&1
    done

## step-2: mashing
    for fasta in $(cat $list); do
        echo "mashing $fasta"
        ( /home/groups/VEO/tools/mash/v2.3/mash dist -p 50 \
        $my_dir/sketches/$fasta.msh \
        $database > $my_dir/distance/$fasta.tab )> /dev/null 2>&1
    done 

## step-3: finding closest relative
    (mkdir $my_dir/closest_relative )> /dev/null 2>&1
    for fasta in $(cat $list); do
        (rm $my_dir/closest_relative/$fasta.closest_relative.tab )> /dev/null 2>&1
        echo "finding closest relative for $fasta"
        sort -k5rn $my_dir/distance/$fasta.tab | head -10 | awk -F'\t' '{print $2}' >> $my_dir/closest_relative/$fasta.closest_relative.tab
    done

## step-4: Calculating shared genome and ANI for closest relatives
    (mkdir $my_dir/closest_relative )> /dev/null 2>&1
    for fasta in $(cat $list); do
        echo "calculating shared genome and ANI for $fasta"
        (rm $my_dir/closest_relative/$fasta.closest_relative_SGC-ANI.tab)> /dev/null 2>&1
        for closest_relative in $(cat $my_dir/closest_relative/$fasta.closest_relative.tab); do
            header=$(grep "$closest_relative" $header_file)
            shared_genome=$( awk '{print $2, $3, $4, $5}' $my_dir/distance/$fasta.tab | grep "$closest_relative" | awk '{print $4}' | awk -F'/' '{print $1*100/1000 }' )
            ANI=$( awk '{print $2, $3, $4, $5}' $my_dir/distance/$fasta.tab | grep "$closest_relative" | awk '{print (1-$2)*100}' )
            echo "$fasta closest relative is $header ($shared_genome shared genome, $ANI ANI)" >> $my_dir/closest_relative/$fasta.closest_relative_SGC-ANI.tab
        done
    done

fi
    touch s03_finished.tmp
###############################################################################
echo "finished.... step-03 minhash prophage ------------------------------------------"
###############################################################################
exit 

###############################################################################
## for comparative genomics, query particular species and extract sequence from database
if [ ! -d results/03_minhash_prophage_close_relatives/close_relatives_fasta ] ; then 
    echo "extracting closest relative fasta"
    ( mkdir -p results/03_minhash_prophage_close_relatives/close_relatives_fasta )> /dev/null 2>&1
    for fasta in $(cat $list); do 
        for closest_relative in $(cat $my_dir/closest_relative.tab); do
            #perl /home/groups/VEO/tools/suppl_scripts/fastagrep.pl -f results/03_minhash_prophage_close_relatives/closest_relative.tab /work/groups/VEO/databases/phage_genomes/millardlab_1Mar2023_genomes.fa > results/03_minhash_prophage_close_relatives/close_relatives_fasta/$fasta.$closest_relative.fasta
            perl /home/groups/VEO/tools/suppl_scripts/fastagrep.pl $closest_relative /work/groups/VEO/databases/phage_genomes/millardlab_1Mar2023_genomes.fa > results/03_minhash_prophage_close_relatives/close_relatives_fasta/$fasta.$closest_relative.fasta
        done
    done
fi
###############################################################################
## query species in database and extract prophage sequences

grep "Pseudomonas" /work/groups/VEO/databases/phage_genomes/millardlab_1Mar2023_genomes.fa.header | grep "complete" | awk '{print $1}' > results/03_minhash_prophage_close_relatives/list.all_prophages_for_species.txt

for F1 in $(cat ); do
    cp home/groups/VEO/databases/phage_genomes/millardlab/millardlab_1Mar2023_genomes_seperated/$F1.fasta /work/groups/VEO/databases/phage_genomes/millardlab_1Mar2023_genomes.fa
done

