#Create phenotypes
require(data.table)
#install.packages("optparse", repos="http://R-Forge.R-project.org")
require(optparse)

option_list <- list(
  make_option(c("-i", "--plinkprefix"),help="Plink prefix used to identify subjects"),
  make_option(c("-o", "--phenofile"),help="Name of output file to save permuted phenotypes to"),
  make_option(c("-p", "--nperm"),default=10000,help="Number of permutations to generate"),
  make_option(c("-s", "--subjectlimit",default=NULL,help="Number of subjects to limit to (for testing purposes only)"))
)

# get command line options, i
opt <- parse_args(OptionParser(option_list=option_list))

#Write phenotype file
createPhenoFile <- function(plinkFile,phenoFile,nIter=10000,nSubjects=NULL){
if(is.null(nSubjects)){nrows=-1L}else{nrows<-nSubjects}
  
subjects <- fread(paste0(plinkFile,".fam"),col.names="IID",colClasses="character",select=1,nrows=nrows)
n <- nrow(subjects)

snps <- fread(paste0(plinkFile,".bim"),col.names=c("CHR","SNPID","CM","POS","A1","A2"))
m <- nrow(snps)

pheno <- round(rnorm(n),digit=2)

phenos <- t(replicate(nIter,pheno[sample.int(n)]))
header <- c("id",subjects$IID)
write.table(t(header),file=phenoFile,quote=F,row.names=F,col.names=F)
row.names(phenos) <- paste0("P",1:nIter)
write.table(phenos,file=phenoFile,quote=F,append=T,col.names=F)
}

if(opt$help){quit(save="n",0)}
#print(opt)
createPhenoFile(opt$plinkprefix,opt$phenofile,nIter=opt$nperm,nSubjects=opt$subjectlimit)