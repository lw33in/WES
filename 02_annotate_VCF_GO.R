#!/usr/bin/env Rscript
# Annotate given (dbsnp) query TSV with GO IDs.

# Load packages ----------------------------------------------------------------
library(clusterProfiler)
library(readr)
library(dplyr)
library(optparse)
require(org.Hs.eg.db)

# Get commandline arguments ----------------------------------------------------
option_list <- list(
  make_option(c("-f", "--query_tsv_fp"), type="character", default=NULL,
              help="[REQUIRED] Queries TSV filepath", metavar="character"),
  make_option(c("-o", "--outfile_path"), type="character", default="out.tsv",
              help="Output file path [default = %default]", metavar="character")
);
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are given ----------------------------------------
if (is.null(opt$query_tsv_fp)){
  print_help(opt_parser)
  stop("Query TSV is required.")
}

query_tsv <- read_tsv(opt$query_tsv_fp)
query_tsv[query_tsv=="N/A"] <- NA

# Splits gene IDs into different entries ---------------------------------------
# E.g. x[1] = 111 222 becomes y[1] = 111, y[2] = 222
query_gene_ids <- c()
for (id in query_tsv$GENE_ID) {
  query_gene_ids <- c(query_gene_ids, scan(text = id, what = "", quiet=TRUE))
}
query_gene_ids <- unique(query_gene_ids)

# Get GO IDs -------------------------------------------------------------------
go_ids <- bitr(query_gene_ids, fromType="ENTREZID", toType="GOALL", OrgDb="org.Hs.eg.db")

# Merge based on Entrez IDs 
merged_tsv <- merge(query_tsv, go_ids[, c("ENTREZID", "GOALL")], by.x="GENE_ID", by.y="ENTREZID", all=TRUE)

# Consolidate rows based on GO IDs 
  group_by(across(-GOALL)) %>%
  summarise(GOALL = paste(GOALL, collapse = ", "))

write_tsv(consol_merged_tsv, opt$outfile_path)
