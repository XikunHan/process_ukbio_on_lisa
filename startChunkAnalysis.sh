#!/bin/bash
source scriptSettings.sh

#Run on lisa high memory load yes/no
HIGHMEM="FALSE"

####
#This script automatically submits jobs to the cluster to run a specified chunk-based analysis.
#An <analysis-file> contains all options/details of the analysis to run. The first
#
# Usage on loginnode (automatically submits jobs to cluster): 
# startChunkAnalysis.sh <analysis-file> <walltime> [chunk-type]
#
#Example of <analysis-file> for a snptest analysis per chunk:
#runSNPtestOnChunk.R
#phenoFile:=phenotypes.txt
#subjectExclusionFile:=excludeSubjects.txt
#analysisTime:=linear 
#method:=score
#frequentist:=1
#pheno:=f.50.0.0
#cov_names:=f.22001.0.0 f.22009.0.1 f.22009.0.2 f.22009.0.3 f.22009.0.4 f.22009.0.5

# This wil run on all chunks:
# ./snptest -data <chunk-prefix>.bgen impv1.sample -o <chunk-prefix>.out -method score -frequentist 1 -pheno pheno1
####==

helpString="""
Usage: startChunkAnalysis.sh <analysis-file> <walltime> [<chunk-type>]\n
     <analysis-file> will be used to name the output directory and therefore should be unique\n
     Do not use dots in the file name except at the end for the file extension\n
     <analysis-file> should be located in your current directory\n
     <walltime> xx:yy:zz indicates the maximal walltime allowed per job (xx hours, yy minutes, zz seconds)\n
     Optional paramter <chunk-type> should be one of [bgen ,test or bgentest,plink,plinktest]; is 'bgen' by default
"""

if [[ "$1" == "help" ]]; then
  echo -e $helpString
  exit 0
fi

if [[ "$#" -eq 2 ]] || [[ "$#" -eq 3 ]] || [[ "$#" -eq 4 ]] ;
  then
    ANALYSIS_FILE=$1
    MAX_TIME=$2
    CHUNK_TYPE=$3
    QUEUE_TYPE=$4
  else
    echo "ERROR: Wrong number of parameters!"
    echo -e $helpString
    exit 0
fi

if [[ "$QUEUE_TYPE" == "highmem" ]]; then
  HIGHMEM="TRUE"
fi

#Determine type chunk: bgen, bgentest, plink, plinktest
CHUNK_DIR=""

if [ "$CHUNK_TYPE" == "" ] || [ "$CHUNK_TYPE" == "bgen" ] ; then
  CHUNK_DIR=${BGEN_CHUNK_DIR}
  IS_TEST="FALSE"
fi

if [ "$CHUNK_TYPE" == "test" ] || [ "$CHUNK_TYPE" == "bgentest" ] ; then
  CHUNK_DIR=${BGEN_TESTCHUNK_DIR}
  IS_TEST="TRUE"
fi

if [ "$CHUNK_TYPE" == "plink" ] ; then
  CHUNK_DIR="${PLINK_CHUNK_DIR}"
  IS_TEST="FALSE"
fi

if [ "$CHUNK_TYPE" == "plinktest" ] ; then
  CHUNK_DIR="${PLINK_TESTCHUNK_DIR}"
  IS_TEST="TRUE"
fi

if [ "$CHUNK_DIR" == "" ] ; then
  echo "<chunk-type> should be one of [bgen,bgentest,plink,plinktest]"
  exit -1
fi


#Remove path
ANALYSIS_BASEFILE="${ANALYSIS_FILE##*/}"
#Remove suffix
ANALYSIS_NAME="${ANALYSIS_BASEFILE%.*}"

ANALYSIS_FILE="${ANALYSIS_BASEFILE}"

if [ ! -f "${ANALYSIS_FILE}" ]; then
  echo "ERROR: 
  Analysis-file is NOT located in your current working directory: ${ANALYSIS_FILE}"
  echo "Work directory: ${ANALYSIS_DIR}"
  exit -1
fi

dos2unix ${ANALYSIS_FILE}

RESULT_SUFFIX=""
if [[ "$CHUNK_TYPE" != "" ]]; then
  RESULT_SUFFIX="_${CHUNK_TYPE}"
fi



if [ ! -d "${ANALYSIS_NAME}" ]; then
  echo "ERROR: Result directory does not exist in current directory: ${ANALYSIS_NAME}"
  echo "Make sure you run mergeSampleFile.sh first"
  exit -1
fi

echo "Analysis directory OK"

STOPOS_FILE="${ANALYSIS_DIR}/${ANALYSIS_NAME}/chunk_names${RESULT_SUFFIX}.stopos"
POOL_NAME="pool_${ANALYSIS_NAME}${RESULT_SUFFIX}"
LOG_OUTPUT_DIR="${ANALYSIS_DIR}/${ANALYSIS_NAME}/logs${RESULT_SUFFIX}"


#If processed stopos values directory does not exist trigger new analysis and backup results
if [ ! -f "${STOPOS_FILE}" ]; then
  echo "Stopos value file does not exist: ${STOPOS_FILE}"
  echo "Start new analysis and backup previous results"
  BACKUP_SUFFIX=`date '+%d_%m_%Y_%H_%M_%S'`

  #delete results and logs directories if present (trigger new analysis)
  if [ -d "${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}" ]; then
     echo "Rename existing results directory..."
   mv ${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX} ${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}_backup${BACKUP_SUFFIX}
  fi
  if [ -d "${LOG_OUTPUT_DIR}" ]; then
   echo "Rename existing logs directory..." 
   mv ${LOG_OUTPUT_DIR} ${LOG_OUTPUT_DIR}_backup${BACKUP_SUFFIX}
  fi
  if [ -d "${STOPOS_FILE}_processedchunks" ]; then
     echo "Rename existing processed stopos value directory..."
   mv ${STOPOS_FILE}_processedchunks ${STOPOS_FILE}_processedchunks_backup${BACKUP_SUFFIX}
  fi
fi

echo "Create results directory if necessary: ${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}"
mkdir -p ${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}
echo "Create logs directory if necessary: ${ANALYSIS_DIR}/${ANALYSIS_NAME}/logs${RESULT_SUFFIX}"
mkdir -p ${LOG_OUTPUT_DIR}
echo "Create processed stopos values directory if necessary: ${STOPOS_FILE}_processedchunks"
mkdir -p ${STOPOS_FILE}_processedchunks




echo "Create stopos param file..."
echo "createStoposChunkFile.R ${CHUNK_DIR} ${STOPOS_FILE}"
createStoposChunkFile.R ${CHUNK_DIR} ${STOPOS_FILE}

NR_OF_STOPOSVALUES=`cat ${STOPOS_FILE} | wc -l`
echo "######################################"
echo "Ready to analyze ${NR_OF_STOPOSVALUES} chunk(s)"
echo "######################################"

if [[ "$NR_OF_STOPOSVALUES" == "0" ]]; then
  echo "All chunks have already been processed"
  echo "No job(s) submitted"
  exit 0
fi

if [[ ! -f "./${ANALYSIS_NAME}/mergedPhenoData.sample" ]];
  then
    echo "Merged sample file does not exist: ./${ANALYSIS_NAME}/mergedPhenoData.sample"
    echo "Please run mergeSampleFile.sh first"
    exit -1
fi

echo "Sample file exists: ./${ANALYSIS_NAME}/mergedPhenoData.sample"

#Check if stopos params file exists
if [[ ! -f "${STOPOS_FILE}" ]];
  then
    echo "File with stopos params does not exist: ${STOPOS_FILE}"
    exit -1
fi

  echo "ANALSYIS_NAME=${ANALYSIS_NAME}"
  echo "ANALSYIS_FILE=${ANALYSIS_FILE}"
  echo "POOL_NAME=${POOL_NAME}"
  echo "STOPOS_FILE=${STOPOS_FILE}"

  echo "Setup stopos pool"
  stopos purge -p ${POOL_NAME}
  stopos create -p ${POOL_NAME}

  echo
  echo "Add parameters to stopos (can take a minute or two)..."


  ERROR=$( { stopos -p "${POOL_NAME}" add "${STOPOS_FILE}" | grep 'ERROR' ; } 2>&1 )
  if [[ -z "$ERROR" ]]; then
  echo "${ERROR}" 1>&2
  exit
  fi

  stopos -p "${POOL_NAME}" status

if [ "${HIGHMEM}" = "TRUE" ]; then
  N_JOBS=""   #1-100
  WALLTIME="-l walltime=${MAX_TIME} "
  QUEUE="-qhighmem "
  NPROCS=47
else
  NPROCS=15
  N_JOBS="-t 1-$(((NR_OF_STOPOSVALUES+NPROCS) / NPROCS)) " #69  #"1-69"   #1-100
  WALLTIME="-l walltime=${MAX_TIME} -lnodes=1 "
  QUEUE=""
fi


echo "Submit following command:"
echo "qsub ${N_JOBS}-N ${ANALYSIS_NAME}${RESULT_SUFFIX} -o ${LOG_OUTPUT_DIR} -e ${LOG_OUTPUT_DIR} ${QUEUE}${WALLTIME}-v POOL_NAME=${POOL_NAME},STOPOS_FILE=${STOPOS_FILE},HIGHMEM=${HIGHMEM},NPROCS=${NPROCS},ANALYSIS_FILE=${ANALYSIS_FILE},ANALYSIS_NAME=${ANALYSIS_NAME},IS_TEST=${IS_TEST},RESULT_SUFFIX=${RESULT_SUFFIX} ${UKBIO_SCRIPTDIR}/analyzeChunksJob.sh"
echo

qsub ${N_JOBS}-N ${ANALYSIS_NAME}${RESULT_SUFFIX} -o ${LOG_OUTPUT_DIR} -e ${LOG_OUTPUT_DIR} ${QUEUE}${WALLTIME}-v POOL_NAME=${POOL_NAME},STOPOS_FILE=${STOPOS_FILE},HIGHMEM=${HIGHMEM},NPROCS=${NPROCS},ANALYSIS_FILE=${ANALYSIS_FILE},ANALYSIS_NAME=${ANALYSIS_NAME},IS_TEST=${IS_TEST},RESULT_SUFFIX=${RESULT_SUFFIX} ${UKBIO_SCRIPTDIR}/analyzeChunksJob.sh


