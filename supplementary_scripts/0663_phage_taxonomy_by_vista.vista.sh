
export PATH=/root/VISTA/Scripts/:/root/miniconda3/bin:/root/miniconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This shell script aims to provide taxonomic assignments for input virus sequences within a specified virus family."
   echo
   echo "Syntax: VISTA [-i|f|o|t|h]"
   echo "options:"
   echo "i     Input nucleotide sequences in FASTA format. (e.g. demo.fasta)"
   echo "f     Specify a virus family. default: Dicistroviridae"
   echo "o     Output directory. default: Output"
   echo "t     Number of threads to use. default: 1"
   echo "h     Print this Help."
   echo
}


############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set default variables
Input=""
Family="Dicistroviridae"
Output="Output"
Threads=1


# Get the options
while getopts ":h:i:f:t:o:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Enter a input
         Input=$OPTARG;;
      f) # Specify a virus family
         Family=$OPTARG;;
      o) # Output directory
         Output=$OPTARG;;
      t) # Number of threads 
         Threads=$OPTARG;;

     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

if [[ -d "$Output" ]];then
        rm -rf $Output
fi

if [[ $Input == ""  ]];then
        Help
else

        script_dir=$(cd $(dirname $0); pwd)
        parent_dir=${script_dir%/*}

        #mkdir -p $Output/Data/NA
        mkdir -p $Output/Data/AA/Concaten
        mkdir -p $Output/Data/PC/Kmer_Combined/

        #fasta_name=$Input
    awk '/^>/ {if (NR>1) printf("\n"); printf("%s\t",$0); next;} {printf("%s", $0);} END {printf("\n");}' "$Input" | awk -F '\t' '{gsub("\n", "", $2); print $1 "\n" $2}' > "${Input}.singlerow.fa"
    fasta_name=${Input}.singlerow.fa
        
        id=1
        if [[ $Family == "Circoviridae" || $Family == "Hepadnaviridae" || $Family == "Microviridae" || $Family == "Polyomaviridae" || $Family == "Papillomaviridae"  || $Family == "Geminiviridae" ]];then
    while read line
    do
        if [[ ${line:0:1} == '>' ]]
        then
            Query_ID="Query_$id"
            Query_ID_header=">Query_$id"
            outfile=${Query_ID}.fasta
            echo $Query_ID_header > "$Output/Data/$outfile"

            header=${line#*>}
            echo -e "$Query_ID\t$header" >> $Output/Data/Query_Header_meta.txt
            let id++
        else
            duplicated_sequence=${line}${line}
            echo $duplicated_sequence >> "$Output/Data/$outfile"
        fi
    done < $fasta_name

    rm $fasta_name
    cd $Output/Data/
    for i in `ls *.fasta`
        do
                array=(${i//./ })
                epi=${array[0]}
                /root/miniconda3/bin/sixpack -sequence $i -mstart Yes -firstorf No -lastorf No -orfminsize 100 -outseq  AA/$epi.sixpack.fa -outfile AA/$epi.sixpack.outfile
                python $script_dir/filter_redunant_AA_circo_new.py AA/$epi.sixpack.fa AA/$epi.sixpack.filtered.fa
                rm AA/$epi.sixpack.fa
                mv AA/$epi.sixpack.filtered.fa AA/$epi.sixpack.fa
        done
        else
        while read line
        do
            if [[ ${line:0:1} == '>' ]]
            then
                Query_ID="Query_$id"
                Query_ID_header=">Query_$id"
                outfile=${Query_ID}.fasta
                echo $Query_ID_header > "$Output/Data/$outfile"

                header=${line#*>}
                echo -e "$Query_ID\t$header" >> $Output/Data/Query_Header_meta.txt
                let id++
            else
                echo $line >> "$Output/Data/$outfile"
            fi
        done < $fasta_name

        rm $fasta_name
        cd $Output/Data/
        for i in `ls *.fasta`
                do
                        array=(${i/./ })
                        epi=${array[0]}
                        /root/miniconda3/bin/sixpack -sequence $i -mstart Yes -firstorf No -lastorf No -orfminsize 100 -outseq  AA/$epi.sixpack.fa -outfile AA/$epi.sixpack.outfile
                done
        fi

        cd PC
        find ../AA -type f -size 0 > empty.txt
    if [ -s empty.txt ]
        then
                echo "========================================================================"
                echo "Warning: The following sequences have not been translated due to being too short:"
                while read i
                do
                        short_query=`echo $i | grep -o "Query_[0-9]*"`
                        grep -w "$short_query" ../Query_Header_meta.txt
                done < empty.txt
                echo "========================================================================"
        fi 
        find ../AA -type f -size 0 -delete
        if find ../AA -type f -name "*.fa" | grep -q '\.fa$'; then
                echo "..."
        else
                exit
        fi

        for i in `ls ../AA/*.fa`
                do
                        python  $script_dir/trans_AA_physiochem.py  $i
                done
        mv ../AA/*_PC* .


        cd ../AA
        for i in `ls *sixpack.fa`
                do
                        array=(${i/./ })
                        epi=${array[0]}
                        sed '/>/d' $epi.sixpack.fa | sed ':t;N;s/\n//;b t'|sed "1i>$epi" > Concaten/$epi.concaten.fasta
                done
        cd Concaten
        find ./ -name "*.fasta" |xargs sed 'a\' > ../AminoAcid.fasta

        cd ../../PC
        python $script_dir/trans_AA_physiochem.py ../AA/AminoAcid.fasta
        mv  ../AA/AminoAcid.fasta_PC.fasta .

        cd Kmer_Combined
        kmer=`grep -w -i "$Family" $parent_dir/Data/method.txt | cut -f2`
        python $script_dir/Create_Kmer_Count.py -d ../ -k $kmer -t $Threads
        
        if [[ $Family != "Caudoviricetes" ]];then
                python $script_dir/Create_Kmer_Pos.py ../AminoAcid.fasta_PC.fasta $kmer

                paste -d"," All_mer_Count_matrix.csv All_mer_Pos_matrix.csv > All_mer_Count_Pos_matrix.csv
                python $script_dir/Extract_select_features_from_data.py $Family

                method=`grep -w -i "$Family" $parent_dir/Data/method.txt | cut -f3`
                #python $script_dir/Make_Pairwise_Distance_Matrix_pairwise.py $Family $method
                python $script_dir/Make_Pairwise_Distance_Matrix_pairwise.py $Family $method
        else
                mv All_mer_Count_matrix.csv All_mer_Count_Pos_matrix.csv
                python $script_dir/Extract_select_features_from_data.py $Family
                method=`grep -w -i "$Family" $parent_dir/Data/method.txt | cut -f3`
                python $script_dir/Make_Pairwise_Distance_Matrix_pairwise_Caudoviricetes.py $Family $method

        fi

        head -1 distance_file.txt > t1
        sed '1d' distance_file.txt -i
        sort -t"_" -k2,2 -n distance_file.txt -o distance_file.txt
        cat t1 distance_file.txt > t2
        rm distance_file.txt
        rm t1
        mv t2 distance_file.txt

        mkdir Results
        touch Results/distance_file_all.txt
        touch Results/distance_file_min.txt
        cp ../../Query_Header_meta.txt .
        
        if [[ $Family != "Caudoviricetes" ]];then
                python $script_dir/make_nearest_tables.py $Family
        else
                python $script_dir/make_nearest_tables_Caudoviricetes.py $Family
        fi
        mv Results ../../../
        echo "Finished!"
fi

