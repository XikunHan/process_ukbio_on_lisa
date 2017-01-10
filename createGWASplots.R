#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))


gwasResultFile <- args[1]
outputPrefix <- args[2]

if(!file.exists(gwasResultFile)){
message("ERROR: GWAS result file does not exist: ",gwasResultFile)
quit("no",-1)
}

df <- fread(gwasResultFile)
width <- 30
height <- 15
res <- 300
pvalueLabel <- names(df)[grepl('_pvalue$', names(df))]
stopifnot(length(pvalueLabel)==1)

cond <- as.logical(df[,pvalueLabel,with=F][[1]]>0)

message("Total nr of lines: ",length(cond))
message("Total nr of positive p-values: ", sum(cond))

message("Save manhattan plot...")
png(paste0(outputPrefix,"_mahattan.png"),width=width,height=height,units="cm",res=res)
manhattan(df[cond,],chr="chromosome", bp="position", p=pvalueLabel, snp="rsid")
dev.off()

message("Save qqplot...")
png(paste0(outputPrefix,"_qqplot.png"),width=width,height=height,units="cm",res=res)
qq(as.numeric(df[,pvalueLabel,with=F][[1]]))
dev.off()
