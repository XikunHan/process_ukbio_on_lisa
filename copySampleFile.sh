#PBS -lwalltime=00:05:00
#!/bin/bash
source scriptSettings.sh

ANALYSIS_FILE=$1


if [[ ! "$#" -eq 1 ]] || [[ "$1" == "help" ]];
  then
    echo "Usage: copySampleFile.sh <analysis-file>"
    echo "The name of <analysis-file> will be used to name the output directory and therefore should be unique"
    echo "Do not use dots in the file name except at the end for the file extension"
    echo "<analysis-file> should be located in your current directory"
    exit 0
fi

if [[ ! -f "${ANALYSIS_FILE}" ]] ;
  then
    echo "Analysis file does not exist: mergeSampleFile.sh <analysis-file>"
    echo "Make sure you run this command in the same directory as the analysis file"
    exit -1
fi



copySampleFile.R ${ANALYSIS_FILE} ${BGEN_SAMPLE_FILE} mergedPhenoData.sample 