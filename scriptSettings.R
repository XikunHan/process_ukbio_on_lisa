## LOAD PACKAGES AND INSTALL IF NECESSARY
#Define package dependencies

listOfPackages <- c("qqman","data.table","parallel","MatrixEQTL","methods")

warningSetting <- getOption("warn")

#Install EasyQC from source locally
#if(!"EasyQC" %in% installed.packages()[,"Package"]) install.packages("/home/ctgukbio/programs/EasyQC_9.2.tar.gz",repos=NULL,type="source")
#require(EasyQC,quietly=F,warn.conflicts = F)

if(!"optparse" %in% installed.packages()[,"Package"]) install.packages("optparse", repos="http://R-Forge.R-project.org")
require(optparse,quietly=F,warn.conflicts = F)


#Install online packages if necessary
newPackages <- listOfPackages[!(listOfPackages %in% installed.packages()[,"Package"])]
if(length(newPackages)>0) install.packages(newPackages,repos=Sys.getenv("DEFAULT_R_REPOS"))

#Load online packages
for(package in listOfPackages){suppressMessages(require(package,quietly=T,warn.conflicts = F,character.only=T))}

## PUT SCRIPT ARGUMENTS IN ARGS
args <- commandArgs(trailingOnly=TRUE)

startsWith <- function(x,pattern){
  substr(x, 1, nchar(pattern)) == pattern
}

source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"functions.R"))

requiredOptions_runSNPtestOnChunk.R <- c("phenoFile","subjectExclusionFile","analysisType")
requiredOptions_estimateHeritabilityREML.R <- c("phenoFile","subjectExclusionFile","subjectLimit")

#Set ANALYSIS as current dir if not set (for debuggin purposes)
if(Sys.getenv("ANALYSIS_DIR")==""){  
  Sys.setenv(ANALYSIS_DIR=getwd())
}

