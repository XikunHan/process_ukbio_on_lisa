#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

####
#This script peforms a BOLT-REML analysis based on a SNPtest analsis file.
#
# Usage on loginnode for testing: ./estimateHeritabilityREML.R ANALYSIS_FILE
####
#module load R/3.2.1

#type of analysis file expected
scriptFileName <- "estimateHeritabilityREML.R"

analysisFile <- args[1]



##Parse options in analysis file

#required options 
requiredOptions <- get(paste0("requiredOptions_",scriptFileName))

message("Process h2 analysis file: ",analysisFile)

#Parse analysis file
options <- parseAnalysisFile(analysisFile,scriptFileName,requiredOptions)
requiredValues <- options$requiredValues
binaryOptions <- options$binary
unaryOptions <- options$unary
analysisName <- options$analysisName


#Set path and file names
message("Set path and file names")
phenoCovFile <- file.path(Sys.getenv("ANALYSIS_DIR"),"pheno_cov_file_REML.txt")
phenoFile <- phenoCovFile
outputFile <- file.path(Sys.getenv("ANALYSIS_DIR"),paste0(analysisName,".boltremloutput"))

boltRemlPath <- Sys.getenv("BOLTREML_PATH")

tempInput=file.path("/scratch",Sys.getenv("USER"),"input")
tempOutput=file.path("/scratch",Sys.getenv("USER"),"output")

dir.create(tempInput, showWarnings = F,recursive=T)
dir.create(tempOutput, showWarnings = F,recursive=T)
stopifnot(file.exists(tempInput))
stopifnot(file.exists(tempOutput))
plinkPrefix <- file.path(tempInput,"plinkprefix")



#Process analysis file options
message("Processing required options...")

phenoFile <- requiredValues["phenoFile"] 
subjectLimit <- as.numeric(requiredValues["subjectLimit"])

subjectExclusionFile <- requiredValues["subjectExclusionFile"] 
stopifnot(file.exists(subjectExclusionFile))

if (!("phenoCol" %in% names(binaryOptions))){
  message("ERROR: No phenoCol option specified in ANALYSIS_FILE: ",analysisFile)
  quit(save="no",status=-1)
}
phenoVars <- strsplit(binaryOptions["phenoCol"],split=" ",fixed=T)[[1]]

message("Processing additional BOLTREML options...")

covarCol <- c()
qCovarCol <- c()
if("covarCol" %in% names(binaryOptions)) covarCol <- strsplit(binaryOptions["covarCol"],split=" ",fixed=T)[[1]]
if("qCovarCol" %in% names(binaryOptions)) qCovarCol <- strsplit(binaryOptions["qCovarCol"],split=" ",fixed=T)[[1]]

vars <- c("f.eid",phenoVars,covarCol,qCovarCol)

message("Phenotypes analyzed: ",paste0(phenoVars,sep=" ",collapse=","))
message("Covariates: ",ifelse(length(covarCol)==0,"none",paste0(covarCol,sep=" ",collapse=",")))
message("Quantitative covariates: ",ifelse(length(qCovarCol)==0,"none",paste0(qCovarCol,sep=" ",collapse=",")))


#Create phenotype covariate file used in BOLTREML including only phenotypes and subjects
#with no NA in phenotypes and not in exclusion list
message("Create phenotype covariate file")

phenoDf <- fread(phenoFile)[,vars,with=F]

setkey(phenoDf,f.eid)
subjectExcl <- fread(subjectExclusionFile)[[1]]

message("Exclude ",length(subjectExcl), " subjects...")

keepSubj <- setdiff(phenoDf$f.eid,subjectExcl)
phenoDf <- phenoDf[f.eid %in% keepSubj,]


noNAphenos <- !apply(phenoDf[,phenoVars,with=F],1,function(x)any(is.na(x)))

phenoDf <- phenoDf[noNAphenos,]

message(nrow(phenoDf), " subjects left with usable phenotypes (no NA in ",paste0(phenoVars,collapse=","),")")

oldCols <- names(phenoDf)
newCols <- c("FID","IID",oldCols)
phenoDf[,FID:=f.eid]
phenoDf[,IID:=f.eid]
setcolorder(phenoDf,newCols)
phenoDf[,f.eid:=NULL]

if(is.na(subjectLimit)){
  subjectLimit=nrow(phenoDf)
}else{
  message("Analysis limited to first ",subjectLimit, "subjects")
}

write.table(phenoDf[1:subjectLimit],file=phenoCovFile,quote=F,sep=" ",row.names=F)


#Copy plink file to scratch
message("Copy common (maf>0.01, geno<0.01) pruned (indep 100 5 0.8 ) plink subset to scratch...")

cmd <- paste0("plink --bfile ",Sys.getenv("PLINK_MERGE_COMMON_PRUNED_FILE")," --make-bed --keep ", phenoCovFile," --out ",plinkPrefix)
message(cmd)
system(cmd)

#Create BOLTREMPL option strings

#Phenotype option string
phenoOptions <- paste0("--phenoCol=",phenoVars,split="",collapse=" ")
phenoString <- paste0("--phenoFile=",phenoCovFile," ",phenoOptions)


#Covariate option string
covarOptions <- ""
if(length(covarCol)>0)covarOptions <- paste0("--covarCol=",covarCol,split="",collapse=" ")
qCovarOptions <- ""
if(length(qCovarCol)>0)qCovarOptions <- paste0("--qCovarCol=",qCovarCol,split="",collapse=" ")
covString <- ""
if(length(covarCol)>0 | length(qCovarCol)>0) covString <- paste0("--covarFile=",phenoCovFile," ",covarOptions," ",qCovarOptions)

#Number of threads avaialable
numThreads <- detectCores()-1
threadString <- paste0("--numThreads=",numThreads)

#Additional unary BOLTREML options
unaryREMLoptions <- "--reml --LDscoresMatchBp"
if(length(unaryOptions)>0) unaryREMLoptions <- paste(unaryREMLoptions,paste0("--",names(unaryOptions),sep="",collapse=" "))

bfileString <- paste0("--bfile=",plinkPrefix)

maxModelSnpsString <- paste0("--maxModelSnps=2000000")


cmd <- paste(boltRemlPath,bfileString,threadString,maxModelSnpsString,phenoString,covString,unaryREMLoptions,">",outputFile)
message(cmd)
system(cmd)