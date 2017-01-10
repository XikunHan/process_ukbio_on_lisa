#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"functions_MatrixEQTL.R"))

####
#This script runs a MatrixEQTL-based permutation analysis on binary plink chunks.
# 
# Usage on loginnode for testing: ./runMatrixEQTLOnChunk.R ANALYSIS_FILE PLINK_CHUNK_PREFIX OUTPUT_DIR
####

#Any chunk analysis script (like this one) must conform to the following guidelines:
# 1) It must be able to run as:
#   Rscript ${SCRIPT_DIR}/${SCRIPT_NAME} ${ANALYSIS_FILE} ${PLINK_FILE} ${OUTPUT_DIR}
#   where SCRIPT_DIR is the directory where all ukbio chunk analysis scripts are stored
#   SCRIPT_NAME is the file name of the analysis
#   ANALYSIS_FILE is a file with analysis options understood by SCRIPT_NAME with on the first line the name of the script
#   PLINK_FILE is a binary plink file prefix
#   OUTPUT_DIR is the output directory to save the analysis output to

scriptFileName <- "runMatrixEQTLOnChunk.R"

#Test ARGS
option_list <- list(
  make_option(c("-a", "--analysisfile"),help="Analysis file for runMatrixEQTLOnChunk.R"),
  make_option(c("-c", "--chunkprefix"),help="Plink chunk file prefix"),
  make_option(c("-o", "--outputdir"),help="Output directory")
)

#TEST ARGS
#args <- c("-a","perm_analysis.txt","-c","/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/genotypes/plink_testchunks/chunk_1","-o",".")
opt <- parse_args(OptionParser(option_list=option_list),args)
stopifnot(!is.null(opt$analysisfile) & !is.null(opt$chunkprefix) & !is.null(opt$outputdir))
analysisFile <- opt$analysisfile
plinkFile <- opt$chunkprefix
outputDir <- opt$outputdir

message("Process analysis file: ",analysisFile)


#Parse options
options <- parseAnalysisFile(analysisFile,scriptFileName)

analysisName <- options$analysisName
unaryOptions <- options$unaryOptions
binaryOptions <- options$binaryOptions

stopifnot("phenoFile" %in% names(options$binaryOptions))
phenoFile <- options$binaryOptions["phenoFile"]
genoFile <- paste0(plinkFile,".traw")
meqtlGenoFile <- paste0(plinkFile,".meqtlgeno")
meqtlFile <- paste0(plinkFile,".meqtl")
outputFile <- file.path(outputDir,paste0(basename(plinkFile),".minpvals"))

#Set output file name
message("Output file: ",outputFile)

bedFile <- paste0(plinkFile,".bed")
if(!file.exists(bedFile)){
  stopifnot(file.exists(paste0(bedFile,".gz")))
  message("Unzip .bed.gz...")
  cmd <- paste0("gunzip ", bedFile, ".gz")
  system(cmd)
}

#Set output file name
message("Convert binary plink to MatrixEQTL files...")
nSubjects <- ncol(fread(phenoFile,nrows=1))-1
nPerm <- as.numeric(system(paste0("cat ",phenoFile," | wc -l"),intern=T))-1
convertBedToMqtl(plinkFile, meqtlGenoFile,nSubjects=nSubjects)

message("Run MatrixEQTL with ",nPerm, " permutations and ",nSubjects," subjects...")
runMatrixEqtl(meqtlGenoFile,phenoFile,meqtlFile)

message("Process MatrixEQTL output...")

processPermResults(plinkFile,meqtlFile,outputFile)
