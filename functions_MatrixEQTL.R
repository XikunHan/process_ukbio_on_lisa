### Functions used in runMatrixQTLOnChunk.R ###

#Convert binary plink into MatrixEQTL format
convertBedToMqtl <- function(plinkFile,meqtlGenoFile,nSubjects=NULL){
  trawFile <- paste0(plinkFile,".traw")
  snpidFile <-paste0(plinkFile,".snpids")
  cmd <- paste0("plink --bfile ",plinkFile," --recode A-transpose --freq --missing --out ",plinkFile)
  system(cmd)
  
  #Identify subjects in chunk
  fileHeader <- strsplit(readLines(trawFile,n=1),"\t")[[1]]
  subjectIds <- sapply(strsplit(fileHeader[-(1:6)],split="_"),function(x){x[1]})
  subjectIds <- paste0("S",subjectIds[1:min(nSubjects,length(subjectIds))])
  
  #Bash commands for speedup and to circumvent memory issues when applied to large datasets
  header <- c("id",subjectIds)
  write.table(t(header),file=meqtlGenoFile,quote=F,col.names=F,row.names=F,sep="\t")
  cmd <-paste0("tail -n +2 ",trawFile," | cut -f 2,7-",nSubjects+6," >> ", meqtlGenoFile)
  message(cmd)
  system(cmd)
}

runMatrixEqtl <- function(meqtlGenoFile,phenoFile,outputFile,batchSize=1000){
  #Test mqtl on chunk
  
  ## Settings
  sep <- "\t"
  # Linear model to use, modelANOVA or modelLINEAR
  useModel <- modelLINEAR # modelANOVA or modelLINEAR
  
  # Genotype file name
  SNP_file_name <- meqtlGenoFile
  
  # Gene expression file name
  expression_file_name <- phenoFile
  
  # Covariates file name
  # Set to character() for no covariates
  # covariates_file_name <- character()
  covariates_file_name <- character()
  
  # Output file name
  output_file_name <- outputFile
  
  # Only associations significant at this level will be output
  pvOutputThreshold <- 1
  
  # Error covariance matrix
  # Set to character() for identity.
  errorCovariance <- numeric()
  # errorCovariance = read.table("Sample_Data/errorCovariance.txt");
  
  ## Load genotype data
  tic_load <- proc.time()[3]
  
  snps = SlicedData$new();
  snps$fileDelimiter = sep; # the TAB character
  snps$fileOmitCharacters = 'NA' ;# denote missing values;
  snps$fileSkipRows = 1; # one row of column labels
  snps$fileSkipColumns = 1; # one column of row labels
  snps$fileSliceSize = batchSize; # read file in pieces of 10,000 rows
  snps$LoadFile(SNP_file_name);
  
  ## Load gene expression data
  gene = SlicedData$new();
  gene$fileDelimiter = sep; # the TAB character
  gene$fileOmitCharacters = 'NA'; # denote missing values;
  gene$fileSkipRows = 1; # one row of column labels
  gene$fileSkipColumns = 1; # one column of row labels
  gene$fileSliceSize = batchSize; # read file in pieces of 10,000 rows
  gene$LoadFile(expression_file_name);
  
  ## Load covariates
  cvrt = SlicedData$new();
  cvrt$fileDelimiter = sep; # the TAB character
  cvrt$fileOmitCharacters = 'NA'; # denote missing values;
  cvrt$fileSkipRows = 1; # one row of column labels
  cvrt$fileSkipColumns = 1; # one column of row labels
  cvrt$fileSliceSize = snps$nCols()+1; # read file in one piece
  if(length(covariates_file_name)>0) {
    cvrt$LoadFile(covariates_file_name);
  }
  
  toc_load = proc.time()[3];
  message('eQTL time: ', toc_load-tic_load, ' sec');
  
  message("Run MatrixEQTL...")
  ## Run the analysis
  {
    tic_eqtl = proc.time()[3];
    Matrix_eQTL_engine(snps, gene, cvrt,output_file_name,pvOutputThreshold,useModel, errorCovariance, verbose=TRUE,min.pv.by.genesnp = F,noFDRsaveMemory=T);
    toc_eqtl = proc.time()[3];
  }
  gc()
  message('eQTL time: ', toc_eqtl-tic_eqtl, ' sec')
  #show(data.frame(load = toc_load-tic_load, eQTL = toc_eqtl-tic_eqtl))
}

#Given a set of ranges, defined by lower and upper bouds, compute which range index a scalar belongs to
computeBinScalar <- function(x,lowBounds,upBounds,leftInclusive=T){
  #If x equals single digit
  stopifnot(length(lowBounds)==length(upBounds))
  stopifnot(all(lowBounds<=upBounds))
  
  if(any(x == upBounds & x == lowBounds)){return(which(x == upBounds & x == lowBounds))}
  
  if(leftInclusive){
    index <- which(x >= lowBounds & x < upBounds)
  }else{
    index <- which(x > lowBounds & x <= upBounds)
  }
  if(length(index) == 0) index = NA
  return(index)
}

#Vectorized version of computeBinScalar
computeBin <- Vectorize(computeBinScalar,vectorize.args="x")

#Process output from MatrixEQTL and write min pvalue for all combinations of maf and missing geno bins
processPermResults <- function(plinkFile,inputFile,outputFile,mafLimits=c(0.0001,0.0005,0.001,0.005,0.01,0.05),missLimits=c(0.0001,0.0005,0.001,0.005,0.01,0.05,0.1,0.25))
{
  frqFile <- paste0(plinkFile,".frq")
  missFile <- paste0(plinkFile,".lmiss") 
  
  
  #Define bins
  lowMafBounds <- c(sort(unique(mafLimits)))
  upMafBounds <- c(sort(unique(mafLimits))[-1],0.5001)
  mafLimHeaders <- paste0("[",format(lowMafBounds,scientific=F),",",format(upMafBounds,scientific=F),")")
  
  missLimits <-c(0,sort(unique(missLimits)))
  lowMissBounds <- c(0,missLimits[-length(missLimits)])
  upMissBounds <- missLimits
  missLimHeaders <- paste0("(",format(lowMissBounds,scientific=F),",",format(upMissBounds,scientific=F),"]")
  
  frqDT <- fread(frqFile,select=c("SNP","MAF"))
  missDT <- fread(missFile,select=c("SNP","F_MISS"))
  frqDT[,mafBin:=factor(mafLimHeaders[computeBin(MAF,lowMafBounds,upMafBounds,leftInclusive = T)])]
  missDT[,missBin:=factor(missLimHeaders[computeBin(F_MISS,lowMissBounds,upMissBounds,leftInclusive = F)])]
  
  message("Load ", inputFile,"...") 
  DT <- fread(inputFile)
  DT <- merge(DT,frqDT,by="SNP")
  gc()
  DT <- merge(DT,missDT,by="SNP")
  gc()
  names(DT)[1:6] <- c("SNP","phenoID","beta","t","pvalue","MAF")
  
  nPhenos <- length(unique(DT$phenoID))
  result <- DT[,list(chunk=basename(plinkFile),minP=min(pvalue,na.rm=T),nSNPs=.N/nPhenos,nPhenos=nPhenos),by=c("phenoID","mafBin","missBin")]
  message("Save chunk result...")
  write.table(result,file=outputFile,quote=F,row.names=F,col.names=T)
  file.create(paste0(outputFile,".log"))
}
