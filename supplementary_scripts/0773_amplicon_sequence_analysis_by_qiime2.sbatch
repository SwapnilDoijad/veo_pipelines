#!/bin/bash
#SBATCH --job-name 0773_amplicon_sequence_analysis_by_qiime2
#SBATCH --partition=short,interactive,standard,long,gpu
#SBATCH --output results/0773_amplicon_sequence_analysis_by_qiime2/tmp/slurm/%J.out
#SBATCH --error results/0773_amplicon_sequence_analysis_by_qiime2/tmp/slurm/%j.err
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
#SBATCH --mail-type=END
#SBATCH --mail-user=your_email@example.com
###############################################################################
## header
	pipeline=0773_amplicon_sequence_analysis_by_qiime2
  source /home/groups/VEO/scripts_for_users/supplementary_scripts/my_functions.sh
	log "STARTED: $pipeline -----------------------------"
###############################################################################

####Rare_phylotypes in the USD microbiome
library(phyloseq)
library(Biostrings)
library(ggplot2)
library(microbiome)
library(metagMisc)
library(plyr)
library(DECIPHER)
library(vegan)
library(DESeq2)
library(decontam)
library(ggpubr)
library(ape)
library(dada2)

#######Setting your working directory - where all your data files are and where you want your results to go.  This will be project specific.  In the below code, I have it set to our group project.  You can figure out the working directory by pulling the directory into terminal.  From there, you can just copy and paste that into the quotes below.

setwd("pwd_of_sequence_data")
path <- "metaanalysis"
fnFs <- sort(list.files(path, pattern="_R1", full.names = TRUE))
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)
filtFs <- file.path(path, "filtered", paste0(sample.names, "_F_filt.fastq.gz"))
names(filtFs) <- sample.names
out <- filterAndTrim(fnFs, filtFs, truncLen=c(150),
              maxN=0, maxEE=c(10), truncQ=2, rm.phix=TRUE,
              compress=TRUE, multithread=TRUE)
              
              
##Learn error rates              
errF <- learnErrors(filtFs, multithread=TRUE)
##Sample inference
dadaFs <- dada(filtFs, err=errF, multithread=TRUE)
##Make count table
seqtab <- makeSequenceTable(dadaFs)
##Remove Chimeras
seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE, verbose=TRUE)
##Assign taxonomy
taxa <- assignTaxonomy(seqtab.nochim, "new_refseqs_asv_bacteria.fna", multithread=TRUE)


###Move to phyloseq for further processing
samples.out <- rownames(seqtab.nochim)
ps <- phyloseq(otu_table(seqtab.nochim, taxa_are_rows=FALSE),
               tax_table(taxa))
write.table(otu_table(ps), "otu_table_seqs.txt", sep="\t")
write.table(tax_table(ps), "tax_table_seqs.txt", sep="\t")
####The above block of code saves your count and taxonomy tables with raw sequences as identifiers.  Open the files up.  Specifically, you want to see if a reasonable proportion of your ASVs have some taxonomic classification.  If a majority of them are "NA" through the entire taxonomic lineage, something went wrong with assignment.  Ask Aaron about troubleshooting.
setwd("metaanalysis")

##Filter data for downstream analysis - Remove host contamination
ps <- subset_taxa(ps, (Class!="Chloroplast") | is.na(Class))
ps <- subset_taxa(ps, (Order!="Rickettsiales") | is.na(Order))
ps <- subset_taxa(ps, (Kingdom!="Eukaryota") | is.na(Kingdom))
ps <- subset_taxa(ps, !(Phylum %in% c(NA)))
write.table(otu_table(ps), "otu_table_seqs_nohost.txt", sep="\t")
write.table(tax_table(ps), "tax_table_seqs_nohost.txt", sep="\t")

##Generate phylogenetic tree - This step will take a day or 2
seqs <- getSequences(otu_table(ps))
names(seqs) <- seqs
alignment <- AlignSeqs(DNAStringSet(seqs), anchor=NA)
phang.align <- phyDat(as(alignment, "matrix"), type="DNA")
dm <- dist.ml(phang.align)
treeNJ <- NJ(dm) # Note, tip order != sequence order
fit = pml(treeNJ, data=phang.align)

## negative edges length changed to 0!

fitGTR <- update(fit, k=4, inv=0.2)
fitGTR <- optim.pml(fitGTR, model="GTR", optInv=TRUE, optGamma=TRUE,
                       rearrangement = "stochastic", control = pml.control(trace = 0))
detach("package:phangorn", unload=TRUE)
ps <- phyloseq(otu_table(ps),  
               tax_table(ps), phy_tree(fitGTR$tree))
tree1 = phy_tree(fitGTR$tree)
ape::write.tree(tree1, "rep_set.tre")  ##Save phylogenetic tree
sampledata <- read.table("current_map.txt", header=TRUE, check.names=FALSE, sep="\t", row.names=1)
ps = phyloseq(otu_table(ps), tax_table(ps), phy_tree(tree1), sample_data(sampledata))


###Remove redundancy by grouping ASV's with 97% sequence homology with cd-hit
cd-hit -c 0.97 -i JAMS_100.fasta -o JAMS_100_97hom.fasta 

###Turn dereplicated database into bowtie2 index - in terminal
bowtie2-build JAMS_100_97hom.fasta  derep
bowtie2 -x derep -f JAMS_100.fasta -S derep.sam
samtools view -S -F 4 -h derep.sam derep_mapped.sam
samtools fasta derep_mapped.sam derep_mapped_fasta
awk '{print $1,$3}' derep_mapped.sam derep_mapped_count.txt
####Dereplicate taxa in excel, merge otu file by dereplicated asvs
python
import pandas as pd
data = pd.read_csv('otu_table_seqs_nohost.txt', sep="	") ##the large space there is a tab.  Replace text.txt with your target file name
data = data.groupby(data['derep'].str.lower()).sum() ##Replace ID with whatever your column names are
data.to_csv('otu_table_seqs_nohost_derep.txt', sep='	')

##Recreate phyloseq object with dereplicated data
otu.file <- read.csv("otu_table_seqs_nohost_derep.txt", header = TRUE, sep="\t", stringsAsFactors=FALSE, row.names=1, check.names=FALSE)
tax.file <- as.matrix(read.csv("tax_table_seqs_nohost_ASV.txt", header = TRUE, sep="\t", row.names=1))
taxa_names(tree1) <- paste0("ASV", seq(ntaxa(ps)))
ps = phyloseq(otu_table(otu.file, taxa_are_rows=TRUE), sample_data(ps), tax_table(tax.file), phy_tree(tree1))

###Subset urine and stone and compare

samp_type <- c("Bacteria")
ps_nobact = subset_samples(ps, !(Sample_type %in% samp_type))
pd_alpha <-  phyloseq_phylo_div(ps_nobact, measures = c("PD"))  ##Calculate alpha - change ps object
bind <- cbind(pd_alpha, sample_data(ps_nobact))  ##bind alpha and metadata - change ps object
f1 <- as.data.frame(bind$Sample_type)  ##Put variable of interest into variable as dataframe
f2 <- f1[!duplicated(f1), ]  ##Dereplicate values so that each group is represented once
f3 <- list()
for(i in 1:ncol(combn(unique(f2),2))) {             # Using for-loop to add columns to list
+   f3[[i]] <- combn(unique(f2),2)[ , i]
+ }
lab_y <- mean(bind$PD * 2.2)  ##Automate position of global p-value
ggplot(bind, aes(y = PD, x = Sample_type, color = Sample_type)) + geom_boxplot(outlier.shape = NA, size=1.5) + geom_point(position = position_jitterdodge(jitter.width = 0.1), size=3) + xlab("Sample_type") + labs(color="Sample_type") +ylab("Phylogenetic diversity") + ggtitle("Species richness by Assay" ) + theme_classic()  + theme(plot.title = element_text(hjust = 0.5)) + stat_compare_means(comparisons = f3, size=10, symnum.args = list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1), symbols = c("****", "***", "**", "*", "ns"))) + stat_compare_means(label.y = lab_y*2, size=10) + theme(text = element_text(size=25, color="black"))
quartz.save("JAMS100_alpha_sample_type_all.pdf", type="pdf")

pairwise.adonis <- function(x,factors, sim.function = 'vegdist', sim.method = 'bray', p.adjust.m ='fdr')
{
library(vegan)

co = combn(unique(as.character(factors)),2)
pairs = c()
F.Model =c()
R2 = c()
p.value = c()


for(elem in 1:ncol(co)){
if(sim.function == 'daisy'){
library(cluster); x1 = daisy(x[factors %in% c(co[1,elem],co[2,elem]),],metric=sim.method)
} else{x1 = vegdist(x[factors %in% c(co[1,elem],co[2,elem]),],method=sim.method)}

ad = adonis2(x1 ~ factors[factors %in% c(co[1,elem],co[2,elem])] );
pairs = c(pairs,paste(co[1,elem],'vs',co[2,elem]));
F.Model =c(F.Model,ad$aov.tab[1,4]);
R2 = c(R2,ad$aov.tab[1,5]);
p.value = c(p.value,ad$aov.tab[1,6])
}
p.adjusted = p.adjust(p.value,method=p.adjust.m)
sig = c(rep('',length(p.adjusted)))
sig[p.adjusted <= 0.05] <-'.'
sig[p.adjusted <= 0.01] <-'*'
sig[p.adjusted <= 0.001] <-'**'
sig[p.adjusted <= 0.0001] <-'***'

pairw.res = data.frame(pairs,F.Model,R2,p.value,p.adjusted,sig)
print("Signif. codes:  0 ë***í 0.001 ë**í 0.01 ë*í 0.05 ë.í 0.1 ë í 1")
return(pairw.res)

} 

ps_log2 <- transform_sample_counts(ps_nobact,log2)
otu_table(ps_log2)[otu_table(ps_log2) < 0.0] <- 0.0
f1 <- sample_data(ps_log2)$Sample_type
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_log2, method="unifrac")))
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pval <- pm[[5]]
pm2 <- pairwise.adonis(ps.dist, f1)
pm2
pval2 <- pm2[[5]]
pval_lab <- pm2[[1]]
lab <- paste(pval_lab, "=", pval2)
lab2 <- c("paired_p", lab)
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 3)
rp[1] = substitute(paste(italic(pvalues)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Sample_type) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
lab <- paste(pval_lab, "=", pval2)
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Health", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(f1)), col=1:8, pch=1:8, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("JAMS100_beta_all.pdf", type="pdf")


Kindly see some references:

1. Package 'labdsv' for raretaxa sorting:

https://rdrr.io/cran/labdsv/man/raretaxa.html
library(labdsv)
raretaxa(otu_table(ps_ut),min=1,log=FALSE,type='b', panel='all')
samp_type <- c("stone")
ps_stone = subset_samples(ps, (Sample_type %in% samp_type))
samp_type <- c("urine")
ps_urine = subset_samples(ps, (Sample_type %in% samp_type))
raretaxa(otu_table(ps_stone),min=1,log=FALSE,type='b', panel='all')
quartz.save("rare_species_per_sample_stone.pdf", type="pdf")
quartz.save("mean_abundance_rare_species_per_sample_stone.pdf", type="pdf")
quartz.save("total_abundance_rare_species_per_sample_stone.pdf", type="pdf")
raretaxa(otu_table(ps_urine),min=1,log=FALSE,type='b', panel='all')
quartz.save("rare_species_per_sample_urine.pdf", type="pdf")
quartz.save("mean_abundance_rare_species_per_sample_urine.pdf", type="pdf")
quartz.save("total_abundance_rare_species_per_sample_urine.pdf", type="pdf")
 

2. Stats on raretaxa:

https://www.frontiersin.org/articles/10.3389/fmicb.2020.607325/full

https://environmentalmicrobiome.biomedcentral.com/articles/10.1186/s40793-022-00436-y

https://www.sciencedirect.com/science/article/pii/S200103702100516X

 

3. Rare species and genomic signature analyses:

https://www.nature.com/articles/s43705-021-00010-6

https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6343076/

######Separate rare and common taxa.  Define rare taxa as <50% prevalence and <0.5% relative abundance per stool, urine, stone


samp_type <- c("stone")
ps_stone = subset_samples(ps, (Sample_type %in% samp_type))
ps_stone = prune_taxa(taxa_sums(ps_stone) 0, ps_stone) 
samp_type <- c("urine")
ps_urine = subset_samples(ps, (Sample_type %in% samp_type))
ps_urine = prune_taxa(taxa_sums(ps_urine) 0, ps_urine) 
samp_type <- c("stool")
ps_stool = subset_samples(ps, (Sample_type %in% samp_type))
ps_stool = prune_taxa(taxa_sums(ps_stool) 0, ps_stool) 
raretaxa(otu_table(ps_stool),min=1,log=FALSE,type='b', panel='all')
quartz.save("rare_species_per_sample_stool.pdf", type="pdf")
quartz.save("mean_abundance_rare_species_per_sample_stool.pdf", type="pdf")
quartz.save("total_abundance_rare_species_per_sample_stool.pdf", type="pdf")

##Plot histogram of urine, stool, stone counts per taxa
tdt = data.table(tax_table(ps_stone),
                 TotalCounts = log(taxa_sums(ps_stone)),
                 OTU = taxa_names(ps_stone))
ggplot(tdt, aes(TotalCounts)) + 
  geom_histogram() + 
  ggtitle("Histogram of Total Counts") + xlab("Log-transformed no. of counts/ASV") + ylab("No. of ASV's") + theme_classic() + theme(text = element_text(size=15))
quartz.save("dist_asvs_total_counts_stone.pdf", type="pdf")
  
tdt = data.table(tax_table(ps_stool),
                 TotalCounts = log(taxa_sums(ps_stool)),
                 OTU = taxa_names(ps_stool))
ggplot(tdt, aes(TotalCounts)) + 
  geom_histogram() + 
  ggtitle("Histogram of Total Counts") + xlab("Log-transformed no. of counts/ASV") + ylab("No. of ASV's") + theme_classic() + theme(text = element_text(size=15))
quartz.save("dist_asvs_total_counts_stool.pdf", type="pdf")

tdt = data.table(tax_table(ps_urine),
                 TotalCounts = log(taxa_sums(ps_urine)),
                 OTU = taxa_names(ps_urine))
ggplot(tdt, aes(TotalCounts)) + 
  geom_histogram() + 
  ggtitle("Histogram of Total Counts") + xlab("Log-transformed no. of counts/ASV") + ylab("No. of ASV's") + theme_classic() + theme(text = element_text(size=15))
quartz.save("dist_asvs_total_counts_urine.pdf", type="pdf")  
  
  
  
###Plot ASV prevalence
fast_melt = function(physeq,
                     includeSampleVars = character(),
                     omitZero = FALSE){
  require("phyloseq")
  require("data.table")
  # supports "naked" otu_table as `physeq` input.
  otutab = as(otu_table(physeq), "matrix")
  if(!taxa_are_rows(physeq)){otutab <- t(otutab)}
  otudt = data.table(otutab, keep.rownames = TRUE)
  setnames(otudt, "rn", "TaxaID")
  # Enforce character TaxaID key
  otudt[, TaxaIDchar := as.character(TaxaID)]
  otudt[, TaxaID := NULL]
  setnames(otudt, "TaxaIDchar", "TaxaID")
  # Melt count table
  mdt = melt.data.table(otudt, 
                        id.vars = "TaxaID",
                        variable.name = "SampleID",
                        value.name = "count")
  if(omitZero){
    # Omit zeroes and negative numbers
    mdt <- mdt[count 0]
  }
  # Omit NAs
  mdt <- mdt[!is.na(count)]
  # Calculate relative abundance
  mdt[, RelativeAbundance := count / sum(count), by = SampleID]
  if(!is.null(tax_table(physeq, errorIfNULL = FALSE))){
    # If there is a tax_table, join with it. Otherwise, skip this join.
    taxdt = data.table(as(tax_table(physeq, errorIfNULL = TRUE), "matrix"), keep.rownames = TRUE)
    setnames(taxdt, "rn", "TaxaID")
    # Enforce character TaxaID key
    taxdt[, TaxaIDchar := as.character(TaxaID)]
    taxdt[, TaxaID := NULL]
    setnames(taxdt, "TaxaIDchar", "TaxaID")
    # Join with tax table
    setkey(taxdt, "TaxaID")
    setkey(mdt, "TaxaID")
    mdt <- taxdt[mdt]
  }
  # includeSampleVars = c("DaysSinceExperimentStart", "SampleType")
  # includeSampleVars = character()
  # includeSampleVars = c()
  # includeSampleVars = c("aksjdflkas") 
  wh.svars = which(sample_variables(physeq) %in% includeSampleVars)
  if( length(wh.svars) 0 ){
    # Only attempt to include sample variables if there is at least one present in object
    sdf = as(sample_data(physeq), "data.frame")[, wh.svars, drop = FALSE]
    sdt = data.table(sdf, keep.rownames = TRUE)
    setnames(sdt, "rn", "SampleID")
    # Join with long table
    setkey(sdt, "SampleID")
    setkey(mdt, "SampleID")
    mdt <- sdt[mdt]
  }
  setkey(mdt, "TaxaID")
  return(mdt)
}

summarize_taxa = function(physeq, Rank, GroupBy = NULL){
  require("phyloseq")
  require("data.table")
  Rank <- Rank[1]
  if(!Rank %in% rank_names(physeq)){
    message("The argument to `Rank` was:\n", Rank,
            "\nBut it was not found among taxonomic ranks:\n",
            paste0(rank_names(physeq), collapse = ", "), "\n",
            "Please check the list shown above and try again.")
  }
  if(!is.null(GroupBy)){
    GroupBy <- GroupBy[1]
    if(!GroupBy %in% sample_variables(physeq)){
      message("The argument to `GroupBy` was:\n", GroupBy,
              "\nBut it was not found among sample variables:\n",
              paste0(sample_variables(physeq), collapse = ", "), "\n",
              "Please check the list shown above and try again.")
    }
  }
  # Start with fast melt
  mdt = fast_melt(physeq)
  if(!is.null(GroupBy)){
    # Add the variable indicated in `GroupBy`, if provided.
    sdt = data.table(SampleID = sample_names(physeq),
                     var1 = get_variable(physeq, GroupBy))
    setnames(sdt, "var1", GroupBy)
    # Join
    setkey(sdt, SampleID)
    setkey(mdt, SampleID)
    mdt <- sdt[mdt]
  }
  # Summarize
  if(!is.null(GroupBy)){
    summarydt = mdt[, list(meanRA = mean(RelativeAbundance),
                           sdRA = sd(RelativeAbundance),
                           minRA = min(RelativeAbundance),
                           maxRA = max(RelativeAbundance)),
                    by = c(Rank, GroupBy)]
  } else {
    Nsamples = nsamples(physeq)
    # No GroupBy argument, can be more precise with the mean, sd, etc.
    summarydt = mdt[, list(meanRA = sum(RelativeAbundance) / Nsamples,
                           sdRA = sd(c(RelativeAbundance, numeric(Nsamples - .N))),
                           minRA = ifelse(test = .N < Nsamples,
                                          yes = 0L, 
                                          no = min(RelativeAbundance)),
                           maxRA = max(RelativeAbundance)),
                    by = c(Rank)]
  }
  return(summarydt)
}

plot_taxa_summary = function(physeq, Rank, GroupBy = NULL){
  require("phyloseq")
  require("data.table")
  require("ggplot2")
  # Get taxa summary table 
  dt1 = summarize_taxa(physeq, Rank = Rank, GroupBy = GroupBy)
  # Set factor appropriately for plotting
  RankCol = which(colnames(dt1) == Rank)
  setorder(dt1, -meanRA)
  dt1[, RankFac := factor(dt1[[Rank]], 
                          levels = rev(dt1[[Rank]]))]
  dt1[, ebarMax := max(c(0, min(meanRA + sdRA))), by = eval(Rank)]
  dt1[, ebarMin := max(c(0, min(meanRA - sdRA))), by = eval(Rank)]
  # Set zeroes to one-tenth the smallest value
  ebarMinFloor = dt1[(ebarMin 0), min(ebarMin)]
  ebarMinFloor <- ebarMinFloor / 10
  dt1[(ebarMin == 0), ebarMin := ebarMinFloor]
  pRank = ggplot(dt1, aes(x = meanRA, y = RankFac)) +
    scale_x_log10() +
    xlab("Mean Relative Abundance") +
    ylab(Rank) +
    theme_bw()
  if(!is.null(GroupBy)){
    # pRank <- pRank + facet_wrap(facets = as.formula(paste("~", GroupBy)))
    pRank <- pRank + geom_point(mapping = aes_string(colour = GroupBy),
                                size = 5)
  } else {
    # Don't include error bars for faceted version
    pRank <- pRank + geom_errorbarh(aes(xmax = ebarMax,
                                        xmin = ebarMin))
  }
  return(pRank)
}
  
mdt = fast_melt(ps_stone)
prevdt = mdt[, list(Prevalence = sum(count 0)/0.63, 
                    TotalCounts = sum(count)),
             by = TaxaID]
ggplot(prevdt, aes(Prevalence)) + 
  geom_histogram() + 
  ggtitle("Histogram of Taxa Prevalence") + xlab("Prevalence of ASV's(%)") + ylab("Total counts of ASV's/% prevalence") + theme_classic() + theme(text = element_text(size=15))
quartz.save("prevalence_asvs_stone.pdf", type="pdf")

mdt = fast_melt(ps_stool)
prevdt = mdt[, list(Prevalence = sum(count 0)/1.59, 
                    TotalCounts = sum(count)),
             by = TaxaID]
ggplot(prevdt, aes(Prevalence)) + 
  geom_histogram() + 
  ggtitle("Histogram of Taxa Prevalence") + xlab("Prevalence of ASV's(%)") + ylab("Total counts of ASV's/% prevalence") + theme_classic() + theme(text = element_text(size=15))
quartz.save("prevalence_asvs_stool.pdf", type="pdf")

mdt = fast_melt(ps_urine)
prevdt = mdt[, list(Prevalence = sum(count 0)/1.77, 
                    TotalCounts = sum(count)),
             by = TaxaID]
ggplot(prevdt, aes(Prevalence)) + 
  geom_histogram() + 
  ggtitle("Histogram of Taxa Prevalence") + xlab("Prevalence of ASV's(%)") + ylab("Total counts of ASV's/% prevalence") + theme_classic() + theme(text = element_text(size=15))
quartz.save("prevalence_asvs_urine.pdf", type="pdf")

###Calculate average prevalence and counts per taxa for stool, urine, stone
 mdt = fast_melt(ps_stone)
prevdt_stone = mdt[, list(Prevalence = log(sum(count 0)/0.63), 
                    TotalCounts = sum(count)),
             by = TaxaID]
prevdt_stone$Type <- 'Stone'

mdt = fast_melt(ps_stool)
prevdt_stool = mdt[, list(Prevalence = log(sum(count 0)/1.59), 
                    TotalCounts = sum(count)),
             by = TaxaID]
prevdt_stool$Type <- 'Stool'

mdt = fast_melt(ps_urine)
prevdt_urine = mdt[, list(Prevalence = log(sum(count 0)/1.77), 
                    TotalCounts = sum(count)),
             by = TaxaID]
prevdt_urine$Type <- 'Urine'

prevdt_all <- rbind(prevdt_stone, prevdt_stool, prevdt_urine)

f1 <- as.data.frame(prevdt_all$Type)  ##Put variable of interest into variable as dataframe
f2 <- f1[!duplicated(f1), ]  ##Dereplicate values so that each group is represented once
f3 <- list()
for(i in 1:ncol(combn(unique(f2),2))) {             # Using for-loop to add columns to list
  f3[[i]] <- combn(unique(f2),2)[ , i]
}
lab_y <- mean(prevdt_all$Prevalence * 2.2)  ##Automate position of global p-value
ggplot(prevdt_all, aes(y = Prevalence, x = Type, color = Type)) + geom_boxplot(outlier.shape = NA, size=1.5) + geom_point(position = position_jitterdodge(jitter.width = 0.1), size=3) + xlab("Sample type") + labs(color="Sample Type") +ylab("ASV Prevalence (%)") + ggtitle("Prevalence of ASV's by sample type" ) + theme_classic() + theme(plot.title = element_text(hjust = 0.5)) + stat_compare_means(comparisons = f3, size=10, symnum.args = list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1), symbols = c("****", "***", "**", "*", "ns"))) + stat_compare_means(label.y = 115, size=10) + theme(text = element_text(size=25, color="black")) +
      stat_summary(aes(label=round(..y..,2)), fun=mean, geom="text", size=6,
             vjust = -19.5)
quartz.save("ASV_prevalence.pdf", type="pdf")

prevdt_all$TotalCounts <- log(prevdt_all$TotalCounts)
ggplot(prevdt_all, aes(y = TotalCounts, x = Type, color = Type)) + geom_boxplot(outlier.shape = NA, size=1.5) + geom_point(position = position_jitterdodge(jitter.width = 0.1), size=3) + xlab("Sample type") + labs(color="Sample Type") +ylab("ASV Counts") + ggtitle("Counts of ASV's by sample type" ) + theme_classic() + theme(plot.title = element_text(hjust = 0.5)) + stat_compare_means(comparisons = f3, size=10, symnum.args = list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1), symbols = c("****", "***", "**", "*", "ns"))) + stat_compare_means(label.y = 18, size=10) + theme(text = element_text(size=25, color="black"))
quartz.save("ASV_counts.pdf", type="pdf")

###Separate out common and rare taxa.  Define rare as <average prevalence and <average counts for a particular sample type
urine prev = 2.19, count = 926.5
stone prev = 3.45, count = 252.6
stool prev = 4.54, count = 2201


ps_stone_common = phyloseq_filter_prevalence(ps_stone, prev.trh = 0.0345, abund.trh = 253, threshold_condition = "AND") 
ps_urine_common = phyloseq_filter_prevalence(ps_urine, prev.trh = 0.0219, abund.trh = 927, threshold_condition = "AND") 
ps_stool_common = phyloseq_filter_prevalence(ps_stool, prev.trh = 0.0454, abund.trh = 2201, threshold_condition = "AND") 

ps_stone_rare = prune_taxa(taxa_sums(ps_stone) < 253, ps_stone)
prev <- (taxa_sums(ps_stone_rare) 0)/63 < 0.0345
prev2 <- prev[prev == TRUE]
prev3 <- as.data.frame(prev2)
prev3$row_names <- row.names(prev3)
prev4 <- prev3[,2]
ps_stone_rare2 = prune_taxa(prev4, ps_stone_rare)

ps_stool_rare = prune_taxa(taxa_sums(ps_stool) < 2201, ps_stool)
prev <- (taxa_sums(ps_stool_rare) 0)/159 < 0.0454
prev2 <- prev[prev == TRUE]
prev3 <- as.data.frame(prev2)
prev3$row_names <- row.names(prev3)
prev4 <- prev3[,2]
ps_stool_rare2 = prune_taxa(prev4, ps_stool_rare)

ps_urine_rare = prune_taxa(taxa_sums(ps_urine) < 927, ps_urine)
prev <- (taxa_sums(ps_urine_rare) 0)/177 < 0.0219
prev2 <- prev[prev == TRUE]
prev3 <- as.data.frame(prev2)
prev3$row_names <- row.names(prev3)
prev4 <- prev3[,2]
ps_urine_rare2 = prune_taxa(prev4, ps_urine_rare)

###Compare beta of rare and common for stone v urine and healthy v usd (stool and urine)
ps_urine_rare3 = phyloseq(otu_table(ps_urine_rare2), tax_table(ps_urine_rare2), sample_data(ps_urine_rare2))
ps_stone_rare3 = phyloseq(otu_table(ps_stone_rare2), tax_table(ps_stone_rare2), sample_data(ps_stone_rare2))
ps_urine_stone_rare = merge_phyloseq(ps_urine_rare3, ps_stone_rare3)
ps_urine_stone_rare2 = phyloseq(otu_table(ps_urine_stone_rare), tax_table(ps_urine_stone_rare), sample_data(ps_urine_stone_rare), phy_tree(tree1))

ps_urine_common3 = phyloseq(otu_table(ps_urine_common), tax_table(ps_urine_common), sample_data(ps_urine_common))
ps_stone_common3 = phyloseq(otu_table(ps_stone_common), tax_table(ps_stone_common), sample_data(ps_stone_common))
ps_urine_stone_common = merge_phyloseq(ps_urine_common3, ps_stone_common3)
ps_urine_stone_common2 = phyloseq(otu_table(ps_urine_stone_common), tax_table(ps_urine_stone_common), sample_data(ps_urine_stone_common), phy_tree(tree1))


ps_urine_stone_rare2_log2 <- transform_sample_counts(ps_urine_stone_rare2,log2)
otu_table(ps_urine_stone_rare2_log2)[otu_table(ps_urine_stone_rare2_log2) < 0.0] <- 0.0
ps_urine_stone_rare2_log22 <- remove_samples(c("3861", "MU.21701"), ps_urine_stone_rare2_log2)
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_urine_stone_rare2_log22, method="unifrac")))
f1 <- sample_data(ps_urine_stone_rare2_log22)$Sample_type
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pm[[5]]
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 4)
rp[1] = substitute(paste(italic(global_p)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Sample_type) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Sample type", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(sample_data(ps_urine_stone_rare2_log22)$Sample_type)), col=1:15, pch=1:15, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("beta_ps_urine_stone_rare2_sample_type.pdf", type="pdf")

ps_urine_stone_common2_log2 <- transform_sample_counts(ps_urine_stone_common2,log2)
otu_table(ps_urine_stone_common2_log2)[otu_table(ps_urine_stone_common2_log2) < 0.0] <- 0.0
ps_urine_stone_common2_log22 <- remove_samples(c("3861", "MU.21701"), ps_urine_stone_common2_log2)
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_urine_stone_common2_log22, method="unifrac")))
f1 <- sample_data(ps_urine_stone_common2_log22)$Sample_type
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pm[[5]]
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 4)
rp[1] = substitute(paste(italic(global_p)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Sample_type) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Sample type", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(sample_data(ps_urine_stone_common2_log22)$Sample_type)), col=1:15, pch=1:15, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("beta_ps_urine_stone_common2_sample_type.pdf", type="pdf")

ps_urine_rare2_log2 <- transform_sample_counts(ps_urine_rare2,log2)
otu_table(ps_urine_rare2_log2)[otu_table(ps_urine_rare2_log2) < 0.0] <- 0.0
ps_urine_rare2_log22 <- remove_samples(c("3861", "MU.21701"), ps_urine_rare2_log2)
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_urine_rare2_log22, method="unifrac")))
f1 <- sample_data(ps_urine_rare2_log22)$Group
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pm[[5]]
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 4)
rp[1] = substitute(paste(italic(global_p)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Health) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Sample type", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(sample_data(ps_urine_rare2_log22)$Group)), col=1:15, pch=1:15, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("beta_ps_urine_rare2_log2_health.pdf", type="pdf")

ps_urine_common_log2 <- transform_sample_counts(ps_urine_common,log2)
otu_table(ps_urine_common_log2)[otu_table(ps_urine_common_log2) < 0.0] <- 0.0
ps_urine_common_log22 <- remove_samples(c("3861", "MU.21701"), ps_urine_common_log2)
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_urine_common_log22, method="unifrac")))
f1 <- sample_data(ps_urine_common_log22)$Group
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pm[[5]]
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 4)
rp[1] = substitute(paste(italic(global_p)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Health) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Sample type", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(sample_data(ps_urine_common_log22)$Group)), col=1:15, pch=1:15, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("beta_ps_urine_common_log2_health.pdf", type="pdf")

ps_stool_common_log2 <- transform_sample_counts(ps_stool_common,log2)
otu_table(ps_stool_common_log2)[otu_table(ps_stool_common_log2) < 0.0] <- 0.0
ps_stool_common_log22 <- remove_samples(c("3861", "MU.21701"), ps_stool_common_log2)
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_stool_common_log22, method="unifrac")))
f1 <- sample_data(ps_stool_common_log22)$Group
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pm[[5]]
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 4)
rp[1] = substitute(paste(italic(global_p)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Health) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Sample type", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(sample_data(ps_stool_common_log22)$Group)), col=1:15, pch=1:15, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("beta_ps_stool_common_log2_health.pdf", type="pdf")

ps_stool_rare2_log2 <- transform_sample_counts(ps_stool_rare2,log2)
otu_table(ps_stool_rare2_log2)[otu_table(ps_stool_rare2_log2) < 0.0] <- 0.0
ps_stool_rare2_log22 <- remove_samples(c("3861", "MU.21701"), ps_stool_rare2_log2)
ps.dist <- as.data.frame(as.matrix(phyloseq::distance(ps_stool_rare2_log22, method="unifrac")))
f1 <- sample_data(ps_stool_rare2_log22)$Group
pm <- adonis2(ps.dist ~ f1, permutations = 999)
pval <- pm[[5]]
pd <- betadisper(as.dist(ps.dist), f1)
eigen <- eigenvals(pd)
pcoa1 <- capture.output(cat("PCoA1 (", scales::percent(eigen["PCoA1"]/sum(eigen), accuracy=0.01), "of variance )"))
pcoa2 <- capture.output(cat("PCoA2 (", scales::percent(eigen["PCoA2"]/sum(eigen), accuracy=0.01), "of variance )"))
rp = vector('expression', 4)
rp[1] = substitute(paste(italic(global_p)), list(MYOTHERVALUE = format(pval[1])))[2]
rp[2] = substitute(expression(italic(Health) == MYOTHERVALUE), list(MYOTHERVALUE = format(pval[1], digits = 3)))[2]
plot(pd, label.cex=0.001, ellipse=TRUE, hull=FALSE, seg.lty="dashed", cex=0.5, main="Beta x Sample type", cex.main=1.5, cex.sub=0.01, cex.lab=1.5, xlab=pcoa1, ylab=pcoa2, axes=c(1,2))
legend(x="bottomleft", legend=levels(as.factor(sample_data(ps_stool_rare2_log22)$Group)), col=1:15, pch=1:15, bty='n')
legend('topright', legend=rp, bty='n')
quartz.save("beta_ps_stool_rare2_log2_health.pdf", type="pdf")

library(Hmisc)
library(data.table)
res2 <- rcorr(as.matrix(t(otu_table(ps_stone))))
write.table(res2$r, "stone_r.txt", sep="\t")
write.table(res2$P, "stone_p.txt", sep="\t")
library(gdata)
sigp <- unmatrix(res2$P)
sigr <- unmatrix(res2$r)
comb <- cbind(sigp, sigr)
sig <- subset(comb, sigr>0.4)
sig2 <- sig[complete.cases(sig), ]
write.table(sig2, "stone_correlation_table_signifcant.txt", sep="\t")
write.table(tax_table(ps_stone_rare2), "ps_stone_rare2_taxa.txt", sep="\t")
write.table(tax_table(ps_stone_common), "ps_stone_common_taxa.txt", sep="\t")

library(Hmisc)
library(data.table)
res2 <- rcorr(as.matrix(t(otu_table(ps_stool))))
write.table(res2$r, "stool_r.txt", sep="\t")
write.table(res2$P, "stool_p.txt", sep="\t")
library(gdata)
sigp <- unmatrix(res2$P)
sigr <- unmatrix(res2$r)
comb <- cbind(sigp, sigr)
sig <- subset(comb, sigr>0.4)
sig2 <- sig[complete.cases(sig), ]
write.table(sig2, "stool_correlation_table_signifcant.txt", sep="\t")
write.table(tax_table(ps_stool_rare2), "ps_stool_rare2_taxa.txt", sep="\t")
write.table(tax_table(ps_stool_common), "ps_stool_common_taxa.txt", sep="\t")

res2 <- rcorr(as.matrix(t(otu_table(ps_urine))))
write.table(res2$r, "urine_r.txt", sep="\t")
write.table(res2$P, "urine_p.txt", sep="\t")
library(gdata)
sigp <- unmatrix(res2$P)
sigr <- unmatrix(res2$r)
comb <- cbind(sigp, sigr)
sig <- subset(comb, sigr>0.4)
sig2 <- sig[complete.cases(sig), ]
write.table(sig2, "urine_correlation_table_signifcant.txt", sep="\t")
write.table(tax_table(ps_urine_rare2), "ps_urine_rare2_taxa.txt", sep="\t")
write.table(tax_table(ps_urine_common), "ps_urine_common_taxa.txt", sep="\t")

##Phylum/genus profiles
##Diff abun by health

ps_stool_common
ps_urine_common
ps_stone_common
ps_urine
ps_stool
ps_stone
ps_stool_rare2
ps_stone_rare2
ps_urine_rare2

##Phylum/genus profiles
#########Genus level

library(RColorBrewer)
getPalette = colorRampPalette(brewer.pal(9, "Set1"))
ps.rel = transform_sample_counts(ps_stool_common, function(x) x/sum(x)*100)
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Genus <- as.character(ps.melt$Genus)


ps.melt <- ps.melt %>%
  group_by(Sample_type, Genus) %>%
  mutate(median=median(Abundance))
# select tissue mean > 1
keep <- unique(ps.melt$Genus[ps.melt$Abundance > 5])
ps.melt$Genus[!(ps.melt$Genus %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Genus))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,tissue,Genus) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Genus, color = Genus)) + 
  geom_bar(stat = "identity", aes(fill=Genus), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("genus_profile_stool_common.pdf", type="pdf")


        
############Phylum level
        
ps.rel = transform_sample_counts(ps_stool_common, function(x) x/sum(x)*100)
# agglomerate taxa
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Phylum <- as.character(ps.melt$Phylum)
colourCount = length(unique(ps.melt$Phylum))

ps.melt <- ps.melt %>%
  group_by(Sample_type, Phylum) %>%
  mutate(median=median(Abundance))
# select Sample_type mean > 1
keep <- unique(ps.melt$Phylum[ps.melt$Abundance > 1])
ps.melt$Phylum[!(ps.melt$Phylum %in% keep)] <- "Other"
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,Sample_type,Phylum) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Phylum, color = Phylum)) + 
  geom_bar(stat = "identity", aes(fill=Phylum), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("phylum_profile_stool_common.pdf", type="pdf")   

#########Genus level

ps.rel = transform_sample_counts(ps_stool_rare2, function(x) x/sum(x)*100)
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Genus <- as.character(ps.melt$Genus)


ps.melt <- ps.melt %>%
  group_by(Sample_type, Genus) %>%
  mutate(median=median(Abundance))
# select tissue mean > 1
keep <- unique(ps.melt$Genus[ps.melt$Abundance > 7])
ps.melt$Genus[!(ps.melt$Genus %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Genus))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,tissue,Genus) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Genus, color = Genus)) + 
  geom_bar(stat = "identity", aes(fill=Genus), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("genus_profile_stool_rare2.pdf", type="pdf")


        
############Phylum level
        
ps.rel = transform_sample_counts(ps_stool_rare2, function(x) x/sum(x)*100)
# agglomerate taxa
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Phylum <- as.character(ps.melt$Phylum)

ps.melt <- ps.melt %>%
  group_by(Sample_type, Phylum) %>%
  mutate(median=median(Abundance))
# select Sample_type mean > 1
keep <- unique(ps.melt$Phylum[ps.melt$Abundance > 1])
ps.melt$Phylum[!(ps.melt$Phylum %in% keep)] <- "Other"
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,Sample_type,Phylum) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Phylum, color = Phylum)) + 
  geom_bar(stat = "identity", aes(fill=Phylum), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent)
quartz.save("phylum_profile_stool_rare2.pdf", type="pdf")   

#########Genus level

library(RColorBrewer)
getPalette = colorRampPalette(brewer.pal(9, "Set1"))
ps.rel = transform_sample_counts(ps_stone_common, function(x) x/sum(x)*100)
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Genus <- as.character(ps.melt$Genus)


ps.melt <- ps.melt %>%
  group_by(Sample_type, Genus) %>%
  mutate(median=median(Abundance))
# select tissue mean > 1
keep <- unique(ps.melt$Genus[ps.melt$Abundance > 5])
ps.melt$Genus[!(ps.melt$Genus %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Genus))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,tissue,Genus) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Genus, color = Genus)) + 
  geom_bar(stat = "identity", aes(fill=Genus), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("genus_profile_stone_common.pdf", type="pdf")


        
############Phylum level
        
ps.rel = transform_sample_counts(ps_stone_common, function(x) x/sum(x)*100)
# agglomerate taxa
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Phylum <- as.character(ps.melt$Phylum)
colourCount = length(unique(ps.melt$Phylum))

ps.melt <- ps.melt %>%
  group_by(Sample_type, Phylum) %>%
  mutate(median=median(Abundance))
# select Sample_type mean > 1
keep <- unique(ps.melt$Phylum[ps.melt$Abundance > 1])
ps.melt$Phylum[!(ps.melt$Phylum %in% keep)] <- "Other"
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,Sample_type,Phylum) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Phylum, color = Phylum)) + 
  geom_bar(stat = "identity", aes(fill=Phylum), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("phylum_profile_stone_common.pdf", type="pdf")   

#########Genus level

ps.rel = transform_sample_counts(ps_stone_rare2, function(x) x/sum(x)*100)
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Genus <- as.character(ps.melt$Genus)


ps.melt <- ps.melt %>%
  group_by(Sample_type, Genus) %>%
  mutate(median=median(Abundance))
# select tissue mean > 1
keep <- unique(ps.melt$Genus[ps.melt$Abundance > 10])
ps.melt$Genus[!(ps.melt$Genus %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Genus))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,tissue,Genus) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Genus, color = Genus)) + 
  geom_bar(stat = "identity", aes(fill=Genus), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("genus_profile_stone_rare2.pdf", type="pdf")


        
############Phylum level
        
ps.rel = transform_sample_counts(ps_stone_rare2, function(x) x/sum(x)*100)
# agglomerate taxa
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Phylum <- as.character(ps.melt$Phylum)
colourCount = length(unique(ps.melt$Phylum))


ps.melt <- ps.melt %>%
  group_by(Sample_type, Phylum) %>%
  mutate(median=median(Abundance))
# select Sample_type mean > 1
keep <- unique(ps.melt$Phylum[ps.melt$Abundance > 1])
ps.melt$Phylum[!(ps.melt$Phylum %in% keep)] <- "Other"
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,Sample_type,Phylum) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Phylum, color = Phylum)) + 
  geom_bar(stat = "identity", aes(fill=Phylum), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent)  + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("phylum_profile_stone_rare2.pdf", type="pdf")

#########Genus level

library(RColorBrewer)
getPalette = colorRampPalette(brewer.pal(9, "Set1"))
ps.rel = transform_sample_counts(ps_urine_common, function(x) x/sum(x)*100)
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Genus <- as.character(ps.melt$Genus)


ps.melt <- ps.melt %>%
  group_by(Sample_type, Genus) %>%
  mutate(median=median(Abundance))
# select tissue mean > 1
keep <- unique(ps.melt$Genus[ps.melt$Abundance > 5])
ps.melt$Genus[!(ps.melt$Genus %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Genus))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,tissue,Genus) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Genus, color = Genus)) + 
  geom_bar(stat = "identity", aes(fill=Genus), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("genus_profile_urine_common.pdf", type="pdf")


        
############Phylum level
        
ps.rel = transform_sample_counts(ps_urine_common, function(x) x/sum(x)*100)
# agglomerate taxa
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Phylum <- as.character(ps.melt$Phylum)
colourCount = length(unique(ps.melt$Phylum))

ps.melt <- ps.melt %>%
  group_by(Sample_type, Phylum) %>%
  mutate(median=median(Abundance))
# select Sample_type mean > 1
keep <- unique(ps.melt$Phylum[ps.melt$Abundance > 1])
ps.melt$Phylum[!(ps.melt$Phylum %in% keep)] <- "Other"
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,Sample_type,Phylum) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Phylum, color = Phylum)) + 
  geom_bar(stat = "identity", aes(fill=Phylum), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("phylum_profile_urine_common.pdf", type="pdf")   

#########Genus level

ps.rel = transform_sample_counts(ps_urine_rare2, function(x) x/sum(x)*100)
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Genus <- as.character(ps.melt$Genus)


ps.melt <- ps.melt %>%
  group_by(Sample_type, Genus) %>%
  mutate(median=median(Abundance))
# select tissue mean > 1
keep <- unique(ps.melt$Genus[ps.melt$Abundance > 22])
ps.melt$Genus[!(ps.melt$Genus %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Genus))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,tissue,Genus) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Genus, color = Genus)) + 
  geom_bar(stat = "identity", aes(fill=Genus), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("genus_profile_urine_rare2.pdf", type="pdf")


        
############Phylum level
        
ps.rel = transform_sample_counts(ps_urine_rare2, function(x) x/sum(x)*100)
# agglomerate taxa
ps.melt <- psmelt(ps.rel)
# change to character for easy-adjusted level
ps.melt$Phylum <- as.character(ps.melt$Phylum)
colourCount = length(unique(ps.melt$Phylum))

ps.melt <- ps.melt %>%
  group_by(Sample_type, Phylum) %>%
  mutate(median=median(Abundance))
# select Sample_type mean > 1
keep <- unique(ps.melt$Phylum[ps.melt$Abundance > 1])
ps.melt$Phylum[!(ps.melt$Phylum %in% keep)] <- "Other"
colourCount = length(unique(ps.melt$Phylum))
#to get the same rows together
ps.melt_sum <- ps.melt %>%
  group_by(Sample,Sample_type,Phylum) %>%
  summarise(Abundance=sum(Abundance))

ggplot(ps.melt, aes(x = Sample_type, y = Abundance, fill = Phylum, color = Phylum)) + 
  geom_bar(stat = "identity", aes(fill=Phylum), position="fill") + 
  labs(x="Sample_type", y="Relative abundance") +
  theme_classic() + 
  theme(legend.position = "right", 
        strip.background = element_blank(), 
        axis.text.x.bottom = element_text(angle = -90)) + theme(text = element_text(size=15)) + scale_y_continuous(labels = scales::percent) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
quartz.save("phylum_profile_urine_rare2.pdf", type="pdf")

##Diff abun by health v usd, rare & common, stool & urine
ps_stool_common
ps_urine_common
ps_stone_common
ps_urine
ps_stool
ps_stone
ps_stool_rare2
ps_stone_rare2
ps_urine_rare2


otu_table(ps_stool_common)[otu_table(ps_stool_common) >= 0.0] <- otu_table(ps_stool_common) + 1
diagdds = phyloseq_to_deseq2(ps_stool_common, ~ Group)
dds_res <- DESeq(diagdds)
results_dds <- results(dds_res)
results_dds
full <- cbind(results_dds, tax_table(ps_stool_common))
write.table(full, file="diff_abun_ps_stool_common_Group.txt", sep = "\t")

##In Terminal, make sure you are in the same directory as the results.  Look at the *forheatmap*4.txt files (2 of them).  If there are "NA" taxa, you will need to go back into the *signif.txt file created in the first line, sort by genus, family, order, class, then copy/paste the lowest assigned taxonomy into the genus column, then rerun all except the first line.

awk '{ if ($7 < 0.05) { print }}' diff_abun_ps_stool_common_Group.txt > diff_abun_ps_stool_common_Group_signif.txt
awk '{ if ($3 < 0) { print }}' diff_abun_ps_stool_common_Group_signif.txt > diff_abun_ps_stool_common_Group_signif_Cont.txt 
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_stool_common_Group_signif_Cont.txt > diff_abun_ps_stool_common_Group_signif_Cont2.txt
mv diff_abun_ps_stool_common_Group_signif_Cont2.txt diff_abun_ps_stool_common_Group_signif_Cont.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_stool_common_Group_signif_Cont.txt > diff_abun_ps_stool_common_Group_signif_Cont_genus.txt
sed 's/\[//g' diff_abun_ps_stool_common_Group_signif_Cont_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_stool_common_Group_signif_Cont_genus_formatted.txt
awk 'BEGIN{print "Cont Taxa"}; {print}' diff_abun_ps_stool_common_Group_signif_Cont_genus_formatted.txt > diff_abun_ps_stool_common_Group_forheatmap_Cont.txt
awk '{$1=$1};1' diff_abun_ps_stool_common_Group_forheatmap_Cont.txt > diff_abun_ps_stool_common_Group_forheatmap_Cont2.txt
tr ' ' \\t < diff_abun_ps_stool_common_Group_forheatmap_Cont2.txt > diff_abun_ps_stool_common_Group_forheatmap_Cont3.txt
diff_abun_ps_stool_common_Group_forheatmap_Cont.txt diff_abun_ps_stool_common_Group_forheatmap_Cont2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_stool_common_Group_forheatmap_Cont3.txt | awk '!/Bacteria/' > diff_abun_ps_stool_common_Group_forheatmap_Cont4.txt
awk '{ if ($3 > 0) { print }}' diff_abun_ps_stool_common_Group_signif.txt > diff_abun_ps_stool_common_Group_signif_USD.txt
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_stool_common_Group_signif_USD.txt > diff_abun_ps_stool_common_Group_signif_USD2.txt
mv diff_abun_ps_stool_common_Group_signif_USD2.txt diff_abun_ps_stool_common_Group_signif_USD.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_stool_common_Group_signif_USD.txt > diff_abun_ps_stool_common_Group_signif_USD_genus.txt
sed 's/\[//g' diff_abun_ps_stool_common_Group_signif_USD_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_stool_common_Group_signif_USD_genus_formatted.txt
awk 'BEGIN{print "USD Taxa"}; {print}' diff_abun_ps_stool_common_Group_signif_USD_genus_formatted.txt > diff_abun_ps_stool_common_Group_forheatmap_USD.txt
awk '{$1=$1};1' diff_abun_ps_stool_common_Group_forheatmap_USD.txt > diff_abun_ps_stool_common_Group_forheatmap_USD2.txt
tr ' ' \\t < diff_abun_ps_stool_common_Group_forheatmap_USD2.txt > diff_abun_ps_stool_common_Group_forheatmap_USD3.txt
diff_abun_ps_stool_common_Group_forheatmap_USD.txt > diff_abun_ps_stool_common_Group_forheatmap_USD2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_stool_common_Group_forheatmap_USD3.txt | awk '!/Bacteria/' > diff_abun_ps_stool_common_Group_forheatmap_USD4.txt


###In excel - open both *4.txt files.  Change the Value name to "Count", then create a new column with your variable name.  For each file, but the correct value name in the new variable column.  Then, copy and paste all of the data from one of the files into the other.  You will use this file in R to create the charts.


####Back in R - use the merged results file you created in excel


library(ggplot2)
library(dplyr)
args = commandArgs(trailingOnly=TRUE)
data <- read.table("diff_abun_ps_stool_common_Group_forheatmap_Cont4.txt", header=TRUE)
data$Taxonomy <- factor(data$Taxa, levels = data$Taxa)
colourCount = length(unique(data$Taxonomy))
pdf(file="diff_abun_stool_common_USD.pdf", width=15, height=20)
ggplot(data, aes(fill=Taxa, y=Count, x=Group)) + 
    geom_bar(position="stack", stat="identity") + ggtitle("Bacteria enriched by USD Status") + theme(legend.text=element_text(size=22)) + theme(text = element_text(size = 22)) + ylab("No. of ASV's/Taxon") + guides(fill = guide_legend(ncol = 2)) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
dev.off()

otu_table(ps_stool_rare2)[otu_table(ps_stool_rare2) >= 0.0] <- otu_table(ps_stool_rare2) + 1
diagdds = phyloseq_to_deseq2(ps_stool_rare2, ~ Group)
dds_res <- DESeq(diagdds)
results_dds <- results(dds_res)
results_dds
full <- cbind(results_dds, tax_table(ps_stool_rare2))
write.table(full, file="diff_abun_ps_stool_rare2_Group.txt", sep = "\t")

##In Terminal, make sure you are in the same directory as the results.  Look at the *forheatmap*4.txt files (2 of them).  If there are "NA" taxa, you will need to go back into the *signif.txt file created in the first line, sort by genus, family, order, class, then copy/paste the lowest assigned taxonomy into the genus column, then rerun all except the first line.

awk '{ if ($7 < 0.05) { print }}' diff_abun_ps_stool_rare2_Group.txt > diff_abun_ps_stool_rare2_Group_signif.txt
awk '{ if ($3 < 0) { print }}' diff_abun_ps_stool_rare2_Group_signif.txt > diff_abun_ps_stool_rare2_Group_signif_Cont.txt 
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_stool_rare2_Group_signif_Cont.txt > diff_abun_ps_stool_rare2_Group_signif_Cont2.txt
mv diff_abun_ps_stool_rare2_Group_signif_Cont2.txt diff_abun_ps_stool_rare2_Group_signif_Cont.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_stool_rare2_Group_signif_Cont.txt > diff_abun_ps_stool_rare2_Group_signif_Cont_genus.txt
sed 's/\[//g' diff_abun_ps_stool_rare2_Group_signif_Cont_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_stool_rare2_Group_signif_Cont_genus_formatted.txt
awk 'BEGIN{print "Cont Taxa"}; {print}' diff_abun_ps_stool_rare2_Group_signif_Cont_genus_formatted.txt > diff_abun_ps_stool_rare2_Group_forheatmap_Cont.txt
awk '{$1=$1};1' diff_abun_ps_stool_rare2_Group_forheatmap_Cont.txt > diff_abun_ps_stool_rare2_Group_forheatmap_Cont2.txt
tr ' ' \\t < diff_abun_ps_stool_rare2_Group_forheatmap_Cont2.txt > diff_abun_ps_stool_rare2_Group_forheatmap_Cont3.txt
diff_abun_ps_stool_rare2_Group_forheatmap_Cont.txt diff_abun_ps_stool_rare2_Group_forheatmap_Cont2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_stool_rare2_Group_forheatmap_Cont3.txt | awk '!/Bacteria/' > diff_abun_ps_stool_rare2_Group_forheatmap_Cont4.txt
awk '{ if ($3 > 0) { print }}' diff_abun_ps_stool_rare2_Group_signif.txt > diff_abun_ps_stool_rare2_Group_signif_USD.txt
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_stool_rare2_Group_signif_USD.txt > diff_abun_ps_stool_rare2_Group_signif_USD2.txt
mv diff_abun_ps_stool_rare2_Group_signif_USD2.txt diff_abun_ps_stool_rare2_Group_signif_USD.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_stool_rare2_Group_signif_USD.txt > diff_abun_ps_stool_rare2_Group_signif_USD_genus.txt
sed 's/\[//g' diff_abun_ps_stool_rare2_Group_signif_USD_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_stool_rare2_Group_signif_USD_genus_formatted.txt
awk 'BEGIN{print "USD Taxa"}; {print}' diff_abun_ps_stool_rare2_Group_signif_USD_genus_formatted.txt > diff_abun_ps_stool_rare2_Group_forheatmap_USD.txt
awk '{$1=$1};1' diff_abun_ps_stool_rare2_Group_forheatmap_USD.txt > diff_abun_ps_stool_rare2_Group_forheatmap_USD2.txt
tr ' ' \\t < diff_abun_ps_stool_rare2_Group_forheatmap_USD2.txt > diff_abun_ps_stool_rare2_Group_forheatmap_USD3.txt
diff_abun_ps_stool_rare2_Group_forheatmap_USD.txt > diff_abun_ps_stool_rare2_Group_forheatmap_USD2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_stool_rare2_Group_forheatmap_USD3.txt | awk '!/Bacteria/' > diff_abun_ps_stool_rare2_Group_forheatmap_USD4.txt


###In excel - open both *4.txt files.  Change the Value name to "Count", then create a new column with your variable name.  For each file, but the correct value name in the new variable column.  Then, copy and paste all of the data from one of the files into the other.  You will use this file in R to create the charts.


####Back in R - use the merged results file you created in excel


library(ggplot2)
library(dplyr)
args = commandArgs(trailingOnly=TRUE)
data <- read.table("diff_abun_ps_stool_rare2_Group_forheatmap_Cont4.txt", header=TRUE)
data$Taxonomy <- factor(data$Taxa, levels = data$Taxa)
colourCount = length(unique(data$Taxonomy))
pdf(file="diff_abun_stool_rare2_USD.pdf", width=15, height=20)
ggplot(data, aes(fill=Taxa, y=Count, x=Group)) + 
    geom_bar(position="stack", stat="identity") + ggtitle("Bacteria enriched by USD Status") + theme(legend.text=element_text(size=22)) + theme(text = element_text(size = 22)) + ylab("No. of ASV's/Taxon") + guides(fill = guide_legend(ncol = 2)) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
dev.off()

otu_table(ps_urine_common)[otu_table(ps_urine_common) >= 0.0] <- otu_table(ps_urine_common) + 1
diagdds = phyloseq_to_deseq2(ps_urine_common, ~ Group)
dds_res <- DESeq(diagdds)
results_dds <- results(dds_res)
results_dds
full <- cbind(results_dds, tax_table(ps_urine_common))
write.table(full, file="diff_abun_ps_urine_common_Group.txt", sep = "\t")

##In Terminal, make sure you are in the same directory as the results.  Look at the *forheatmap*4.txt files (2 of them).  If there are "NA" taxa, you will need to go back into the *signif.txt file created in the first line, sort by genus, family, order, class, then copy/paste the lowest assigned taxonomy into the genus column, then rerun all except the first line.

awk '{ if ($7 < 0.05) { print }}' diff_abun_ps_urine_common_Group.txt > diff_abun_ps_urine_common_Group_signif.txt
awk '{ if ($3 < 0) { print }}' diff_abun_ps_urine_common_Group_signif.txt > diff_abun_ps_urine_common_Group_signif_Cont.txt 
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_urine_common_Group_signif_Cont.txt > diff_abun_ps_urine_common_Group_signif_Cont2.txt
mv diff_abun_ps_urine_common_Group_signif_Cont2.txt diff_abun_ps_urine_common_Group_signif_Cont.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_urine_common_Group_signif_Cont.txt > diff_abun_ps_urine_common_Group_signif_Cont_genus.txt
sed 's/\[//g' diff_abun_ps_urine_common_Group_signif_Cont_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_urine_common_Group_signif_Cont_genus_formatted.txt
awk 'BEGIN{print "Cont Taxa"}; {print}' diff_abun_ps_urine_common_Group_signif_Cont_genus_formatted.txt > diff_abun_ps_urine_common_Group_forheatmap_Cont.txt
awk '{$1=$1};1' diff_abun_ps_urine_common_Group_forheatmap_Cont.txt > diff_abun_ps_urine_common_Group_forheatmap_Cont2.txt
tr ' ' \\t < diff_abun_ps_urine_common_Group_forheatmap_Cont2.txt > diff_abun_ps_urine_common_Group_forheatmap_Cont3.txt
diff_abun_ps_urine_common_Group_forheatmap_Cont.txt diff_abun_ps_urine_common_Group_forheatmap_Cont2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_urine_common_Group_forheatmap_Cont3.txt | awk '!/Bacteria/' > diff_abun_ps_urine_common_Group_forheatmap_Cont4.txt
awk '{ if ($3 > 0) { print }}' diff_abun_ps_urine_common_Group_signif.txt > diff_abun_ps_urine_common_Group_signif_USD.txt
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_urine_common_Group_signif_USD.txt > diff_abun_ps_urine_common_Group_signif_USD2.txt
mv diff_abun_ps_urine_common_Group_signif_USD2.txt diff_abun_ps_urine_common_Group_signif_USD.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_urine_common_Group_signif_USD.txt > diff_abun_ps_urine_common_Group_signif_USD_genus.txt
sed 's/\[//g' diff_abun_ps_urine_common_Group_signif_USD_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_urine_common_Group_signif_USD_genus_formatted.txt
awk 'BEGIN{print "USD Taxa"}; {print}' diff_abun_ps_urine_common_Group_signif_USD_genus_formatted.txt > diff_abun_ps_urine_common_Group_forheatmap_USD.txt
awk '{$1=$1};1' diff_abun_ps_urine_common_Group_forheatmap_USD.txt > diff_abun_ps_urine_common_Group_forheatmap_USD2.txt
tr ' ' \\t < diff_abun_ps_urine_common_Group_forheatmap_USD2.txt > diff_abun_ps_urine_common_Group_forheatmap_USD3.txt
diff_abun_ps_urine_common_Group_forheatmap_USD.txt > diff_abun_ps_urine_common_Group_forheatmap_USD2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_urine_common_Group_forheatmap_USD3.txt | awk '!/Bacteria/' > diff_abun_ps_urine_common_Group_forheatmap_USD4.txt


###In excel - open both *4.txt files.  Change the Value name to "Count", then create a new column with your variable name.  For each file, but the correct value name in the new variable column.  Then, copy and paste all of the data from one of the files into the other.  You will use this file in R to create the charts.


####Back in R - use the merged results file you created in excel


library(ggplot2)
library(dplyr)
args = commandArgs(trailingOnly=TRUE)
data <- read.table("diff_abun_ps_urine_common_Group_forheatmap_Cont4.txt", header=TRUE)
data$Taxonomy <- factor(data$Taxa, levels = data$Taxa)
colourCount = length(unique(data$Taxonomy))
pdf(file="diff_abun_urine_common_USD.pdf", width=15, height=20)
ggplot(data, aes(fill=Taxa, y=Count, x=Group)) + 
    geom_bar(position="stack", stat="identity") + ggtitle("Bacteria enriched by USD Status") + theme(legend.text=element_text(size=18)) + theme(text = element_text(size = 18)) + ylab("No. of ASV's/Taxon") + guides(fill = guide_legend(ncol = 2)) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
dev.off()

otu_table(ps_urine_rare2)[otu_table(ps_urine_rare2) >= 0.0] <- otu_table(ps_urine_rare2) + 1
diagdds = phyloseq_to_deseq2(ps_urine_rare2, ~ Group)
dds_res <- DESeq(diagdds)
results_dds <- results(dds_res)
results_dds
full <- cbind(results_dds, tax_table(ps_urine_rare2))
write.table(full, file="diff_abun_ps_urine_rare2_Group.txt", sep = "\t")

##In Terminal, make sure you are in the same directory as the results.  Look at the *forheatmap*4.txt files (2 of them).  If there are "NA" taxa, you will need to go back into the *signif.txt file created in the first line, sort by genus, family, order, class, then copy/paste the lowest assigned taxonomy into the genus column, then rerun all except the first line.

awk '{ if ($7 < 0.05) { print }}' diff_abun_ps_urine_rare2_Group.txt > diff_abun_ps_urine_rare2_Group_signif.txt
awk '{ if ($3 < 0) { print }}' diff_abun_ps_urine_rare2_Group_signif.txt > diff_abun_ps_urine_rare2_Group_signif_Cont.txt 
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_urine_rare2_Group_signif_Cont.txt > diff_abun_ps_urine_rare2_Group_signif_Cont2.txt
mv diff_abun_ps_urine_rare2_Group_signif_Cont2.txt diff_abun_ps_urine_rare2_Group_signif_Cont.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_urine_rare2_Group_signif_Cont.txt > diff_abun_ps_urine_rare2_Group_signif_Cont_genus.txt
sed 's/\[//g' diff_abun_ps_urine_rare2_Group_signif_Cont_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_urine_rare2_Group_signif_Cont_genus_formatted.txt
awk 'BEGIN{print "Cont Taxa"}; {print}' diff_abun_ps_urine_rare2_Group_signif_Cont_genus_formatted.txt > diff_abun_ps_urine_rare2_Group_forheatmap_Cont.txt
awk '{$1=$1};1' diff_abun_ps_urine_rare2_Group_forheatmap_Cont.txt > diff_abun_ps_urine_rare2_Group_forheatmap_Cont2.txt
tr ' ' \\t < diff_abun_ps_urine_rare2_Group_forheatmap_Cont2.txt > diff_abun_ps_urine_rare2_Group_forheatmap_Cont3.txt
diff_abun_ps_urine_rare2_Group_forheatmap_Cont.txt diff_abun_ps_urine_rare2_Group_forheatmap_Cont2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_urine_rare2_Group_forheatmap_Cont3.txt | awk '!/Bacteria/' > diff_abun_ps_urine_rare2_Group_forheatmap_Cont4.txt
awk '{ if ($3 > 0) { print }}' diff_abun_ps_urine_rare2_Group_signif.txt > diff_abun_ps_urine_rare2_Group_signif_USD.txt
awk -v OFS='\t' 'NF{NF-=1};1' diff_abun_ps_urine_rare2_Group_signif_USD.txt > diff_abun_ps_urine_rare2_Group_signif_USD2.txt
mv diff_abun_ps_urine_rare2_Group_signif_USD2.txt diff_abun_ps_urine_rare2_Group_signif_USD.txt
awk -v OFS='\t' '{print $NF}' diff_abun_ps_urine_rare2_Group_signif_USD.txt > diff_abun_ps_urine_rare2_Group_signif_USD_genus.txt
sed 's/\[//g' diff_abun_ps_urine_rare2_Group_signif_USD_genus.txt | sed 's/\]//g' | sort | uniq -c > diff_abun_ps_urine_rare2_Group_signif_USD_genus_formatted.txt
awk 'BEGIN{print "USD Taxa"}; {print}' diff_abun_ps_urine_rare2_Group_signif_USD_genus_formatted.txt > diff_abun_ps_urine_rare2_Group_forheatmap_USD.txt
awk '{$1=$1};1' diff_abun_ps_urine_rare2_Group_forheatmap_USD.txt > diff_abun_ps_urine_rare2_Group_forheatmap_USD2.txt
tr ' ' \\t < diff_abun_ps_urine_rare2_Group_forheatmap_USD2.txt > diff_abun_ps_urine_rare2_Group_forheatmap_USD3.txt
diff_abun_ps_urine_rare2_Group_forheatmap_USD.txt > diff_abun_ps_urine_rare2_Group_forheatmap_USD2.txt
awk -F '\t' 'BEGIN {OFS = FS} {print $2,$1}' diff_abun_ps_urine_rare2_Group_forheatmap_USD3.txt | awk '!/Bacteria/' > diff_abun_ps_urine_rare2_Group_forheatmap_USD4.txt


###In excel - open both *4.txt files.  Change the Value name to "Count", then create a new column with your variable name.  For each file, but the correct value name in the new variable column.  Then, copy and paste all of the data from one of the files into the other.  You will use this file in R to create the charts.


####Back in R - use the merged results file you created in excel


library(ggplot2)
library(dplyr)
args = commandArgs(trailingOnly=TRUE)
data <- read.table("diff_abun_ps_urine_rare2_Group_forheatmap_Cont4.txt", header=TRUE)
data$Taxonomy <- factor(data$Taxa, levels = data$Taxa)
colourCount = length(unique(data$Taxonomy))
pdf(file="diff_abun_urine_rare2_USD.pdf", width=15, height=20)
ggplot(data, aes(fill=Taxa, y=Count, x=Group)) + 
    geom_bar(position="stack", stat="identity") + ggtitle("Bacteria enriched by USD Status") + theme(legend.text=element_text(size=22)) + theme(text = element_text(size = 22)) + ylab("No. of ASV's/Taxon") + guides(fill = guide_legend(ncol = 2)) + scale_fill_manual(values = getPalette(colourCount)) + scale_color_manual(values = getPalette(colourCount))  +  theme(legend.text = element_text(face = c(rep("italic", 5), rep("plain", 5))))
dev.off()