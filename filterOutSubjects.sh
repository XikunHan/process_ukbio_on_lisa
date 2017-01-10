#PBS -lwalltime=00:15:00
#!/bin/bash
source scriptSettings.sh

OUT_FILE=$1
KINSHIP_THRESH=$2

if [[ "$1" == "help" ]];
  then
    echo "Usage: filterOutSubjects.sh [output-file] [kinship-thresh]"
    echo "[output-file] is the name of the output file containing excluded subjects; defaults to defaultSubjectExclusions.txt"
    echo "[kinship-thresh] is the kinship coefficient threshold used to remove relatedness between subjects (0.5 = genetically identical)"
    echo "Defaults to 0.05"
    exit 0
fi

filterOutSubjects.R ${OUT_FILE} ${KINSHIP_THRESH}