#!/bin/sh

#module load java/jdk1.8.0_121

family=$1
echo $family
echo NOWACTION Hello! $(date)
cd /workDirectory/halluxValgus/$family
pwd

GATK=/workDirectory/software/gatk-4.1.6.0/gatk
bwa=/workDirectory/software/bwa-0.7.17/bwa

GENOME=/workDirectory/index/FASTA/GRCh37.75/GRCh37.fa
INDEX=/workDirectory/index/fasta_hg19_bwa/GRCh37.fa
bed=/workDirectory/software/exome_m_interval.bed
DBSNP=/workDirectory/index/SNP/dbsnp_138.b37_sorted.vcf
kgSNP=/workDirectory/index/SNP/1000G_phase1.snps.high_confidence.b37_sorted.vcf
kgINDEL=/workDirectory/index/SNP/Mills_and_1000G_gold_standard.indels.b37_sorted.vcf

echo NOWACTION GenomicsDBImport-Start $(date)
for bed in  {1..22} X Y
do
echo $bed
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   GenomicsDBImport  \
-L $bed -R $GENOME \
$(ls *raw.vcf|awk '{print "-V "$0" "}') \
--genomicsdb-workspace-path gvcfs_${bed}.db
done

echo NOWACTION GenotypeGVCFs-Start $(date)
for bed in  {1..22} X Y
do
echo $bed 
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   GenotypeGVCFs  \
-R $GENOME  -V gendb://gvcfs_${bed}.db -O final_${bed}.vcf
done

echo NOWACTION GatherVcfs-Start $(date)
$GATK GatherVcfs  \
$(for i in {1..22} X Y  ;do echo "-I final_$i.vcf"  ;done) \
-O $family.raw.vcf 

#echo NOWACTION Relatedness2-Start $(date)
#vcftools --vcf $family.raw.vcf --relatedness2

echo NOWACTION SelectVariants-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   SelectVariants -R $GENOME -V ${family}.raw.vcf --select-type-to-include SNP -O ${family}_raw_snps.vcf
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   SelectVariants -R $GENOME -V ${family}.raw.vcf --select-type-to-include INDEL -O ${family}_raw_indels.vcf

echo NOWACTION VariantFiltration-Start $(date)
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   VariantFiltration -R $GENOME -V ${family}_raw_snps.vcf -filter "QD < 2.0" --filter-name "QD2" -filter "QUAL < 30.0" --filter-name "QUAL30" -filter "SOR > 3.0" --filter-name "SOR3" -filter "FS > 60.0" --filter-name "FS60" -filter "MQ < 40.0" --filter-name "MQ40" -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" -O ${family}_final_snps.vcf
$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   VariantFiltration -R $GENOME -V ${family}_raw_indels.vcf -filter "QD < 2.0" --filter-name "QD2" -filter "QUAL < 30.0" --filter-name "QUAL30" -filter "FS > 200.0" --filter-name "FS200" -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" -filter "SOR > 10.0" --filter-name "SOR10" -filter "InbreedingCoeff < -0.8"  --filter-name "InbreedingCoeff-0.8" -O ${family}_final_indels.vcf
echo NOWACTION Bye! $(date)
