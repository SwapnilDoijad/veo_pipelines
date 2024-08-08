#! /bin/bash

#########################################################################################################################
# ./Mgnify_sample_selection.sh -f Digestive


# Define usage function
usage() {
    echo "Usage: $0 [-f Filter] [-v Version] [-o Outdir] [Further filters]"
    echo "Options:"
    echo "  -f Filter     Specify a filter to identify samples (default: Marine)"
    echo "  -v Version          Which version of the sample index file? (default: 7)"
    echo "  -o Output          Specify a directory to save the outputs"
    echo "  Further_filters     Any other argument that you add will be interpreted as a filter!!"
    exit 1
}

find_sample() {
	# Set the name of the variable
	local sm=$1
	# Locate the directory the files are in 
	diraki=`grep  "/.*$sm.*tsv/" All_mgnify_files_sed2.txt  | cut -d ':' -f 1`

	# Locate the correct OTU files
	filaki=`grep "$sm.*otu.tsv" All_mgnify_files.txt`
	# If the dir exists
	if [ ! -z "$diraki" ];then
		l=$(printf '%s' "$diraki" | wc -l)
		if [ "$l" -gt 1 ];then
			diraki=$(echo $diraki | tail -n 1)
		fi
		# And if file exists
		if [ ! -z "$filaki" ];then
			# Write to the output
			echo $diraki/$filaki >>$outdir/${filter}_list.txt
		# Write the file error file
		else
			echo "$filaki" >>$outdir/${filter}_files.err
		fi
	else
		# Write the directory error file
		echo "$diraki" >>$outdir/${filter}_direct.err
	fi
}


map_samples(){
	local filter=$1
	local prev=$2
	if [ ! -z $prev ];then
		name=${prev}_${filter}
	else
		name=$filter
	fi
	local where=$3
	grep -ie "$filter" $where >$outdir/${name}_mapping.tmp
}






# Set default version of sample.index file
version=7
second_filter=''
# Find all options and set initial variables
while getopts ":f:v:o:" opt; do
    case ${opt} in
        f )
            filter=$OPTARG
            ;;
        v )
            version=$OPTARG
	    ;;
	o )
            outdir=$OPTARG
            ;;
        s )
            second_filter=$OPTARG
            ;;

        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Check that the variable is there
if [ -z $filter ];then
	echo $filter
	usage
fi

# Check that the variable is there
if [ ! -d $outdir ];then
mkdir $outdir
fi


if [ ! -d $outdir/$filter ];then
mkdir $outdir/$filter
fi
outdir="$outdir/$filter"

# Specify the original file to grep from
where="/work/groups/VEO/databases/mgnify/mgnify.sample.index.*.v$version.tab"

# Run the map samples function
map_samples $filter "" $where


# Specify the file for the recursive loop
where="$outdir/${name}_mapping.tmp"
# Specify the previous to keep track of all filters
prev=$filter



# Loop for recursive run of the map samples function
for sec in "$@";do
	map_samples $sec $prev $where
	# Re-save variables for recursive runs
	where="$outdir/${name}_mapping.tmp"
	prev=$sec
done


mv $where ${outdir}/${name}_mapping.tsv
rm $outdir/*tmp



# Iterate on the unique studies
for i in `awk -F '\t' '{print $3}' $outdir/${name}_mapping.tsv | sort | uniq`;do
# Find all run_ids corresponding to the study
a=`grep $i /work/groups/VEO/databases/mgnify/mgnify_all_ids_combined.20230127.tab| awk '{print $2}'`
length=`wc -l ${outdir}/${name}_mapping.tsv | cut -d ' ' -f 1`


counts=1
# For every id
for sample in $a;do
	printf "\033[2K\r"
	printf "$counts / $length"
	counts=$((counts+1))
	# Check for '_'
	if [[ $sample == *"_"* ]];then

       		IFS="_" read -ra parts <<< "$sample"

                for part in "${parts[@]}"; do

			if [ "$part" != "null" ];then

				find_sample $part
			fi

                done

        else
                find_sample $sample


        fi
done
done


python Merging_MGnify_OTUs_2table.py -o $outdir/${name}_list.txt -d $outdir -t $name
