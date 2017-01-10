#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

#Script parameters
#First parameter: .bgen chunk directory
#Second paramter: stopos parameter file
chunkDir <- args[1]
stoposFile <- args[2]

#TEST args
#chunkDir <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/genotypes/bgen_testchunks"
#stoposFile <- "chunk_names_test.stopos"
message(paste0("chunk directory: ", chunkDir))
message(paste0("output stopos parameter file: ", stoposFile))

# .bgen file prefixes 
files <- Sys.glob(file.path(chunkDir,"*.bgen"))
SNPsInSubset <- unlist(sapply(strsplit(files,".",fixed=T),function(prefix) file.exists(paste0(prefix[1],".snpstats"))))
#Only chunks with a .snpstats file (i.e. chunks that have remaining SNPs after filtering)
allChunks <- files[SNPsInSubset]
message("A total of ",length(allChunks)," chunks exist in chunk file")

stopifnot(length(allChunks)>0)

if(file.exists(stoposFile)){

#Check processed chunks
message("A stopos file exists. Checking nr of chunks that were already processed..")
stopifnot(file.exists(paste0(stoposFile,"_processedchunks")))

fileList <- Sys.glob(file.path(paste0(stoposFile,"_processedchunks"),"*"))

if(length(fileList>0)){
dataset <- NULL

for (file in fileList){
  # if the merged dataset doesn't exist, create it
  if (!exists("dataset")){
    dataset <- read.table(file, header=FALSE, quote="",sep="\t")
  }
  # if the merged dataset does exist, append to it
  if (exists("dataset")){
    temp_dataset <-read.table(file, header=FALSE, quote="", sep="\t")
    dataset<-rbind(dataset, temp_dataset)
    rm(temp_dataset)
  }
}
  processedChunks <- dataset[,1] 
}else{ #If no chunks were processed in process directory
  processedChunks <- c()
}

#TODO
# message("Checking nr of .snptestresult files..")
# stopifnot(file.exists(paste0(stoposFile,"_processedchunks")))
# 
# fileList <- Sys.glob(file.path(paste0(stoposFile,"_processedchunks"),"*"))
# 
# if(length(fileList>0)){
#   dataset <- NULL
#   
#   for (file in fileList){
#     # if the merged dataset doesn't exist, create it
#     if (!exists("dataset")){
#       dataset <- read.table(file, header=FALSE, quote="",sep="\t")
#     }
#     # if the merged dataset does exist, append to it
#     if (exists("dataset")){
#       temp_dataset <-read.table(file, header=FALSE, quote="", sep="\t")
#       dataset<-rbind(dataset, temp_dataset)
#       rm(temp_dataset)
#     }
#   }
#   processedChunks <- dataset[,1] 
# }else{ #If no chunks were processed in process directory
#   processedChunks <- c()
# }
# 
# 
# message("Number of .snptestresult files: ",length(chunkResults))
message("Number of processed chunks: ",length(processedChunks))
message("Number of chunks that need to be processed: ",length(processedChunks))
remainingChunks <- setdiff(allChunks, processedChunks)
stoposChunks <- remainingChunks



}else{ #If stoposFile does not exist
  stoposChunks <- allChunks
}

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
