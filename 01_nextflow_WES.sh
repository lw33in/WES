# Nextflow command to pre-process scRNA-seq raw data

# scRNA-seq raw data: fastq.gz files
# Pipeline: nf-core/sarek (https://nf-co.re/sarek), Version: 3.1.2
# Input csv file format: patient [patient_name], sample[sample_name], lane [labe_name], fastq_1[fastq.gz], fastq_2[fastq.gz],variantcaller [deepvariant]
# Reference genome: GRCh38 Gencode v32, download command (provided by Cellranger): wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz

# Germline
nextflow run nf-core/sarek --input sample_wes_germline_config.csv --outdir output_germline \
  --wes --tools deepvariant --genome GATK.GRCh38 -profile docker -r 3.1.2 \
  --trim_fastq --detect_adapter_for_pe

# Somatic 
nextflow run nf-core/sarek --input sample_wes_somatic_config.csv --outdir output_somatic \
  --wes --tools strelka --genome GATK.GRCh38 -profile docker -r 3.1.2 \
  --trim_fastq --detect_adapter_for_pe

