#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.env,"scriptSettings.R"))

egrep '^#*|^id rsid *' ./test_analysis/test_analysis_chr1impv1_fromSNP1_toSNP150000_1_subset.snptestresult > merged_results.txt && egrep -v '^#*|^id rsid *' ./test_analysis/*.snptestresult >> merged_results.txt



####
#This script merges and performs EasyQC quality control steps
# Usage on loginnode for testing: ./easyQCSNPtestResults.R EASYQC_CONFIG_FILE
####


# merge command bash shell 


#easyQCFile <- args[1]

#Test ARGS
#analysisFile <- "mergeSNPtestResults.ecf"

#
#EasyQC(analysisFile)

