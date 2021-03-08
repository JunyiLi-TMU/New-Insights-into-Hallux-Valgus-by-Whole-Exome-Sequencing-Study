#!/bin/sh

#module load java/jdk1.8.0_121

sample=$1
echo $sample
echo NOWACTION Hello! $(date)
cd /workDirectory/halluxValgus/$sample
pwd
fq1=$sample.R1_val_1.fq.gz
fq2=$sample.R2_val_2.fq.gz

GATK=/workDirectory/software/gatk-4.1.6.0/gatk
bwa=/workDirectory/software/bwa-0.7.17/bwa

GENOME=/workDirectory/index/FASTA/GRCh37.75/GRCh37.fa
INDEX=/workDirectory/index/fasta_hg19_bwa/GRCh37.fa
bed=/workDirectory/software/exome_m_interval.bed
DBSNP=/workDirectory/index/SNP/dbsnp_138.b37_sorted.vcf
kgSNP=/workDirectory/index/SNP/1000G_phase1.snps.high_confidence.b37_sorted.vcf
kgINDEL=/workDirectory/index/SNP/Mills_and_1000G_gold_standard.indels.b37_sorted.vcf

echo NOWACTION FastQC-Start $(date)
fastqc -t 12 $fq1 $fq2
echo NOWACTION BWA-Start $(date)
$bwa mem -t 12 -M  -R "@RG\tID:$sample\tSM:$sample\tLB:WES\tPL:Illumina" $INDEX $fq1 $fq2 >$sample.sam
echo NOWACTION SamToBam-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"  SortSam -SO coordinate  -I $sample.sam -O $sample.bam
echo NOWACTION IndexRawBam-Start $(date)
samtools index $sample.bam
echo NOWACTION RawBamQC-Start $(date)
samtools flagstat $sample.bam > ${sample}.alignment.flagstat
samtools stats  $sample.bam > ${sample}.alignment.stat
echo plot-bamstats -p ${sample}_QC  ${sample}.alignment.stat
echo NOWACTION MarkDuplicates-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   MarkDuplicates  -I $sample.bam -O ${sample}_marked.bam -M $sample.metrics
echo NOWACTION FixMateInformation-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   FixMateInformation -I ${sample}_marked.bam -O ${sample}_marked_fixed.bam -SO coordinate
echo NOWACTION IndexBam-Start $(date)
samtools index ${sample}_marked_fixed.bam
echo NOWACTION BQSR-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   BaseRecalibrator -I ${sample}_marked_fixed.bam -R $GENOME --output ${sample}_recal.table --known-sites $DBSNP --known-sites $kgSNP --known-sites $kgINDEL
echo NOWACTION ApplyBQSR-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   ApplyBQSR -I ${sample}_marked_fixed.bam -R $GENOME --output ${sample}_recal.bam -bqsr ${sample}_recal.table 
echo NOWACTION ValidateBam-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./" ValidateSamFile -I ${sample}_recal.bam
echo NOWACTION Gvcf-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   HaplotypeCaller  -ERC GVCF  -L $bed -R $GENOME -I ${sample}_recal.bam  --dbsnp $DBSNP -O  ${sample}_raw.vcf
echo NOWACTION Bye! $(date)