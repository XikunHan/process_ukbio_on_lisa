#!/bin/bash
source scriptSettings.sh

####
#This script runs some analysis on all .bgen chunks.
# Requires as a parameter:
# - an option file $ANALYSIS_FILE containing all details of the analysis to run 
# - the first line of $ANALYSIS_FILE should contain the script name to run on each chunk
# - the remaining lines contain options that can be different depending on the script.
#
# Assumes:
# - Bgen chunk locations, .sample file and  are assumed be passed on through stoposvalues and script parameters
# - Results will be saved in subdirectory of current WORK_DIR
####

#POOL_NAME, ANALYSIS_FILE, ANALYSIS_NAME, ANALYSIS_DIR, BGEN_SAMPLE_FILE, NPROCS,STOPOS_FILE, IS_TEST should be available (passed on) 

SAMPLE_FILE="${BGEN_SAMPLE_FILE}"

cd ${ANALYSIS_DIR}
echo "Analysis dir: ${ANALYSIS_DIR}"
echo "Start chunk analysis job"

if [[ "${HIGHMEM}" == "TRUE" ]]; then
  MAX_ITER="1000"
  echo "Job runs on high memory node"
else
  MAX_ITER="1"
  echo "Job runs on normal node"
fi

#Check if analysis file exists
if [[ ! -f "${ANALYSIS_FILE}" ]];
  then
    echo "File with analysis options does not exist: ${ANALYSIS_FILE}"
    exit -1
fi

SCRIPT_NAME=`head -n1 ${ANALYSIS_FILE}`

#Check if analysis script exists
SCRIPT_PATH=""
if [[ -f "${UKBIO_SCRIPTDIR}/${SCRIPT_NAME}" ]]; then
    SCRIPT_PATH="${UKBIO_SCRIPTDIR}/${SCRIPT_NAME}"
fi

if [[ -f "${SCRIPT_NAME}" ]]; then
    SCRIPT_PATH="${SCRIPT_NAME}"
    exit -1
fi

if [[ "$SCRIPT_PATH" == "" ]]; then
    echo "Analysis script ${SCRIPT_NAME} cannot be found in ${ANALYSIS_DIR} or ${UKBIO_SCRIPTDIR}"
    exit -1
fi

#Setup outputdir
OUTPUT_DIR="${ANALYSIS_DIR}/${ANALYSIS_NAME}/results${RESULT_SUFFIX}"

if [[ ! -d "${OUTPUT_DIR}" ]]; then
    echo "Results dir was not created: ${OUTPUT_DIR}"
    exit -1
fi

#Setup temporary input and output directories
[[ -z $TEMP  ]] && TEMP=/scratch/${USER}/${ANALYSIS_NAME}
mkdir -p "${TEMP}/input"
mkdir -p "${TEMP}/output"
rm -f "${TEMP}/output/*"
rm -f "${TEMP}/input/*"

TEMP_OUTPUT_DIR="${TEMP}/output"

MERGED_SAMPLE_FILE=${TEMP}/input/mergedPhenoData.sample

cp ${ANALYSIS_DIR}/${ANALYSIS_NAME}/mergedPhenoData.sample ${MERGED_SAMPLE_FILE}

for ((i=1; i<=${NPROCS}; i++)) ; do
(

  for ((j=1; j<=${MAX_ITER}; j++)) ; do
    echo "Get next stopos value"
    stopos next -p ${POOL_NAME}
    if [ "$STOPOS_RC" != "OK" ] ; then
      echo "$((${j}-1)) chunks processed by process ${i}"
      break
    fi

    CHUNKFILE="${STOPOS_VALUE}"
    #Check if .bgen chunk exists
    if [[ ! -f "${CHUNKFILE}" ]];
    then
      echo "ERROR: Chunk file does not exist: ${CHUNKFILE}"
      exit -1
    fi
    
    #Copy bgen chunk to scratch
    CHUNK_BASE="${CHUNKFILE##*/}"
    CHUNK_PREFIX="${CHUNK_BASE%%.*}"

    cp ${CHUNKFILE} ${TEMP}/input/${CHUNK_BASE}
    
    #Analyze chunk
    cd ${ANALYSIS_DIR}
    echo "Run: ${SCRIPT_PATH} ${ANALYSIS_FILE} ${MERGED_SAMPLE_FILE} ${TEMP}/input/${CHUNK_BASE} ${TEMP_OUTPUT_DIR}"
    ${SCRIPT_PATH} ${ANALYSIS_FILE} ${MERGED_SAMPLE_FILE} ${TEMP}/input/${CHUNK_BASE} ${TEMP_OUTPUT_DIR}

    cp ${TEMP_OUTPUT_DIR}/*${CHUNK_PREFIX}* ${OUTPUT_DIR}    
    echo $STOPOS_VALUE > ${STOPOS_FILE}_processedchunks/jobid${PBS_JOBID}_process${i}
    echo "Finished processing chunk: ${CHUNK_BASE}"
    stopos remove -p "${POOL_NAME}"
    done
) &
done
wait

#cp ${TEMP_OUTPUT_DIR}/* ${OUTPUT_DIR}
echo "Job finished"

