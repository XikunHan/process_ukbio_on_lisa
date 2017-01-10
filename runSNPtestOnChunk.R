#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

####
#This script runs a SNPtest analysis on  .bgen chunks.
# 
# Usage on loginnode for testing: ./runSNPtestOnChunk.R ANALYSIS_FILE SAMPLE_FILE BGEN_FILE OUTPUT_DIR
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

scriptFileName <- "runSNPtestOnChunk.R"

analysisFile <- args[1]
sampleFile <- args[2]
bgenFile <- args[3]
outputDir <- args[4]



#Test ARGS
#analysisFile <- "test_analysis.txt"
#sampleFile <- "./test_analysis_merged_impv1.sample"
#bgenFile <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/intermediate/genotypes/chunks/filtered/serial/chr10impv1_fromSNP1050001_toSNP1200000_10_subset.bgen"
#outputDir <- "."

message("Process analysis file: ",analysisFile)

#required options 
requiredOptions <- get(paste0("requiredOptions_",scriptFileName))

#Parse options
options <- parseAnalysisFile(analysisFile,scriptFileName,requiredOptions)

requiredValues <- options$requiredValues
analysisName <- options$analysisName
unaryOptions <- options$unaryOptions
binaryOptions <- options$binaryOptions


#Set output file name
bgenFileWithoutExtension <- paste0(substr(basename(bgenFile), 1, nchar(basename(bgenFile))-5))
outputPrefix <- paste0(analysisName,"_",bgenFileWithoutExtension)

outputFile <- file.path(outputDir,paste0(outputPrefix,".snptestresult"))

message("Output file: ",outputFile)

message("Process additional snptest options...")
subjectExclusionFile <- requiredValues["subjectExclusionFile"]
snptestOptions <- concatenateProgramOptions(unaryOptions,binaryOptions)

#Run snptest
cmd <- paste0("source scriptSettings.sh;
  snptest -data ",bgenFile," ",sampleFile," -o ",outputFile," -exclude_samples ",subjectExclusionFile," ",snptestOptions)
message("Runnning the following snptest command:")
message(cmd)
system(cmd)
