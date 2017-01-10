#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

####
#This script runs a plink on binary plink chunks.
# 
# Usage on loginnode for testing: ./runPlinkOnChunk.R ANALYSIS_FILE PHENOTYPE_FILE PLINK_CHUNK_PREFIX OUTPUT_DIR
####

#Any chunk analysis script (like this one) must conform to the following guidelines:
# 1) It must be able to run as:
#   Rscript ${SCRIPT_DIR}/${SCRIPT_NAME} ${ANALYSIS_FILE} ${PLINK_FILE} ${OUTPUT_DIR}
#   where SCRIPT_DIR is the directory where all ukbio chunk analysis scripts are stored
#   SCRIPT_NAME is the file name of the analysis
#   ANALYSIS_FILE is a file with analysis options understood by SCRIPT_NAME with on the first line the name of the script
#   PLINK_FILE is a binary plink file prefix
#   OUTPUT_DIR is the output directory to save the analysis output to

scriptFileName <- "runPlinkOnChunk.R"

#Test ARGS
option_list <- list(
  make_option(c("-a", "--analysisfile"),help="Analysis file for runMatrixEQTLOnChunk.R"),
  make_option(c("-c", "--chunkprefix"),help="Plink chunk file prefix"),
  make_option(c("-o", "--outputdir"),help="Output directory")
)

#TEST ARGS
#args <- c("-a","perm_analysis.txt","-c","./chunk_test","-o",".")
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


#Set output file name
outputFile <- file.path(outputDir,basename(plinkFile))

message("Output file: ",outputFile)

message("Process additional options...")
plinkOptions <- concatenateProgramOptions(unaryOptions,binaryOptions,optionPrefix="--")

#Run plink
if(!file.exists(paste0(plinkFile,".bed"))){
cmd <- paste0("gunzip ",plinkFile,".bed.gz")
message(cmd)
system(cmd)
}

cmd <- paste0("source scriptSettings.sh; plink --memory 1000 --bfile ",plinkFile," --out ",outputFile," ",plinkOptions)
message("Runnning the following plink command:")
message(cmd)
system(cmd)
