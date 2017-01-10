#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

#Script parameters
#First parameter: filename of phenotype list to be extracted
#Second paramter: filename with withdrawn subjects to remove
#Third paramter: filename of phenotype data file to extract from
#Fourth parameter: filename to save extracted phenotype data to

phenoListFile <- args[1]
withDrawnSubjectsFile <- args[2]
phenotypePrefix <- args[3]
outputFile <- args[4]

#TEST args
#phenoListFile <- file.path(getwd(),"svenvars.txt")
#phenotypePrefix <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/phenotypes/combined/combined_phenotypes"
#outputFile <- "testextraction.txt"
#withDrawnSubjectsFile <- "/home/ctgukbio/datasets/ukbio/applicationID1640/qc/final/phenotypes/combined/withdrawnsubjects.txt"

#Set UKBIO combined phenotype files
phenotypeFile <- paste0(phenotypePrefix,".tab")
phenoRFile <- paste0(phenotypePrefix,".r")


#User messages
message(paste0("pheno list filename: ", phenoListFile))
message(paste0("phenotype data file used: ", phenotypeFile))
message(paste0("output file name: ", outputFile))


#Column names in UKBIO combined phenotype data
columnNames <- names(fread(phenotypeFile,nrows=0))[-1]

#Check if duplicate column names exist and warn user
if(length(unique(columnNames))==length(columnNames)){
	message("WARNING: multiple columns in combined phenotype list with the same name!")
}

#Parse column names in UKBIO combined phenotype file into field code, subcode 1, and subcode 2 (f.fieldcode.subcode1.subcode2)
fieldNames <- sapply(strsplit(columnNames,split=".",fixed=T),function(x)x[2])
subCode1 <- sapply(strsplit(columnNames,split=".",fixed=T),function(x)x[3])
subCode2 <-  sapply(strsplit(columnNames,split=".",fixed=T),function(x)x[4])



#Convert dos new lines to unix new lines in user specified phenotype code list
system(paste("dos2unix",phenoListFile))

#Extract requested fields
#phenotypeList <- fread(phenoListFile,sep="\t",header=F,colClasses=c("character","character"))[[1]]
phenotypeList <- fread(phenoListFile,sep="\t",header=F)[[1]]
requestedRanges <- unlist(strsplit(as.character(phenotypeList),split=","))
requestedFields <- unlist(sapply(strsplit(requestedRanges,split="-"),function(x){if(length(x)==2){seq(as.numeric(x[1]),as.numeric(x[2]))}else{as.numeric(x)}}))

#Check if any of the requested field codes is non-numeric, if so quit
if(sum(is.na(as.numeric(requestedFields)))>0){
	message("Non-numeric UKBIO codes detected in: ",phenoListFile)
	quit(save="no",status=-1)
}


#Column numbers (1-based index) to be extracted from UKBIO combined phenotype data
#Column 1 is subject id and will always be extracted
requestedColumns <- c(1,which(fieldNames %in% requestedFields)+1)

#Save extracted data first to temporary file
tempOutputFile <- paste0(outputFile,".temp")
cmd <- paste0("cut -f",paste(requestedColumns,collapse=",")," ",phenotypeFile," > ",tempOutputFile)

message("Number of fields to be extracted: ",length(requestedFields))
message("Number of columns to be extracted: ", length(requestedColumns))
message("Command to be applied:")
message(cmd)
message("Extract and save fields to temporary file...")
system(cmd)

#Filter out withdrawn subjects and then copy to destination
message("Filter out withdrawn subjects and save to destination...")
cmd <- paste("filterOutLines.sh",withDrawnSubjectsFile,tempOutputFile,outputFile)
message("Command to be applied:")
message(cmd)
system(cmd)
message("Remove temporary file...")
system(paste0("rm ",tempOutputFile))


#Use R code from UKBIO to create an R file that loads the data as data.frame with factors
message("Create .R file to read data in R...")
rLabels <- readLines(phenoRFile)

filter <- startsWith(rLabels,"lvl.") | startsWith(rLabels,"lbl.")
for (f in requestedFields){
	filter <- filter | startsWith(rLabels,paste0("bd$f.",f,"."))
}


message("Create variable levels...")
#Create code for variable2level list
varLevelCode <- "ukbioCoding <- list()"
for (line in rLabels[filter]){
	if(startsWith(line,paste0("bd$f.")))
	{
		fieldRes <- regexpr("f.[0-9]+.[0-9]+.[0.9]+",line)
		fieldCode <- substr(line,fieldRes,fieldRes+attr(fieldRes,"match.length")-1)
        
        levelRes <- regexpr("lvl.[0-9]+",line)
        levelCode <- substr(line,levelRes,levelRes+attr(levelRes,"match.length")-1)

        lableRes <- regexpr("lbl.[0-9]+",line)
        lableCode <- substr(line,lableRes,lableRes+attr(lableRes,"match.length")-1)
		varLevelCode <- c(varLevelCode,paste0("ukbioCoding[[\"",fieldCode,"\"]] <- list(values=",levelCode,",lables=",lableCode,")"))
	}
}

#Write .R script
write(c("library(data.table)",
	paste0("#Load data\n",
	 "bd <- fread(\"",outputFile,"\",data.table=F)"),
	 "\n#Create factors",
	 rLabels[filter],
	 "\n#Create variablename-to-level list",
	 varLevelCode),file=paste0(outputFile,".R"))
#Remove as.Date since it causes problems when sourcing the R file
system(paste0("sed -i 's/as.Date//g' ",outputFile,".R"))
system(paste0("sed -i -E 's/.+list(values=,lables=).*//g' ",outputFile,".R"))
message("Done")
