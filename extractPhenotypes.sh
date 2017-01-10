#PBS -lwalltime=00:05:00
                         # 2 hours wall-clock
                         # time allowed for this job
#PBS -lnodes=1
                         # 1 node for this job
#PBS -S /bin/bash
source scriptSettings.sh

helpString="Usage: extractPhenotypes.sh <phenotype-code-list> <output-file-name>\n
  Extracts specific phenotype columns\n
  from total ukbio phenotype file as specified\n
  in tab-delimited text file <pheno-code-list>\n
  First column should contain field number or range (-)\n
  Example values: \n
  \n
  123\n
  123-125\n
 \n
 one ukbiobank field number per row\n
 first column should be separated by tabs\n
 from optional consecutive columns (e.g., field description)\n
 \n
 Usage on cluster: qsub -v PHENOLIST_FILE=<phenotype-code-list>,OUT_FILE=<output-file-name> extractPhenotypes.sh"

if [[ "$#" -eq 2 ]];
  then
    PHENOLIST_FILE=$1
    OUTPUT_FILE=$2
fi

if [[ "${1}" == "help" ]];
  then
    echo -e $helpString
    exit 0
fi

if [[ "${PHENOLIST_FILE}" == "" || "${OUTPUT_FILE}" == "" ]];
  then
    echo -e $helpString
    exit -1
fi

#Check if pheno code list exists
if [[ ! -f "${PHENOLIST_FILE}" ]];
  then
    echo "File with UKBIO phenotype codes does not exist: ${PHENOLIST_FILE}"
    exit -1
fi


#Extract phenotypes using R

Rscript ${UKBIO_SCRIPTDIR}/extractPhenotypes.R ${PHENOLIST_FILE} ${WITHDRAWNSUBJECT_FILE} ${PHENOTYPE_FILE} ${OUTPUT_FILE}