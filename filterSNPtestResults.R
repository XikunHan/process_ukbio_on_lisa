#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

resultPrefix <- args[1]
infoThresh <- args[2]
mafThresh <- args[3]


if(is.na(as.numeric(mafThresh))){
	mafThresh <- 0.01
}

if(is.na(as.numeric(infoThresh))){
	infoThresh <- 0.8
}

resultFile <- paste0(resultPrefix,".snptestresult")
filteredFile <- paste0(resultPrefix,"_info",infoThresh,"_maf",mafThresh,".snptestresult")
message("Load result file...")
result <- fread(resultFile,
          skip="#",
          colClasses=list(character=c("comment")),
          data.table=T)
message("Filter snps...")
result <- subset(result,info>infoThresh & all_maf > mafThresh & frequentist_add_pvalue >=0 & frequentist_add_pvalue <=1 )
message("Write filtered snps to ",filteredFile,"...")
write.table(result,file=filteredFile,row.names=F,quote=F,sep=" ")
message("Done")



