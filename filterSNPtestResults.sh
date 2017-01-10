#PBS -l walltime=02:00:00
#!/bin/bash
source scriptSettings.sh

helpString="
usage: filterSNPtestResults.sh <result-prefix> [info-thresh] [maf-thresh]\n
       <result-prefix> is the file name (without .snptestresult extension) of a (merged) snptest file\n
       [info-thresh] is an optional info threshold (default info=0.8). Only snps with info > thresh will be included\n
       [maf-thresh] is an optional maf threshold (default maf=0.001). Only snps with maf > thresh will be included\n
       SNPs with an invalid p-value (outside [0,1]) and SNPs that are not present in the UKBIO merged plink file are also excluded.\n
       Finally, some formatting changes are applied.\n
       First, chromosomes 01-09 are changed into 1-9.
       Leading lines starting with # are removed, and a column with unique snp ids is added as the first column\n
       (same unique snp id as used in UKBIO merged plink files: chr:pos:A1_A2, where A1 and A2 are alleles in alphabetical order).\n
       Since the result is technically not a snptest result file anymore, filtered snps are saved to <result-file>_info0.8_maf0.001_plinksnps.txt\n
"

if [[ $1 == "help" ]]; then
	echo -e $helpString
	exit 0
fi

if [[ "$PBS_O_WORKDIR" == "" ]]; then
  RESULT_PREFIX=$1
  INFO_THRESH=$2
  MAF_THRESH=$3
fi
if [[ ${MAF_THRESH} == "" ]]; then
	MAF_THRESH="0.001"
fi

if [[ ${INFO_THRESH} == "" ]]; then
	INFO_THRESH="0.8"
fi

ANALYSIS_DIR="$PBS_O_WORKDIR"
if [[ "$ANALYSIS_DIR" == "" ]]; then
  ANALYSIS_DIR=`pwd`	
fi

cd ${ANALYSIS_DIR}

if [[ ! -f "${RESULT_PREFIX}.snptestresult" ]]; then
	echo "ERROR: SNPtest result file does not exist in current directory: ${ANALYSIS_DIR}/${RESULT_PREFIX}.snptestresult"
	exit -1
fi

RESULT_FILE="${RESULT_PREFIX}_info${INFO_THRESH}_maf${MAF_THRESH}_plinksnps.txt"

echo "Filter snps on info and maf..."
grep -vE "^#" "${RESULT_PREFIX}.snptestresult" | awk -v INFO_THRESH=$INFO_THRESH  -v MAF_THRESH=$MAF_THRESH 'NR==1 {
    for (i=1; i<=NF; i++){
        ix[$i] = i;
        if ($i ~ /pvalue/) pvalcol=$i;
    };
    #print $ix["all_maf"],MAF_THRESH;
    #print $ix["info"],INFO_THRESH;
    #print pvalcol;
    print "unique_snpid_plink",$0
    }
    NR>1 {
      $ix["chromosome"]=($ix["chromosome"] ~ /0[1-9]/ ? substr($ix["chromosome"],2,1) : $ix["chromosome"]);
      if ($ix["info"] >= INFO_THRESH && 
      $ix["info"] <=1 && 
      $ix["all_maf"] >= MAF_THRESH && 
      $ix["all_maf"] <= (1-MAF_THRESH) && 
      $ix[pvalcol] >= 0 &&
      $ix[pvalcol] <= 1) print $ix["chromosome"]":"$ix["position"]":"($ix["alleleA"]<$ix["alleleB"]?$ix["alleleA"]"_"$ix["alleleB"]:$ix["alleleB"]"_"$ix["alleleA"]),$0;
    }' - > .res.tmp

echo "Restrict to plink SNPS..."
head -n1 .res.tmp > $RESULT_FILE
echo "Sort snp ids in snptest result file..."
tail -n+2 .res.tmp | sort -k1b,1 > .res2.tmp
#rm .res.tmp

echo "Sort snp ids in merge plink file..."
cut -f 2 -d ' ' ${PLINK_MERGE_FILE}.bim | sort -k1b,1 > .bim.tmp

echo "Identify common snps and save..."
join -t " " -1 1 -2 1 .res2.tmp .bim.tmp >> $RESULT_FILE
#rm .bim.tmp
#rm .res2.tmp
echo "Result saved to ${RESULT_FILE}"
echo "Done"

#filterSNPtestResults.R $RESULT_PREFIX $INFO_THRESH $MAF_THRESH
