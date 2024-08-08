## https://phaster.ca/instructions
###############################################################################
# b062 phage detection by phaster
###############################################################################
    if [ -f list.my_fasta.txt ]; then 
        list=list.my_fasta.txt
        else
        echo "provide list file (for e.g. all)"
        echo "---------------------------------------------------------------------"
        ls list.*.txt | awk -F'.' '{print $2}'
        echo "---------------------------------------------------------------------"
        read l
        list=$(echo "list.$l.txt")
    fi
    
    (mkdir results) > /dev/null 2>&1
    (mkdir results/b062_phaster) > /dev/null 2>&1
    (mkdir results/b062_phaster/raw_files) > /dev/null 2>&1
###############################################################################
for file in $(cat $list); do
    if [ ! -d results/b062_phaster/raw_files/$file ] ; then 
    echo "uploading $file.fasta"
    (mkdir results/b062_phaster/raw_files/$file) > /dev/null 2>&1
    wget -q --post-file="results/0040_assembly/all_fasta/$file.fasta" "http://phaster.ca/phaster_api?contigs=1" -O results/b062_phaster/raw_files/$file/$file.txt
    fi
done
###############################################################################
for file in $(cat $list); do
    if [ -d results/b062_phaster/raw_files/$file ] ; then 
    echo "getting status for $file"
    link=$(cat results/b062_phaster/raw_files/$file/$file.txt | awk -F'"' '{print $4}')
    wget -q "http://phaster.ca/phaster_api?acc=$link" -O results/b062_phaster/raw_files/$file/$file.txt
    fi
done
##############################################################################