#!/usr/bin/env bash
# annotateVCF.sh

# Annotates input VCF with snpEff-identified variant effects and ClinVar & dbSNP IDs.
# It is possible to filter the fully-annotated VCF (i.e., skip the annotation step and filter only) by setting the `FILTER_ONLY` parameter to `true`.
# Automatically downloads/installs SnpEff/SnpSift and dbSNP & ClinVar annotation files.
# Note: Modify the "filter_vcf_custom" function to set a custom filter.

# Log files
script_name=$(basename $0 .sh)
log_path="log_files/" # Contains set of log and error files generated
log_file="${log_path}${script_name}.log"
err_file="${log_path}${script_name}.err"

# Directory names & database annotation file names
annotation_files_dir="annotation_files/"
snpEff_dir="snpEff/"
dbsnp_annotation_file_path="${annotation_files_dir}dbsnp_annotation.vcf.gz"
clinvar_annotation_file_path="${annotation_files_dir}clinvar_annotation.vcf.gz"

# Output file suffixes
eff_vcf_suffix="_eff.vcf" # Annotated with snpEff variant effects
dbsnp_vcf_suffix="_dbsnp.vcf" # Annotated with dbSNP IDs
fully_ann_vcf_suffix="_fully_ann.vcf" # Annotated with dbSNP & ClinVar IDs
filtered_vcf_suffix=""
filtered_loose_vcf_suffix=""
filtered_custom_vcf_suffix=""

# Downloads/installs SnpEff/SnpSift.
# Downloads annotation files for ClinVar and dbSNP if they do not exist
download_files () {
  # Install SnpEff/SnpSift
  if [ ! -d "${snpEff_dir}" ]; then
  wget https://snpeff.blob.core.windows.net/versions/snpEff_latest_core.zip
  unzip snpEff_latest_core.zip
  rm snpEff_latest_core.zip
  fi
  
  # Download annotation files
  [ -d  $annotation_files_dir ] && return 0 # Return if annotation directory exists
  mkdir -p $annotation_files_dir
  
  # Download dbSNP Annotation file
  annotation_file_url="https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-All.vcf.gz"
  echo "Downloading dbSNP Annotation File" 
  wget -c $annotation_file_url -O $dbsnp_annotation_file_path
  bcftools index -f -t $dbsnp_annotation_file_path
  echo "Finished Downloading dbSNP Annotation File"
  
  # Download Clinvar Annotation file
  annotation_file_url="https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz"
  echo "Downloading Clinvar Annotation File" 
  wget -c $annotation_file_url -O $clinvar_annotation_file_path
  bcftools index -f -t $clinvar_annotation_file_path
  echo "Finished Downloading Clinvar Annotation File" 
  return 0
}

# Annotate VCF with snpEff-identified variant effects and ClinVar & dbSNP IDs
# Parameters: 1 = Path to input VCF, 2 = Path to output VCF
annotate_vcf () {
  input_vcf=$1
  output_vcf_path=$2
  
  echo "Annotate VCF with snpEff-identified variant effects"
  eff_vcf="${output_vcf_path}${eff_vcf_suffix}"
  java -Xmx16g -jar "snpEff/snpEff.jar" -csvStats snpEff_summary.csv -v GRCh38.105 $input_vcf > $eff_vcf
  mv snpEff_* "$(dirname $eff_vcf)" # Move snpEff-generated summary files to output directory
  
  echo "Annotate VCF with dbSNP IDs"
  dbsnp_vcf="${output_vcf_path}${dbsnp_vcf_suffix}"
  java -Xmx16g -jar "snpEff/SnpSift.jar" annotate -id  "$dbsnp_annotation_file_path" $eff_vcf > $dbsnp_vcf
  
  echo "Annotate VCF with Clinvar IDs"
  java -Xmx16g -jar "snpEff/SnpSift.jar" annotate -id "$clinvar_annotation_file_path" $dbsnp_vcf > $fully_ann_vcf
}

# Strictly filter for gene of interest
# Parameters: 1 = Path to output VCF
filter_vcf_strict () {
  output_vcf_path=$1
  
  echo "Filter for $filter_gene"
  filtered_vcf="${output_vcf_path}${filtered_vcf_suffix}"
  java -Xmx16g -jar "snpEff/SnpSift.jar" filter "ANN[*].GENE has '$filter_gene'" $fully_ann_vcf > $filtered_vcf
}

# Loosely filter for gene of interest
# Parameters: 1 = Path to output VCF
filter_vcf_loose () {
  output_vcf_path=$1
  
  echo "Filter for $filter_gene"
  filtered_vcf="${output_vcf_path}${filtered_loose_vcf_suffix}"
  grep -E "^#|.*$filter_gene.*" $fully_ann_vcf > $filtered_vcf
  
}

# Filter for gene of interest with custom parameters.
# Default is "PASS" in addition to strictly filtering for gene of interest.
# Parameters: 1 = Path to output VCF
filter_vcf_custom () {
  output_vcf_path=$1
  
  echo "Filter for $filter_gene"
  filtered_vcf="${output_vcf_path}${filtered_custom_vcf_suffix}"
  java -Xmx16g -jar "${root_rel_path}snpEff/SnpSift.jar" filter "(FILTER = 'PASS') & (ANN[*].GENE has '$filter_gene')" $fully_ann_vcf > $filtered_vcf
}

# Main Function
main () {
  # Get CLI args
  input_vcf_path=$1 # Path to input VCF for processing
  base_vcf_name=$2 # Base name for output VCFs (e.g., H2228_CTL)
  filter_gene=$3 # Gene to filter for (e.g., BRAF)
  to_filter_only=${4:-false} # Flag ('true' or 'false') to determine if only filtering
  
  # Check if CLI args were actually given.
  ((!$#)) && \
      echo "Usage: ./annotateVCF.sh INPUT_VCF_PATH BASE_VCF_NAME FILTER_GENE [FILTER_ONLY]" \
    && exit 1
    
    # Manage log files
    mkdir -p $log_path
    
    [ -e $log_file ] && rm $log_file
    [ -e $err_file ] && rm $err_file
    
    # Check if input VCF exists
    [ ! -e $input_vcf_path ] && echo "Could not find the input VCF at $input_vcf_path" &>> $err_file && return 1
    
    # Convert to_filter_only to lower case
    to_filter_only=$(echo "$to_filter_only" | tr '[:upper:]' '[:lower:]')
    
    # Output path is same as input path
    path=$(dirname $input_vcf_path)
    outfile_path="${path}/${outfile_name}"
    output_vcf_path="$outfile_path/${base_vcf_name}"
    
    # Call functions to download neccessary files, annotate and filter input VCF
    fully_ann_vcf="${output_vcf_path}${fully_ann_vcf_suffix}"
    if [ "$to_filter_only" != true ]; then
    download_files 1>>"$log_file" 2>>"$err_file"
    annotate_vcf "$input_vcf_path" "$output_vcf_path" 1>>"$log_file" 2>>"$err_file"
    fi
    
    # Define filtered VCF suffixes
    filtered_vcf_suffix="_${filter_gene}.vcf"
    filtered_loose_vcf_suffix="_${filter_gene}_loose.vcf"
    filtered_custom_vcf_suffix="_${filter_gene}_custom.vcf"
    # Check fully_ann_vcf exists before attempting to filter it.
    [ ! -e $fully_ann_vcf ] && echo "Could not find the annotated VCF at $fully_ann_vcf" &>> $err_file && return 1 
    filter_vcf_strict "$output_vcf_path" 1>>"$log_file" 2>>"$err_file"
    
    echo "$script_name Finished"
}

main "$@"
