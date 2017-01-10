#PBS -lwalltime=00:05:00
#!/bin/bash
source scriptSettings.sh

ANALYSIS_FILE=$1



if [[ "$#" -gt 1 ]] || [[ "$1" == "help" ]];
  then
    echo "Usage: estimateHeritabilityREML.sh <h2REML-analysis-file>"
    echo "Do not use dots in the file name except at the end for the file extension"
    echo "<h2REML-analysis-file> should be located in your current directory and"
    exit 0
fi

if [[ ! -f "${ANALYSIS_FILE}" ]] ;
  then
    echo "Analysis file ${ANALYSIS_FILE} does not exist..."
    echo "Make sure you run this command in the same directory as the analysis file"
    exit -1
fi

Rscript ${UKBIO_SCRIPTDIR}/estimateHeritabilityREML.R ${ANALYSIS_FILE}
