################## HOW TO #####################
#### bash Filter_mgnify_studies.sh N ##########
### N: minimum number of samples is a study ###

## Adding a loop in order to provide the files that we need in from the terminal
while true; do
case $1 in
	-n|--minimum_samples)
		### Make sure that the path doesn't end with /, so that the paths remain correct
		N=$2
		shift 2;;
	-f|--filter)
		filt=$2
		shift 2;;
	*)
		break;;
esac
done

# Check if the flags were correct
if [ -z $filt ] && [ -z $N ];then
	echo "Please provide the minimum number of samples per study and the filter"
	echo "For example:"
	echo "bash Filter_mgnify_studies.sh -n 50 -f fecal"
	exit 1
fi
# Check if filter is applied
if [ -z $filt ];then
	echo "No filter applied, aborting"
	echo "---------------------------"
	exit 1
fi
## Default the minimum number of samples as 1
if [ -z $N ];then
	echo "No number of samples applied"
	echo "Assuming 1"
	N=1

fi
# Initialize the Mapping file
>Mapping_file_${filt}.tsv
# Initialize a file of location of OTU files
>List_of_OTU_files_${filt}.txt
# Find the names of the studies that correspond to the filters
study_ids=`grep -i $filt /work/groups/VEO/databases/mgnify/mgnify.study.index.20230103_223937.tab | awk '{print $3}'`

for i in $study_ids;do
## Check whether they've been downloaded
if [ -d /work/groups/VEO/databases/mgnify/studies/$i ];then
# Find the mgnify accession of the study
study=`grep $i /work/groups/VEO/databases/mgnify/mgnify.study.index.20230103_223937.tab | awk '{print $1}'`
# Check whether it is 16S or shotgun
#is16=`grep $study /work/groups/VEO/databases/mgnify/mgnify.analyses.index.20230118_174036.tab | awk '{print $3}'| head -1`
# When it is 16S, go to the next
#if [[ $is16 = 'amplicon' ]];
#then
#true
#continue
#else
#grep $study /work/groups/VEO/databases/mgnify/mgnify.sample.index.20230117_165017.*
# Find the MGnify accession on the mapping file and append it to our output
grep $study /work/groups/VEO/databases/mgnify/mgnify.sample.index.20230117_165017.v3.tab >>Mapping_file_${filt}.tsv
# Find and store the location of the files
find /work/groups/VEO/databases/mgnify/studies/$i -type f -name "*otu.tsv" >>List_of_OTU_files_${filt}.txt
#fi
fi
done

