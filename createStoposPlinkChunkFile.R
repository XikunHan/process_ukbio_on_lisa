#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

#Script parameters
#First parameter: plink chunk directory
#Second paramter: stopos parameter file
chunkDir <- args[1]
stoposFile <- args[2]

#Test parameters
#chunkDir <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/genotypes/plink_testchunks"
#stoposFile <- "test.stopos"

analysisDir <- dirname(stoposFile)

chunkType <- rev(strsplit(strsplit(basename(stoposFile),split=".stopos")[[1]],split="_")[[1]])[1]

resultDir<- file.path(analysisDir,paste0("results_",chunkType))

message(paste0("chunk directory: ", chunkDir))
message(paste0("output stopos parameter file: ", stoposFile))

# plink file prefixes 
chunkFiles <- Sys.glob(file.path(chunkDir,"chunk_*.bed.gz"))
allChunks <- unlist(sapply(strsplit(basename(chunkFiles),".",fixed=T),function(prefix) prefix[1]))
nrOfChunks <- length(allChunks)
message("A total of ",nrOfChunks," chunks exist in chunk file")

stopifnot(nrOfChunks>0)

if(file.exists(stoposFile)){

#Check processed chunks
message("A stopos file exists. Checking nr of chunks that were already processed..")
resultFiles <- Sys.glob(file.path(resultDir,"chunk_*"))
resultBasenames <- basename(resultFiles)
extensions <- sapply(strsplit(resultBasenames,split=".",fixed=T),function(x)rev(x)[1])
resultPrefixes <- sapply(strsplit(resultBasenames,split=".",fixed=T),function(x)x[1])

df <- data.table(file=resultFiles,prefix=resultPrefixes,extension=extensions)
df[, `:=`(ext_count=.N,error_count=as.numeric(NA),warning_count=as.numeric(NA)),by=extension]

logExt <- "log"
nrOfLogFiles <- nrow(df[extension==logExt,])
message("Plink produced .log files for ",nrOfLogFiles," chunks")

#Check for Errors and Warnings in plink log files
if(nrOfLogFiles>0){
  
df[extension==logExt, error_count:=as.numeric(sapply(file,function(f){
  cmd <- paste0("grep 'Error' ",f," | wc -l")
  system(cmd,intern=T)
  }))]
  
df[extension==logExt, warning_count:=as.numeric(sapply(file,function(f){
  cmd <- paste0("grep 'Warning' ",f," | wc -l")
  system(cmd,intern=T)
}))]


message("Nr of .log files with plink Errors: ",nrow(df[error_count>0,]))
message("Nr of .log files with plink Warnings: ",nrow(df[warning_count>0,]))

message("Number of result files per extension (.log, .gz, etc.)")
print(df[, .N,by=extension])

df[, success:= error_count[extension==logExt] == 0 & .N>1,by=prefix]

processedChunks <- df[extension==logExt & success == T,prefix]
}else{#no log files available, all chunks have failed
  message("No plink log files are available. All chunk plink analyses will be rerun.")
  processedChunks <- c()
}

}else{ #No stopos file, start fresh analysis
  message("No stopos file exists. All plink chunk analyses will be run.")
  processedChunks <- c()
}

message("Number of processed chunks: ",length(processedChunks))
message("Number of chunks that need to be processed: ",nrOfChunks-length(processedChunks))

stoposChunks <- file.path(chunkDir,setdiff(allChunks, processedChunks))
#write stopos values to file
if (length(stoposChunks)==0){
succeeded <-file.create(stoposFile)
if(!succeeded){
message("ERROR: could not create stopos file: ",stoposFile)
quit(save="no",status=-1)
}
}else{
write(sample(stoposChunks,length(stoposChunks)),file=stoposFile)
}
