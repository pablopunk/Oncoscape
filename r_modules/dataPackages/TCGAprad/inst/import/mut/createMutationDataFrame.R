# createMatrix.R
# the mrna comes from cBio 2013 TCGA prad expression data set
# the serialized result is written to extdata, as a numerical matrix  conforming to
# oncoscape protocols:
#
#   NA for missing values
#   sample names for rownames
#   gene symbols for colnames
#   policies yet to be worked out for gene isoforms and multiple measurements for each sample
#
#----------------------------------------------------------------------------------------------------
library(RUnit)

table.mut <- read.table(file="../../../../RawData/TCGAprad/mysql_cbio_mut.txt", header=T, as.is=T)
## 71218 samples x gene protein changes

samples <- unique(table.mut[,"sample_id"])
sample.tbl <- read.delim(file="../../../../RawData/TCGAprad/mysql_cbio_samples.txt", header=T, as.is=T, sep="\t")
BarcodeSample <- sample.tbl[match(samples, sample.tbl[,1]), 2]
BarcodeSample <- gsub("\\-", "\\.", BarcodeSample)
## 261 samples

EntrezGenes <- unique(table.mut[,"entrez_gene_id"])
genes.tbl <- read.delim(file="../../../../RawData/mysql_cbio_genes.txt", header=T, as.is=T, sep="\t")
HugoGenes <- genes.tbl[match(EntrezGenes, genes.tbl[,1]), 2]
## 7047 genes

mtx.mut <- matrix("", nrow = length(samples),ncol=length(EntrezGenes))
dimnames(mtx.mut) <- list(samples,EntrezGenes)

for(pt in samples){
  changes <- which(table.mut$sample_id == pt)
  pt.genes <- table.mut[changes, "entrez_gene_id"]
  pt.mut <- table.mut[changes, "protein_change"]

  duplicated.genes <- which(duplicated(pt.genes))
  if(length(duplicated.genes) >0){

    dup.gene.ids <- unique(pt.genes[duplicated.genes])
    orig.gene <- sapply(dup.gene.ids, function(gene){
      which(pt.genes == gene)[1]
    })
    uniq.mut <- sapply(dup.gene.ids, function(gene) {
       paste(pt.mut[which(pt.genes == gene)], collapse=";")
    })
    
    pt.mut[orig.gene] <- uniq.mut
    pt.genes <- pt.genes[-duplicated.genes]
    pt.mut <- pt.mut[-duplicated.genes]
  }
  mtx.mut[as.character(pt),sapply(pt.genes, as.character)] <- pt.mut 
}

dimnames(mtx.mut) <- list(BarcodeSample,HugoGenes)

checkEquals(mtx.mut["TCGA.HC.7233.01", "ERAP2"], "D735V")
checkEquals(mtx.mut["TCGA.HC.7818.01", "NCOR1P1"], "H33R")
checkEquals(mtx.mut["TCGA.EJ.5502.01", "RNF121"], "")

checkEquals(dim(mtx.mut), c(261, 7047))
checkEquals(length(which(is.na(mtx.mut))), 0)   # all null values stored as emptry strings - no NAs

checkTrue(all(unlist(lapply(mtx.mut, class), use.names=FALSE) == "character"))
save(mtx.mut, file="../../extdata/mtx.mut.RData")
