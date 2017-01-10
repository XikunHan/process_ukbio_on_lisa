#PBS -l walltime=02:00:00
#!/bin/bash
source scriptSettings.sh

helpString="
usage: createGWASplots.sh <snptest-resultfile> <output-prefix>\n
       <gwas-resultfile> is the file name of the snptest result file (with extension) \n
       <output-prefix> is the file prefix used to name the output plots\n
       If you need more options to control plotting, copy createGWASplots.sh and createGWASplots.R to your own account and adjust accordingly\n
"

if [[ $1 == "help" ]]; then
        echo -e $helpString
        exit 0
fi

if [[ "$PBS_O_WORKDIR" == "" ]]; then
  GWAS_RESULTFILE=$1
  OUTPUT_PREFIX=$2
fi

if [[ ! -f "${GWAS_RESULTFILE}" ]]; then
	echo "ERROR: GWAS result file does not exist: ${GWAS_RESULTFILE}"
	echo "$helpString"
        exit -1
fi

if [[ "${OUTPUT_PREFIX}" == "" ]]; then
	echo "ERROR: no output prefix specified"
        echo "$helpString"
	exit -1
fi


createGWASplots.R $GWAS_RESULTFILE $OUTPUT_PREFIX
