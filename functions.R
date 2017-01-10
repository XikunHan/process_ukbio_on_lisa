parseAnalysisFile <- function(analysisFile,scriptFileName,requiredOptions=c()){

analysisName <- paste(strsplit(analysisFile,split=".",fixed=T)[[1]][-length(strsplit(analysisFile,split=".",fixed=T)[[1]])],collapse=".")

lines <- readLines(analysisFile)[]
analysisOptions <- lines[substr(lines,1,1)!="#"]

if (analysisOptions[1]!=scriptFileName){
 message("Wrong type of ANALYSIS_FILE! First line in ",analysisFile," should be: ", scriptFileName)
 quit(save="no",satus=1)
}

analysisOptions <- analysisOptions[2:length(analysisOptions)]
analysisOptions <- strsplit(analysisOptions,split=":=",fixed=T)
optionKeys <- sapply(analysisOptions,function(x)x[1])
values <- sapply(analysisOptions,function(x)x[2])
names(values) <- optionKeys


if (any(is.na(optionKeys))){
  message("ERROR: Malformed analysis file! Use <option> or <option:=optionvalue> format on all but first line in ",analysisFile)
  quit(save="no",satus=1)
}


if (!all(requiredOptions %in% optionKeys) | any(is.na(values[requiredOptions])) ){
  message("ERROR: Not all required options (",paste(requiredOptions,collapse=","),") are present in analysis file: ",analysisFile)
  quit(save="no",status=1)
}

requiredValues<-values[(names(values) %in% requiredOptions )]
optionalValues<-values[!(names(values) %in% requiredOptions )]
unaryOptions <- optionalValues[is.na(optionalValues)]
binaryOptions <- optionalValues[!is.na(optionalValues)]

options <- list(requiredValues=requiredValues,unaryOptions=unaryOptions,binaryOptions=binaryOptions,analysisName=analysisName)

return(options)

}


concatenateProgramOptions <- function(unaryOptions,binaryOptions,optionPrefix="-"){
  programOptions <- " "
  if(length(unaryOptions)>0){programOptions <- paste(programOptions,paste0(optionPrefix,names(unaryOptions),collapse=" "))}
  if(length(binaryOptions)>0){programOptions <- paste(programOptions,paste0(optionPrefix,names(binaryOptions)," ",binaryOptions,collapse=" "))}
  return(programOptions)
}
