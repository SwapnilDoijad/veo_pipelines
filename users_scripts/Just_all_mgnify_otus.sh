# Identify all the OTU files within the group directory
find /work/groups/VEO/databases/mgnify/studies/ -name "*otu.tsv" > Path_of_all_OTU_Files.txt
# Initialize the file of all OTUS
>All_MGnify_OTUs.txt
# Exclude MGnify pipeline version 1.0
for i in `grep -v "1.0" Path_of_all_OTU_Files.txt`;do
# Select all the taxonomy columns for all MGnify samples!
awk -F '\t' '{print $3}' $i >>All_MGnify_OTUs.txt
done

