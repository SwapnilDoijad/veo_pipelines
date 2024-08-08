#!/bin/bash
###############################################################################
echo "script 0024_QC_combine_fastq_QC_by_mulitQC started -----------------------------"
###############################################################################
## step-01: preparations

    if [ -f result_summary.read_me.txt ]; then
        fastq_file_path=$(grep fastq result_summary.read_me.txt | awk '{print $NF}')
        else
        echo "provide fastq_file_path"
        read fastq_file_path
    fi

    (mkdir -p results/0024_QC_combine_fastq_QC_by_mulitQC ) > /dev/null 2>&1
    work_dir=results/0024_QC_combine_fastq_QC_by_mulitQC
    echo $work_dir

    QC_dir=$( find results/ -type d -name "*QC*" | grep -v 0024 | grep -v nanoplot | sed 's/ /\n/g' | sed 's/results\///g')
    echo $QC_dir
###############################################################################
## step-02: run mulitQC


    ## activate multiQC virtual env 
    source /home/groups/VEO/tools/multiQC/v1.15/bin/activate 

    ## run multiQC
    for i in $QC_dir ; do
        if [ ! -d $work_dir/$i ] ; then
            echo "runnig mulitQC for $i"
            multiqc results/$i -o $work_dir/$i/
        fi
    done 

    deactivate

###############################################################################
## step-03: compress results in .zip format

    for i in $QC_dir ; do
        if [ ! -f results/0024_QC_combine_fastq_QC_by_mulitQC/$i.zip ] ; then 
            echo "runnig mulitQC for $i"
            my_dir=$(pwd)
            cd results/0024_QC_combine_fastq_QC_by_mulitQC
            ( zip -r $i.zip $i ) > /dev/null 2>&1
            cd $my_dir
        fi
    done 

###############################################################################
## step-04: send report by email (with attachment)

    echo "sending email"
    user=$(whoami)
    # user_name=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $2}')
    user_email=$(grep $user /home/groups/VEO/scripts_for_users/supplementary_scripts/user_email.csv | awk -F'\t'  '{print $3}')

    source /home/groups/VEO/tools/email/myenv/bin/activate

    python3.6 \
    /home/groups/VEO/scripts_for_users/supplementary_scripts/emails/0024_QC_combine_fastq_QC_by_mulitQC.py -e $user_email

    deactivate

###############################################################################
echo "script 0024_QC_combine_fastq_QC_by_mulitQC finished ----------------------------"
###############################################################################


###############################################################################
# ## step-03: generate pdf
    #     echo "generating pdf" 

    #     source /home/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh
    #     conda activate pdfkit_v1.0.0
        
    #     for i in $QC_dir ; do
    #     python /home/groups/VEO/scripts_for_users/supplementary_scripts/utilities/html2pdf_by_pdfkit.py \
    #     -i $work_dir/$i/multiqc_report.html \
    #     -o $work_dir/$i/multiqc_report.pdf
    #     done 

    #     echo "pdf generation finished" 
###############################################################################