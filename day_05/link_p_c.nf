#!/usr/bin/env nextflow

process SPLITLETTERS {
    input:
    tuple val(meta), val(in_str), val(prefix)

    output:
    tuple val(meta), path("${prefix}_*")

    script:
    """
    printf '%s' "${in_str}" | split -b ${meta.block_size} - ${prefix}_
    """
}

process CONVERTTOUPPER {
    debug true
    publishDir 'results', mode: 'copy'

    input:
    path chunk

    output:
    path "upper_${chunk}"

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${chunk} | tee upper_${chunk}
    """
}

workflow {
    // 1. read in the samplesheet; block_size becomes the meta-map
    in_ch = channel.fromPath('samplesheet_2.csv')
        .splitCsv(header: true)
        .map { row -> [ [ block_size: row.block_size as Integer ], row.input_str, row.out_name ] }

    // 2. split the input string into chunks of block_size
    split_ch = SPLITLETTERS(in_ch)

    // remove the meta-map, one item per chunk file
    chunks_ch = split_ch
        .map { meta, files -> files }
        .flatten()

    // 4. convert the chunks to uppercase, print them and save them to results/
    CONVERTTOUPPER(chunks_ch)
}