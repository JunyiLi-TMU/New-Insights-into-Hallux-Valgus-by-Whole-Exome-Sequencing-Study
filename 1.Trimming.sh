#!/bin/sh
cat id.config | while read id; do trim_galore -q 25 --phred33 --length 36 -e 0.1 --stringency 3 --paired -o ./$id $id.R1.fastq.gz $id.R2.fastq.gz ; done