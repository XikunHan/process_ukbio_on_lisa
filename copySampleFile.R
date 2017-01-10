#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

####
#This script merges a .sample file with a phenotype file specified in a snptest ANALYSIS_FILE on the first column (subject ID)
#
# Usage on loginnode for testing: ./createMergedSampleFile.R ANALYSIS_FILE SAMPLE_FILE OUTPUT_DIR
####
#module load R/3.2.1

scriptFileName <- "convertChunkToPlinkFormat.R"

analysisFile <- args[1]
sampleFile <- args[2]
outputFile <- args[3]

#Test ARGS
#analysisFile <- "example_logistic_analysis.txt"
#sampleFile <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/phenotypes/combined/impv1.sample"
#outputFile <- "example_merged.sample"

#required options 
requiredOptions <- c()

message("Process analysis file: ",analysisFile)

options <- parseAnalysisFile(analysisFile,scriptFileName,requiredOptions)
requiredValues <- options$requiredValues
binaryOptions <- options$binary
unaryOptions <- options$unary
analysisName <- options$analysisName

outputFile <- file.path(".",analysisName,outputFile)

message("Deleting analysis directory if it exists: ",analysisName)
system(paste0("rm -f -R ",analysisName))
message("Creating analysis directory ",analysisName)
system(paste0("mkdir -p ",analysisName))
message("Copy UKBIO .sample file without merge to ",outputFile)

system(paste0("cp ",sampleFile," ",outputFile))
