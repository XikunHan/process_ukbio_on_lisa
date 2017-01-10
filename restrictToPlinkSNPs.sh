#PBS -l walltime=02:00:00
#!/bin/bash
source scriptSettings.sh

helpString="
usage: restrictToPlinkSNPs.sh <result-prefix>\n
       Only keeps SNPs that are also present in plink chunks.\n
       <result-prefix> is the file name (without .txt extension) of a (merged) snptest file\n
       Filtered snps are saved in <result-file>_plinksnps.snptestresult\n
"

if [[ $1 == "help" ]]; then
	echo -e $helpString
	exit 0
fi

if [[ "$PBS_O_WORKDIR" == "" ]]; then
  RESULT_PREFIX=$1
fi

ANALYSIS_DIR="$PBS_O_WORKDIR"
if [[ "$ANALYSIS_DIR" == "" ]]; then
  ANALYSIS_DIR=`pwd`	
fi

cd ${ANALYSIS_DIR}

if [[ ! -f "${RESULT_PREFIX}.snptestresult" ]]; then
	echo "ERROR: Result file does not exist in current directory: ${ANALYSIS_DIR}/${RESULT_PREFIX}.snptestresult"
	exit -1
fi

echo "Restrict to plink SNPS..."
RESULT_FILE="${RESULT_PREFIX}_plinksnps.snptestresult"
head -n1 ${RESULT_PREFIX}.snptestresult > $RESULT_FILE

cut -f 2 -d ' ' ${PLINK_MERGE_FILE}.bim | sort -k1b,1 > .bim.tmp
tail -n+2 ${RESULT_PREFIX}.snptestresult | sort -k1b,1 > .res.tmp
join -t " " -1 1 -2 1 .bim.tmp .res.tmp >> $RESULT_FILE
#rm .bim.tmp
#rm .res.tmp

echo "Result saved to ${RESULT_FILE}"
echo "Done"
