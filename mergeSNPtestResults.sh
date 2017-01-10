#PBS -lwalltime=02:00:00
#!/bin/bash
source scriptSettings.sh

SUFFIX=$1

helpString="
usage: mergeSNPtestResults.sh [suffix]\n
       [suffix] is an optional suffix (such as test or bgentest) to merge results from results_[suffix]\n
       By default no suffix is assumed and a 'results' directory is assumed to exist
       Merged results are saved in merged_snps_<analysis-name>[_suffix].snptestresult\n
       Make sure you call this script from the analysis directory containing the 'results[_suffix]' directory\n
       \n
       Alternatively, on the cluster:\n
       qsub -v [SUFFIX=suffix] ${UKBIO_SCRIPTDIR}/mergeSNPtestResults.sh
"

if [[ $1 == "help" ]]; then
	echo -e $helpString
	exit 0
fi

if [[ ${SUFFIX} != "" ]]; then
	SUFFIX="_${SUFFIX}"
fi


if [[ ! -d "${ANALYSIS_DIR}/results${SUFFIX}" ]]; then
	echo "ERROR: results directory does not exist in current directory: results${SUFFIX}"
	exit -1
fi

if [[ ! -f "${ANALYSIS_DIR}/chunk_names${SUFFIX}.stopos" ]]; then
	echo "ERROR: chunk_names${SUFFIX}.stopos does not exist in current directory"
	exit -1
fi

ANALYSIS_NAME="${ANALYSIS_DIR##*/}"

MERGED_FILE="merged_snps_${ANALYSIS_NAME}${SUFFIX}.snptestresult"

NR_OF_RESULTFILES=`ls ${ANALYSIS_DIR}/results${SUFFIX}/*.snptestresult | wc -l `

if [[ $SUFFIX == "" || "bgen" ]]; then
NR_OF_INPUTCHUNKS=`ls $BGEN_CHUNK_DIR/*.snpstats | wc -l `
else
  if [[ $SUFFIX == "test" ]]; then
     NR_OF_INPUTCHUNKS=`ls $BGEN_TESTCHUNK_DIR/*.snpstats | wc -l `
  else
     echo "ERROR: Suffix not recognized: ${SUFFIX}"
     echo "empty suffix, 'bgen' or 'test' expected as suffix parameter."
     exit -1
  fi
fi




if [[ "${NR_OF_RESULTFILES}" != "${NR_OF_INPUTCHUNKS}" ]]; then
  echo "WARNING: Nr of result files ${NR_OF_RESULTFILES} does not equal number of input chunks ${NR_OF_INPUTCHUNKS}!"
  echo "Do you want to continue merging the existing result files anyway? [y/N]"
  read ANSWER
  if [[ "${ANSWER}" == "y" ]]; then
    echo "Continue merge..."
  else
    echo "Merge aborted."
    exit -1
  fi
else
  echo "Nr of result files equals number of input chunks ${NR_OF_RESULTFILES}: OK"
fi


cd ${ANALYSIS_DIR}/results${SUFFIX}
FIRST_FILE=`ls *.snptestresult | head -n 1`

echo "Broken pipe error can be ignored"
echo "Merging data.. (can take a few minutes)"

#remove -h to add the filename to the alternative snp id
egrep -h '^alternate_ids rsid *|^# *' ${FIRST_FILE} > ${ANALYSIS_DIR}/${MERGED_FILE} && egrep -vh '^alternate_ids rsid *|^# *' *.snptestresult >> ${ANALYSIS_DIR}/${MERGED_FILE}
cd ${ANALYSIS_DIR}

if [[ ! -f ${ANALYSIS_DIR}/${MERGED_FILE} ]] ; then
	echo "ERROR: could not create ${ANALYSIS_DIR}/${MERGED_FILE}"
	exit -1
fi

echo "Merged snptest results file save to: ${ANALYSIS_DIR}/${MERGED_FILE}"
