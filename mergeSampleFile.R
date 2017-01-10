#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

####
#This script merges a .sample file with a phenotype file specified in a snptest ANALYSIS_FILE on the first column (subject ID)
#
# Usage on loginnode for testing: ./createMergedSampleFile.R ANALYSIS_FILE SAMPLE_FILE OUTPUT_DIR
####
#module load R/3.2.1

scriptFileName <- "runSNPtestOnChunk.R"

analysisFile <- args[1]
sampleFile <- args[2]
outputFile <- args[3]

#Test ARGS
#analysisFile <- "example_logistic_analysis.txt"
#sampleFile <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/phenotypes/combined/impv1.sample"
#outputFile <- "example_merged.sample"

#required options 
requiredOptions <- get(paste0("requiredOptions_",scriptFileName))

message("Process analysis file: ",analysisFile)

options <- parseAnalysisFile(analysisFile,scriptFileName,requiredOptions)

requiredValues <- options$requiredValues
binaryOptions <- options$binary
unaryOptions <- options$unary
analysisName <- options$analysisName

outputFile <- file.path(".",analysisName,outputFile)

#Process options
phenoFile <- requiredValues["phenoFile"] 



analysisType <- strsplit(requiredValues["analysisType"],split=" ",fixed=T)[[1]] #character vector of "linear" and "logistic"


if(!all(analysisType %in% c("dichotomous","continuous"))){
  message("ERROR: analysisType should be linear or logistic for all phenotypes in analysis file: ",analysisFile)
  quit(save="no",status=-1)
}


message("Process additional snptest options...")

if (!("pheno" %in% names(binaryOptions) | "mpheno" %in% names(binaryOptions))){
  message("ERROR: No pheno or mpheno option specified in ANALYSIS_FILE: ",analysisFile)
  quit(save="no",status=-1)
}

if ("pheno" %in% names(binaryOptions)){
  phenoVars <- binaryOptions["pheno"]
}
if ("mpheno" %in% names(binaryOptions)){
  phenoVars <- strsplit(binaryOptions["mpheno"],split=" ",fixed=T)[[1]]
}

if(length(phenoVars) != length(analysisType)){
  message("ERROR: analysisType and (m)pheno should contain the same number of values in analysis file: ",analysisFile)
  quit(save="no",status=-1)
}

coVars <- as.character(ifelse(is.null(binaryOptions["cov_names"]),c(),strsplit(binaryOptions["cov_names"]," "))[[1]])


#Merge phenotype file with ukbio .sample file
message("Merge UKBIO sample file and phenotype file...")
message("sample file: ", sampleFile)
message("phenotype file: ", phenoFile)
message("merged output file: ", outputFile)

headerLinesSampleFile <- readLines(sampleFile, n = 2, ok = TRUE, warn = TRUE, encoding = "unknown")
message("Current dir: ", getwd())
message("Load sample file data..")
sampleData <- fread(sampleFile)

message("Load phenotype data..")
varNames <- c(phenoVars,coVars)
#restrict to variables that will be analyzed
phenoData <- fread(phenoFile,header=T,sep="\t",skip=0)
phenoData <- phenoData[,c("f.eid",varNames),with=F]


message("If necessary determine variable types...")
#Determine variable types. not available in second row of file, autodetermine with heuristic
if(all(phenoData[1,] %in% c("C","P","B","D","0",0))){
  typesPhenoFile <- as.character(phenoData[1,-1,with=F])
  hasTypeLine <- T
}else{
  hasTypeLine <- F
#Automatic type determinations:
#all variables not used as pheno var or covariate are assumed to be "C"
#For variables set as (m)pheno or covar the following results apply:
#if only 0/1 values and phenotype: "B"
#if only positive integer values and <6 unique values: "D"
#if only phenotype and not B or D: "P"
#if not phenotype and not D: "C"
typesPhenoFile <- c()
for (i in 1:length(varNames)){

  vec <- phenoData[,varNames[i],with=F][[1]]
  isDiscrete <- is.integer(vec) && all(vec>=0,na.rm=T) && length(na.omit(unique(vec)))<6
  is01 <- all(na.omit(vec) %in% c(0,1))

  #phenotype variable
  if (varNames[i] %in% phenoVars){

      isDichotomous <- analysisType[which(varNames[1] %in% phenoVars)] == "dichotomous"
      if(isDichotomous & !is01){
        message("ERROR: please make sure that binary phenotypes are coded 0/1!")
        quit(save="no",status=-1)
      }

      phenoVars[varNames[i] %in% phenoVars]
      type <- ifelse(isDichotomous,"B","P") 
      message("variable ",varNames[i]," is assigned type: ",type)
    # covariate
    }else if (length(coVars)>0  && varNames[i] %in% coVars){
      type <- ifelse(isDiscrete,"D","C")
      message("variable ",varNames[i]," is assigned type: ",type)

    }else{
      message("ERROR: ",varNames[i]," is not a phenotype nor a covariate.")
      quit(save="no",status=-1)
    }
  typesPhenoFile[i] <- type
}
}

message("Merge .sample and phenotype file...")
startLine <-ifelse(hasTypeLine,2,1)
mergedData <- merge(sampleData[-1,],phenoData[startLine:nrow(phenoData),c(names(phenoData)[1],varNames),with=F],by.x=names(sampleData)[1],
  by.y=names(phenoData)[1],sort=F,all.x=T,all.y=F)

message("Save merged .sample file...")
message("Deleting analysis directory if it exists: ",analysisName)
system(paste0("rm -f -R ",analysisName))
message("Creating analysis directory ",analysisName)
system(paste0("mkdir -p ",analysisName))
#Write header line of merged .sample file
write(paste(headerLinesSampleFile[1],paste0(varNames,collapse=" ")),file=outputFile)
#Append type line to merged .sample file
write(paste(headerLinesSampleFile[2],paste0(typesPhenoFile,collapse=" ")),file=outputFile,append=T)
#Append merged data
write.table(mergedData,file=outputFile,append=T,quote=F,row.names=F,col.names=F)
message("Merged file saved as ",outputFile)