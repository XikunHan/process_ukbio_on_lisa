#!/bin/bash
source scriptSettings.sh

####
#This script automatically submits jobs to the cluster to run a specified chunk-based analysis.
#An <analysis-file> contains all options/details of the analysis to run. The first
#
# Usage on loginnode (automatically submits jobs to cluster): 
# startPlinkChunkAnalysis.sh <analysis-file> <walltime> [chunk-type] [nprocs]
#
#Example of <analysis-file> for a plink analysis per chunk:
#runPLINKonChunk.R
#pheno:=phenotypes.txt
#covar:=phenotypes.txt
#remove:=excludeSubjects.txt
#exclude:=excludeSNPs.txt
#linear:=
#allow-no-sex:=
#pheno-name:=f.50.0.0
#covar-name:=f.22001.0.0,f.22009.0.1
#
#This wil run on all chunks:
#plink --bfile <chunk-prefix> --remove excludeSubjects.txt --exclude excludeSNPs.txt
#                              --pheno phenotypes.txt --linear
#                              --covar phenotypes.txt --covar-name f.22001.0.0,f.22009.0.1
#                              --allow-no-sex --out <chunk-prefix>
####

helpString="""
Usage: startPlinkChunkAnalysis.sh <analysis-file> <walltime> [chunk-type] [nprocs] [memgb] [queue-type]\n
     <analysis-file> will be used to name the output directory and therefore should be unique\n
     Do not use dots in the file name except at the end for the file extension\n
     <analysis-file> should be located in your current directory\n
     <walltime> xx:yy:zz indicates the maximal walltime allowed per job (xx hours, yy minutes, zz seconds)\n
     Optional parameter [chunk-type] should be one of [bgen ,test or bgentest,plink,plinktest]; is 'plink' by default\n
     Optional parameter [nprocs] is the number of processors per node that should be used. Default all-1\n
     Optional parameter [memgb] should be either '32gb' or '64 gb' to restrict to nodes with a specific amount of memory. Default is empty (no restriction). Option is ignored on the high memory node.\n
     Optional parameter [queue-type], if 'highmem', high memory node is used
"""

if [[ "$1" == "help" ]]; then
  echo -e $helpString
  exit 0
fi

if [[ "$#" -eq 2 ]] || [[ "$#" -eq 3 ]] || [[ "$#" -eq 4 ]] || [[ "$#" -eq 5 ]] || [[ "$#" -eq 6 ]];
  then
    ANALYSIS_FILE=$1
    MAX_TIME=$2
    CHUNK_TYPE=$3
    NPROCS=$4
    MEMGB=$5
    QUEUE_TYPE=$6
  else
    echo "ERROR: Wrong number of parameters!"
    echo -e $helpString
    exit 0
fi

#Run on lisa high memory load yes/no
HIGHMEM="FALSE"


if [[ "$QUEUE_TYPE" == "highmem" ]]; then
  HIGHMEM="TRUE"
fi

echo "NPROCS: $NPROCS"

#Determine type chunk: bgen, bgentest, plink, plinktest
CHUNK_DIR=""

if [ "$CHUNK_TYPE" == "" ] || [ "$CHUNK_TYPE" == "plink" ] ; then
  CHUNK_DIR=${PLINK_CHUNK_DIR}
  IS_TEST="FALSE"
fi

if [ "$CHUNK_TYPE" == "test" ] || [ "$CHUNK_TYPE" == "plinktest" ] ; then
  CHUNK_DIR=${PLINK_TESTCHUNK_DIR}
  IS_TEST="TRUE"
fi


if [ "$CHUNK_DIR" == "" ] ; then
  echo "<chunk-type> should be one of [plink,test|plinktest]"
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
  echo "Create result directory ${ANALYSIS_NAME}"
  mkdir -p ${ANALYSIS_NAME}
fi

STOPOS_FILE="${ANALYSIS_DIR}/${ANALYSIS_NAME}/chunk_ranges${RESULT_SUFFIX}.stopos"
POOL_NAME="pool_${ANALYSIS_NAME}${RESULT_SUFFIX}"
LOG_OUTPUT_DIR="${ANALYSIS_DIR}/${ANALYSIS_NAME}/logs${RESULT_SUFFIX}"

#Check if values are left in stopospool AND stopos file exists
#If values left in stopos pool do no create new stopos file and continue with those
stopos status -p ${POOL_NAME} &> poolstatus.tmp
LEFT_IN_POOL=`cat poolstatus.tmp | sed -n 2p | grep -o -E '[0-9]+'`

if [[ -f "${STOPOS_FILE}" && "$LEFT_IN_POOL" > 0 ]]; then
  echo "Continue with $LEFT_IN_POOL values in stopos pool..."
  NR_OF_STOPOSVALUES="$LEFT_IN_POOL"
else # no stopos file exists OR stopospool empty

#If stopos file does not exist backup previous results and log files
if [ ! -f "${STOPOS_FILE}" ]; then
  echo "Stopos value file does not exist: ${STOPOS_FILE}"
  echo "Start new analysis and backup previous results if necessary"
  BACKUP_SUFFIX=`date '+%d_%m_%Y_%H_%M_%S'`
  
  #Backup results and logs directories if present (trigger new analysis)
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

echo "Reset stopos pool"
stopos purge -p ${POOL_NAME}
stopos create -p ${POOL_NAME}

echo "Create new stopos param file to determine which chunks (still) need to be analyzed..."
echo "createStoposChunkFile.R ${CHUNK_DIR} ${STOPOS_FILE}"
Rscript $UKBIO_SCRIPTDIR/createStoposPlinkChunkFile.R ${CHUNK_DIR} ${STOPOS_FILE} || exit 1

NR_OF_STOPOSVALUES=`cat ${STOPOS_FILE} | wc -l`
if [[ "$NR_OF_STOPOSVALUES" == "0" ]]; then
 echo "All chunks have already been processed"
 echo "No job(s) submitted"
exit 0
fi
  
echo "Create results directory if necessary: ${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}"
mkdir -p ${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}
echo "Create logs directory if necessary: ${ANALYSIS_DIR}/${ANALYSIS_NAME}/logs${RESULT_SUFFIX}"
mkdir -p ${LOG_OUTPUT_DIR}
echo "Create processed stopos values directory if necessary: ${STOPOS_FILE}_processedchunks"
mkdir -p ${STOPOS_FILE}_processedchunks

echo "Add parameters to stopos (can take a minute or two)..."

ERROR=$( { stopos -p "${POOL_NAME}" add "${STOPOS_FILE}" | grep 'ERROR' ; } 2>&1 )
if [[ -z "$ERROR" ]]; then
 echo "${ERROR}" 1>&2
 exit
fi

fi #end of create new stopos file branch (no stopos file OR stopospool is empty)



stopos -p "${POOL_NAME}" status



echo "######################################"
echo "Ready to analyze ${NR_OF_STOPOSVALUES} chunk(s)"
echo "######################################"




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


if [ "${HIGHMEM}" == "TRUE" ]; then
  N_JOBS=""   #1-100
  WALLTIME="-l walltime=${MAX_TIME} "
  QUEUE="-qhighmem "
  if [[ "$NPROCS" == "" ]]; then
  NPROCS=47
  fi
else
  JOBS_NEEDED=$(((NR_OF_STOPOSVALUES+NPROCS) / NPROCS))
  N_JOBS="-t 1-$(((${JOBS_NEEDED}<1000)?${JOBS_NEEDED}:1000)) " #69  #"1-69"   #1-100 #< 1000
  if [ "${MEMGB}" != "" ]; then
    MEMGB=":mem${MEMGB}"     
  fi
  WALLTIME="-l walltime=${MAX_TIME} -lnodes=1${MEMGB} "
  QUEUE=""
  if [[ "$NPROCS" == "" ]]; then
  NPROCS=15
  fi
fi

#echo $N_JOBS
#echo $NR_OF_STOPOSVALUES

echo "Submit following command:"
echo "qsub ${N_JOBS}-N ${ANALYSIS_NAME}${RESULT_SUFFIX} -o ${LOG_OUTPUT_DIR} -e ${LOG_OUTPUT_DIR} ${QUEUE}${WALLTIME}-v POOL_NAME=${POOL_NAME},STOPOS_FILE=${STOPOS_FILE},HIGHMEM=${HIGHMEM},NPROCS=${NPROCS},ANALYSIS_FILE=${ANALYSIS_FILE},ANALYSIS_NAME=${ANALYSIS_NAME},IS_TEST=${IS_TEST},RESULT_SUFFIX=${RESULT_SUFFIX} ${UKBIO_SCRIPTDIR}/analyzePlinkChunksJob.sh"

qsub ${N_JOBS}-N ${ANALYSIS_NAME}${RESULT_SUFFIX} -o ${LOG_OUTPUT_DIR} -e ${LOG_OUTPUT_DIR} ${QUEUE}${WALLTIME}-v POOL_NAME=${POOL_NAME},STOPOS_FILE=${STOPOS_FILE},HIGHMEM=${HIGHMEM},NPROCS=${NPROCS},ANALYSIS_FILE=${ANALYSIS_FILE},ANALYSIS_NAME=${ANALYSIS_NAME},IS_TEST=${IS_TEST},RESULT_SUFFIX=${RESULT_SUFFIX} ${UKBIO_SCRIPTDIR}/analyzePlinkChunksJob.sh


