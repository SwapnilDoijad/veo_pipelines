source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
conda activate krona_v2.7.1
for i in $(cat list.fastq.txt);do 
rm results/0062_identification_kraken2_r/raw_files/$i/report.txt.html
    ktImportTaxonomy -t 3 \
    -o results/0062_identification_kraken2_r/raw_files/$i/report.txt.html \
    results/0062_identification_kraken2_r/raw_files/$i/report.txt
done