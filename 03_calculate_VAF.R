# WES post-processing - Calculate VAF from Strelka VCF output 

# Strelka does not auto calcualte VAFs, thus performing the following calculation
# Ref: https://grunwaldlab.github.io/Population_Genetics_in_R/reading_vcf.html#:~:text=Using%20the%20R%20package%20vcfR,in%20the%20three%20VCF%20regions.&text=After%20we%20have%20made%20any,file%20with%20the%20function%20write.

# Option 1: Use ICAMS (SNV only) -----------------------------------------------
# install.packages(c("ICAMS"))
library(ICAMS)
# BiocManager::install("BSgenome")
library(BSgenome)

dir <- "/WES"
vcf_name <- "geneSNP.vcf"
file <- file.path(dir,vcf_name)
df <- MakeDataFrameFromVCF(file)
vaf <- GetStrelkaVAF(df)

# Option 2: Manual Calculation ------------------------------------------------
# install.packages(c("vcfR"))
library(vcfR)

setwd("/WES")
goi <- read.vcfR("goi.vcf", verbose = FALSE) 
tail(NRAS@fix)
NRAS@gt

# SNV VAF ----------------------------------------------------------------------
  # refCounts = Value of FORMAT column $REF + “U” (e.g. if REF="A" then use the value in FOMRAT/AU)
  # altCounts = Value of FORMAT column $ALT + “U” (e.g. if ALT="T" then use the value in FOMRAT/TU)
  # tier1RefCounts = First comma-delimited value from $refCounts
  # tier1AltCounts = First comma-delimited value from $altCounts
  # Somatic allele freqeuncy is $tier1AltCounts / ($tier1AltCounts + $tier1RefCounts)
# Calculate
vaf_snp <- 35 / (35 + 98)  # TU / (TU + AU), VAF = 0.2631579

# Indel VAF --------------------------------------------------------------------
  # tier1RefCounts = First comma-delimited value from FORMAT/TAR
  # tier1AltCounts = First comma-delimited value from FORMAT/TIR
  # Somatic allele freqeuncy is $tier1AltCounts / ($tier1AltCounts + $tier1RefCounts)
vaf_indel <- 4 / (4 + 26) # TIR / (TIR + TAR), VAF = 0.13
# TAR and TIR are "26,26" and "4,4," respectively


sessionInfo()
