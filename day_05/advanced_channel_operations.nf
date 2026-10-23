params {
    step: Integer = 0
}


workflow{

    // Task 1 - Read in the samplesheet.

    if (params.step == 1) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .view()
    }

    // Task 2 - Read in the samplesheet and create a meta-map with all metadata and another list with the filenames ([[metadata_1 : metadata_1, ...], [fastq_1, fastq_2]]).
    //          Set the output to a new channel "in_ch" and view the channel. YOU WILL NEED TO COPY AND PASTE THIS CODE INTO SOME OF THE FOLLOWING TASKS (sorry for that).

    if (params.step == 2) {
        in_ch = channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map { row ->
                def meta  = row.findAll { key, value -> !(key in ['fastq_1', 'fastq_2']) }
                def files = [ row.fastq_1, row.fastq_2 ].findAll { path -> path }.collect { path -> file(path) }
                [ meta, files ]
            }
        in_ch.view()
    }

    // Task 3 - Now we assume that we want to handle different "strandedness" values differently. 
    //          Split the channel into the right amount of channels and write them all to stdout so that we can understand which is which.

    if (params.step == 3) {
        in_ch = channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map { row ->
                def meta  = row.findAll { key, value -> !(key in ['fastq_1', 'fastq_2']) }
                def files = [ row.fastq_1, row.fastq_2 ].findAll { path -> path }.collect { path -> file(path) }
                [ meta, files ]
            }

        def strand_ch = in_ch.branch { meta, files ->
            forward:    meta.strandedness == 'forward'
            reverse:    meta.strandedness == 'reverse'
            unstranded: meta.strandedness == 'unstranded'
            other:      true
        }

        strand_ch.forward.view    { item -> "forward: ${item}" }
        strand_ch.reverse.view    { item -> "reverse: ${item}" }
        strand_ch.unstranded.view { item -> "unstranded: ${item}" }
        strand_ch.other.view      { item -> "other: ${item}" }
    }

    // Task 4 - Group together all files with the same sample-id and strandedness value.

    if (params.step == 4) {
        in_ch = channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map { row ->
                def meta  = row.findAll { key, value -> !(key in ['fastq_1', 'fastq_2']) }
                def files = [ row.fastq_1, row.fastq_2 ].findAll { path -> path }.collect { path -> file(path) }
                [ meta, files ]
            }

        in_ch
            .map { meta, files -> [ [ meta.sample, meta.strandedness ], files ] }
            .groupTuple()
            .map { key, file_lists -> [ key, file_lists.flatten() ] }
            .view()
    }
}