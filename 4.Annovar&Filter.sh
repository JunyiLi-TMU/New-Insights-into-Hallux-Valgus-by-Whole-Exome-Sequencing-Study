#!/bin/sh

#module load java/jdk1.8.0_121

family=$1
echo $family
echo NOWACTION Hello! $(date)
cd /workDirectory/halluxValgus/$family
pwd
GATK=/workDirectory/software/gatk-4.1.6.0/gatk
GENOME=/workDirectory/index/FASTA/GRCh37.75/GRCh37.fa

echo NOWACTION SelectVariants-Start $(date)


#AD>4
#$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   SelectVariants \
        -R $GENOME \
        -V ${family}_final_snps.vcf \
        -select 'vc.getGenotype("sample_S001").getAD().1 > 4' \
        -select 'vc.getGenotype("sample_S002").getAD().1 > 4' \
        -select 'vc.getGenotype("sample_S003").getAD().1 > 4' \
        -O AD.${family}_final_snps.vcf
#$GATK  --java-options "-Xmx20G -Djava.io.tmpdir=./"   SelectVariants \
        -R $GENOME \
        -V ${family}_final_indels.vcf \
        -select 'vc.getGenotype("sample_S001").getAD().1 > 4' \
        -select 'vc.getGenotype("sample_S002").getAD().1 > 4' \
        -select 'vc.getGenotype("sample_S003").getAD().1 > 4' \
        -o AD.${family}_final_indels.vcf

#Variant annotation
table_annovar.pl AD.${family}_final_snps.vcf /workDirectory/software/annovar/humandb/ -buildver hg19 -out ./snp -remove -protocol refGene,cytoBand,snp142,esp6500siv2_all,exac03,gnomad_exome,gnomad_genome,1000g2015aug_all,1000g2015aug_afr,1000g2015aug_amr,1000g2015aug_eas,1000g2015aug_eur,1000g2015aug_sas,cosmic70,clinvar_20190305,dbnsfp35a, -operation g,r,f,f,f,f,f,f,f,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -thread 12
table_annovar.pl AD.${family}_final_indels.vcf /workDirectory/software/annovar/humandb/ -buildver hg19 -out ./indel -remove -protocol refGene,cytoBand,snp142,esp6500siv2_all,exac03,gnomad_exome,gnomad_genome,1000g2015aug_all,1000g2015aug_afr,1000g2015aug_amr,1000g2015aug_eas,1000g2015aug_eur,1000g2015aug_sas,cosmic70,clinvar_20190305,dbnsfp35a, -operation g,r,f,f,f,f,f,f,f,f,f,f,f,f,f,f -nastring . -vcfinput -otherinfo -thread 12

#Remove the VCF header
egrep "#" AD.snp.hg19_multianno.vcf > header.AD.snp.hg19_multianno.vcf
egrep "#" AD.indel.hg19_multianno.vcf > header.AD.indel.hg19_multianno.vcf
egrep -v "#" AD.snp.hg19_multianno.vcf > noheader.AD.snp.hg19_multianno.vcf
egrep -v "#" AD.indel.hg19_multianno.vcf > noheader.AD.indel.hg19_multianno.vcf

#Autosomal dominant inheritance or autosomal recessive inheritance
perl -w /workDirectory/halluxValgus/pl/dominant_$id.pl noheader.AD.snp.hg19_multianno.vcf > dominant.AD.snp.vcf
perl -w /workDirectory/halluxValgus/pl/dominant_$id.pl noheader.AD.indel.hg19_multianno.vcf > dominant.AD.indel.vcf
perl -w /workDirectory/halluxValgus/pl/recessive_$id.pl noheader.AD.snp.hg19_multianno.vcf > recessive.AD.snp.vcf
perl -w /workDirectory/halluxValgus/pl/recessive_$id.pl noheader.AD.indel.hg19_multianno.vcf > recessive.AD.indel.vcf

#Split functional exonic SNVs, functional exonic indels and variants at splicing sites
grep -E "#|ExonicFunc.refGene=nonsynonymous_SNV|ExonicFunc.refGene=stopgain|ExonicFunc.refGene=stoploss" dominant.AD.snp.vcf > exon.dominant.AD.snp.vcf
grep -E "#|ExonicFunc.refGene=nonsynonymous_SNV|ExonicFunc.refGene=stopgain|ExonicFunc.refGene=stoploss" recessive.AD.snp.vcf > exon.recessive.AD.snp.vcf

grep -E "#|ExonicFunc.refGene=frameshift_deletion|ExonicFunc.refGene=frameshift_insertion" dominant.AD.indel.vcf > exon.dominant.AD.indel.vcf
grep -E "#|ExonicFunc.refGene=frameshift_deletion|ExonicFunc.refGene=frameshift_insertion" recessive.AD.indel.vcf > exon.recessive.AD.indel.vcf

grep -E "#|Func.refGene=splicing" dominant.AD.snp.vcf > splice.dominant.AD.vcf
grep -E "#|Func.refGene=splicing" dominant.AD.indel.vcf >> splice.dominant.AD.vcf
grep -E "#|Func.refGene=splicing" recessive.AD.snp.vcf > splice.recessive.AD.vcf
grep -E "#|Func.refGene=splicing" recessive.AD.indel.vcf >> splice.recessive.AD.vcf

#Mutations predicted to be deleterious: SNP: SIFT, Polyphen2_HDIV, PROVEAN; indel: PROVEAN
egrep "SIFT_pred=D" exon.dominant.AD.snp.vcf | egrep "Polyphen2_HDIV_pred=D" | egrep "PROVEAN_pred=D" > pred_exon.dominant.AD.snp.vcf
egrep "SIFT_pred=D" exon.recessive.AD.snp.vcf | egrep "Polyphen2_HDIV_pred=D" | egrep "PROVEAN_pred=D" > pred_exon.recessive.AD.snp.vcf

egrep "PROVEAN_pred=D" gnomAD_ExAC_1000G_exon.dominant.AD.indel.vcf > pred_exon.dominant.AD.indel.vcf
egrep "PROVEAN_pred=D" gnomAD_ExAC_1000G_exon.recessive.AD.indel.vcf > pred_exon.recessive.AD.indel.vcf

#mAF: 1000G, ExAC, gnomAD
perl -w "/workDirectory/halluxValgus/pl/1000G.pl" pred_exon.dominant.AD.snp.vcf > 1000G_pred_exon.dominant.AD.snp.vcf
perl -w "/workDirectory/halluxValgus/pl/ExAC.pl" 1000G_pred_exon.dominant.AD.snp.vcf > ExAC_1000G_pred_exon.dominant.AD.snp.vcf
perl -w "/workDirectory/halluxValgus/pl/gnomAD.pl" ExAC_1000G_pred_exon.dominant.AD.snp.vcf > $id.gnomAD_ExAC_1000G_pred_exon.dominant.AD.snp.vcf

perl -w "/workDirectory/halluxValgus/pl/1000G.pl" pred_exon.recessive.AD.snp.vcf > 1000G_pred_exon.recessive.AD.snp.vcf
perl -w "/workDirectory/halluxValgus/pl/ExAC.pl" 1000G_pred_exon.recessive.AD.snp.vcf > ExAC_1000G_pred_exon.recessive.AD.snp.vcf
perl -w "/workDirectory/halluxValgus/pl/gnomAD.pl" ExAC_1000G_pred_exon.recessive.AD.snp.vcf > $id.gnomAD_ExAC_1000G_pred_exon.recessive.AD.snp.vcf

perl -w "/workDirectory/halluxValgus/pl/1000G.pl" pred_exon.dominant.AD.indel.vcf > 1000G_pred_exon.dominant.AD.indel.vcf
perl -w "/workDirectory/halluxValgus/pl/ExAC.pl" 1000G_pred_exon.dominant.AD.indel.vcf > ExAC_1000G_pred_exon.dominant.AD.indel.vcf
perl -w "/workDirectory/halluxValgus/pl/gnomAD.pl" ExAC_1000G_pred_exon.dominant.AD.indel.vcf > $id.gnomAD_ExAC_1000G_pred_exon.dominant.AD.indel.vcf

perl -w "/workDirectory/halluxValgus/pl/1000G.pl" pred_exon.recessive.AD.indel.vcf > 1000G_pred_exon.recessive.AD.indel.vcf
perl -w "/workDirectory/halluxValgus/pl/ExAC.pl" 1000G_pred_exon.recessive.AD.indel.vcf > ExAC_1000G_pred_exon.recessive.AD.indel.vcf
perl -w "/workDirectory/halluxValgus/pl/gnomAD.pl" ExAC_1000G_pred_exon.recessive.AD.indel.vcf > $id.gnomAD_ExAC_1000G_pred_exon.recessive.AD.indel.vcf

perl -w "/workDirectory/halluxValgus/pl/1000G.pl" splice.dominant.AD.vcf > 1000G_splice.dominant.AD.vcf
perl -w "/workDirectory/halluxValgus/pl/ExAC.pl" 1000G_splice.dominant.AD.vcf > ExAC_1000G_splice.dominant.AD.vcf
perl -w "/workDirectory/halluxValgus/pl/gnomAD.pl" ExAC_1000G_splice.dominant.AD.vcf > $id.gnomAD_ExAC_1000G_splice.dominant.AD.vcf

perl -w "/workDirectory/halluxValgus/pl/1000G.pl" splice.recessive.AD.vcf > 1000G_splice.recessive.AD.vcf
perl -w "/workDirectory/halluxValgus/pl/ExAC.pl" 1000G_splice.recessive.AD.vcf > ExAC_1000G_splice.recessive.AD.vcf
perl -w "/workDirectory/halluxValgus/pl/gnomAD.pl" ExAC_1000G_splice.recessive.AD.vcf > $id.gnomAD_ExAC_1000G_splice.recessive.AD.vcf

