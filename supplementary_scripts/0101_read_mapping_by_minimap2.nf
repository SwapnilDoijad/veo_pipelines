#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// =====================
// PARAMETERS
// =====================

params.fastq_dir = params.fastq_dir ?: null
params.reference = params.reference ?: null

params.out_dir = params.out_dir ?: 'results'
params.threads = params.threads ?: 4

params.minimap2_path = params.minimap2_path ?: '/home/groups/VEO/tools/minimap2/v2.26/minimap2'
params.samtools_path = params.samtools_path ?: '/home/groups/VEO/tools/samtools/v1.17/bin/samtools'
params.seqkit_path   = params.seqkit_path   ?: '/home/groups/VEO/tools/seqkit/v2.8.2/seqkit'

// =====================
// WORKFLOW
// =====================
workflow {

    reads_ch = Channel.fromPath("${params.fastq_dir}/*")
        .map { f -> tuple(f.simpleName, f) }

    ref_ch = Channel.value(file(params.reference))

    bam_ch = mapReads(reads_ch, ref_ch)

    split_out = splitReads(bam_ch)

    raw_counts      = countReads_raw(reads_ch)
    mapped_counts   = countReads_mapped(split_out.mapped)
    unmapped_counts = countReads_unmapped(split_out.unmapped)

    mergeCounts(raw_counts, mapped_counts, unmapped_counts)
}

// =====================
// PROCESSES
// =====================

process mapReads {
    label 'high'
    tag { sample_id }
    cpus { params.threads }

    input:
    tuple val(sample_id), path(reads)
    path reference

    output:
    tuple val(sample_id), path("${sample_id}.bam")

    publishDir "${params.out_dir}/raw_files/${sample_id}", mode: 'copy'

    script:
    """
    ${params.minimap2_path} \
        -t ${task.cpus} \
        -ax map-ont ${reference} ${reads} \
    | ${params.samtools_path} view -b \
    > ${sample_id}.bam
    """
}

// ---------------------

process splitReads {
    label 'low'
    tag { sample_id }
    cpus 2

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.mapped.fastq.gz"), emit: mapped
    tuple val(sample_id), path("${sample_id}.unmapped.fastq.gz"), emit: unmapped

    publishDir "${params.out_dir}/raw_files/${sample_id}", mode: 'copy'

    script:
    """
    ${params.samtools_path} view -b -F 4 ${bam} \
        | ${params.samtools_path} fastq - \
        | gzip > ${sample_id}.mapped.fastq.gz

    ${params.samtools_path} view -b -f 4 ${bam} \
        | ${params.samtools_path} fastq - \
        | gzip > ${sample_id}.unmapped.fastq.gz
    """
}

// ---------------------

process countReads_raw {
    tag { sample_id }

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.raw.txt")

    script:
    """
    c=\$(${params.seqkit_path} stats -T ${reads} | awk -F '\\t' 'NR==2 {print \$4}')
    echo -e "${sample_id}\t\$c" > ${sample_id}.raw.txt
    """
}

// ---------------------

process countReads_mapped {
    tag { sample_id }

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.mapped.txt")

    script:
    """
    c=\$(${params.seqkit_path} stats -T ${reads} | awk -F '\\t' 'NR==2 {print \$4}')
    echo -e "${sample_id}\t\$c" > ${sample_id}.mapped.txt
    """
}

// ---------------------

process countReads_unmapped {
    tag { sample_id }

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.unmapped.txt")

    script:
    """
    c=\$(${params.seqkit_path} stats -T ${reads} | awk -F '\\t' 'NR==2 {print \$4}')
    echo -e "${sample_id}\t\$c" > ${sample_id}.unmapped.txt
    """
}

// ---------------------

process mergeCounts {
    tag { sample_id }

    input:
    tuple val(sample_id), path(raw)
    tuple val(sample_id), path(mapped)
    tuple val(sample_id), path(unmapped)

    output:
    path("${sample_id}.final_counts.tsv")

    publishDir "${params.out_dir}/raw_files/${sample_id}", mode: 'copy'

    script:
    """
    r=\$(cut -f2 ${raw})
    m=\$(cut -f2 ${mapped})
    u=\$(cut -f2 ${unmapped})

    mapped_percentage=\$(awk -v m=\$m -v r=\$r 'BEGIN {printf "%.2f", (m/r)*100}')
    unmapped_percentage=\$(awk -v u=\$u -v r=\$r 'BEGIN {printf "%.2f", (u/r)*100}')

    echo -e "sample\traw\tmapped\tunmapped\tmapped_%\tunmapped_%" > ${sample_id}.final_counts.tsv
    echo -e "${sample_id}\t\$r\t\$m\t\$u\t\$mapped_percentage\t\$unmapped_percentage" >> ${sample_id}.final_counts.tsv

    rm ${raw} ${mapped} ${unmapped}
    """
}