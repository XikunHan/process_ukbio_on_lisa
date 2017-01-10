#!/bin/bash

#Throw away lines in DATAFILE for which the first column has a value in FILTERLIST and save result in OUTPUTFILE
#Assumes tab delimited file

#Check number of parameters
if [[ ! "$#" -eq 3 ]]; then
    echo "Please provide 3 parameters: FILTERLIST DATAFILE OUTPUTFILE"
    exit -1
fi

FILTERLIST=$1
DATAFILE=$2
OUTPUTFILE=$3

#Check existence of filter and data file
if [[ ! -f "${FILTERLIST}" ]];
  then
    echo "File with filter values does not exist: ${FILTERLIST}"
    exit -1
fi

if [[ ! -f "${DATAFILE}" ]];
  then
    echo "Data file does not exist: ${DATAFILE}"
    exit -1
fi

awk 'BEGIN {
while (getline < "'"$FILTERLIST"'")
{
withdrawn[$1]=$1;
}
close("'"$INPUTFILE"'");
}
NR==1 || !($1 in withdrawn) {print $0}' "${DATAFILE}" > "${OUTPUTFILE}"