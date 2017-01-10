#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

####
#This script converts a .bgen chunk into a binary plink chunk
# 
# Usage on loginnode for testing: ./convertChunkToPlinkFormat.R ANALYSIS_FILE SAMPLE_FILE BGEN_FILE OUTPUT_DIR
####

#Any chunk analysis script (like this one) must conform to the following guidelines:
# 1) It must be able to run as:
#   Rscript ${SCRIPT_DIR}/${SCRIPT_NAME} ${ANALYSIS_FILE} ${SAMPLE_FILE} ${BGEN_FILE} ${OUTPUT_DIR}
#   where SCRIPT_DIR is the directory where all ukbio chunk analysis scripts are stored
#   SCRIPT_NAME is the file name of the analysis
#   ANALYSIS_FILE is a file with analysis options understood by SCRIPT_NAME with on the first line the name of the script
#   SAMPLE_FILE is a sample file corresponding to a .bgen file
#   BGEN_FILE is a .bgen file
#   OUTPUT_DIR is the output directory to save the analysis output to

scriptFileName <- "convertChunkToPlinkFormat.R"

analysisFile <- args[1]
sampleFile <- args[2]
bgenFile <- args[3]
outputDir <- args[4]


#Test ARGS
#analysisFile <- "createPlinkChunks.txt"
#sampleFile <- Sys.getenv("BGEN_SAMPLE_FILE")
#bgenFile <- file.path(Sys.getenv("BGEN_CHUNK_DIR"),"chr10impv1_fromSNP1050001_toSNP1200000_10_subset.bgen")
#outputDir <- "."

chunkName <- substr(basename(bgenFile),1,nchar(basename(bgenFile))-5)

snpstatFile <- file.path()

message("Process analysis file: ",analysisFile)


#Analysis options
message("Process analysis file: ",analysisFile)
requiredOptions <- c("phenoFile")
options <- parseAnalysisFile(analysisFile,scriptFileName,requiredOptions)
requiredValues <- options$requiredValues
binaryOptions <- options$binary
unaryOptions <- options$unary

#Process options
phenoFile <- requiredValues["phenoFile"] 
outputFile <- file.path(outputDir,chunkName)

plinkOptions <- concatenateProgramOptions(unaryOptions,binaryOptions,optionPrefix="--")

cmd <- paste0("plink --bgen ",bgenFile," --memory 2000 --sample ",sampleFile,plinkOptions," --out ",outputFile)
message("Run plink analysis on .bgen chunk:")
message(cmd)
system(cmd)

message("Set missing snpids to CHR:POS_A1_A2 in .bim file")
cmd <- paste0("awk '{print $1,$2=="."?$1":"$4"_"$5"_"$6:$2,$3,$4,$5,$6}' ",outputFile,".bim > ",outputFile,".bim.temp")
message(cmd)
system(cmd)
cmd <- paste0("mv",outputFile,".bim.temp ",outputFile,".bim")
message(cmd)
system(cmd)