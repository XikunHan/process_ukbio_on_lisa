#!/bin/bash

#Script settings to be sourced in each bash shell.
echo "Load UKBIO CTG script settings..."

#Load R 
module load R/3.2.1
module load snptest/2.5.0
module load plink2
module load stopos

#Utility programs

export BOLTREML_PATH="/home/ctgukbio/programs/BOLT-LMM_v2.2/bolt"
export MAGMA_PATH="/home/ctgukbio/programs/magma_v1.04/magma"
export FLASHPCA_PATH="/home/ctgukbio/programs/flashpca_v1.2.5/flashpca"
export PCGC_PATH="/home/ctgukbio/programs/java-pcgc_24Oct2015/PCGCRegression.jar"


#File with ukbio phenotype file (combined releases)
export UKBIOAPPLICATION_DIR="/home/ctgukbio/datasets/ukbio/applicationID1640"
export PHENOTYPE_DIR="${UKBIOAPPLICATION_DIR}/qc/final/phenotypes/combined"
export PHENOTYPE_PREFIX="combined"
export PHENOTYPE_FILE="${PHENOTYPE_DIR}/${PHENOTYPE_PREFIX}_phenotypes"

#File with UKBIO withdrawn subjects
export WITHDRAWNSUBJECT_FILE="${PHENOTYPE_DIR}/withdrawnsubjects.txt"


#Genotype files
export GENOTYPE_DIR="${UKBIOAPPLICATION_DIR}/qc/final/genotypes"

#Directory with imputed chunks
export BGEN_CHUNK_DIR="${GENOTYPE_DIR}/bgen_chunks_SNPsubset_info0_3_maf0_0001"

export BGEN_TESTCHUNK_DIR="${GENOTYPE_DIR}/bgen_testchunks"

export PLINK_CHUNK_DIR="${GENOTYPE_DIR}/plink_chunks_info0_8_eur_geno0.25_maf0.0001"

export PLINK_TESTCHUNK_DIR="${GENOTYPE_DIR}/plink_testchunks"

#UKBIO BGEN sample file
export BGEN_SAMPLE_DIR="${UKBIOAPPLICATION_DIR}/qc/final/phenotypes/combined"
export BGEN_SAMPLE_PREFIX="impv1"
export BGEN_SAMPLE_FILE="${BGEN_SAMPLE_DIR}/${BGEN_SAMPLE_PREFIX}.sample"


#merge of bgen chunks
#Variant ids with duplicate chr:pos:A1:A1 combinatations or duplicate SNPids were removed
#Also an info threshold >0.8 is applied (using info stats computed prior to subject filtering)
export PLINK_MERGE_DIRNAME="${GENOTYPE_DIR}/plink_merge_info0_8_eur"
export PLINK_MERGE_FILENAME="mergedChunksInfo0_8removedDuplEUR"
export PLINK_MERGE_DIR="${GENOTYPE_DIR}/plink_merge_info0_8_eur"
export PLINK_MERGE_FILE="${PLINK_MERGE_DIR}/${PLINK_MERGE_FILENAME}"

export PLINK_MERGE_1K_DIRNAME="plink_merge_info0_8_eur_1k"
export PLINK_MERGE_1K_FILENAME="UKB1k"
export PLINK_MERGE_1K_DIR="${GENOTYPE_DIR}/${PLINK_MERGE_1K_DIRNAME}"
export PLINK_MERGE_1K_FILE="${PLINK_MERGE_1K_DIR}/${PLINK_MERGE_1K_FILENAME}"

export PLINK_MERGE_10K_DIRNAME="plink_merge_info0_8_eur_10k"
export PLINK_MERGE_10K_FILENAME="UKB10k"
export PLINK_MERGE_10K_DIR="${GENOTYPE_DIR}/${PLINK_MERGE_10K_DIRNAME}"
export PLINK_MERGE_10K_FILE="${PLINK_MERGE_10K_DIR}/${PLINK_MERGE_10K_FILENAME}"

export PLINK_MERGE_COMMON_PRUNED_DIRNAME="plink_merge_info0_8_eur_geno0.01_maf0.01_pruned"
export PLINK_MERGE_COMMON_PRUNED_FILENAME="plink_merge_info0_8_eur_geno0.01_maf0.01_pruned"
export PLINK_MERGE_COMMON_PRUNED_DIR="${GENOTYPE_DIR}/${PLINK_MERGE_COMMON_PRUNED_DIRNAME}"
export PLINK_MERGE_COMMON_PRUNED_FILE="${PLINK_MERGE_COMMON_PRUNED_DIR}/${PLINK_MERGE_COMMON_PRUNED_FILENAME}"




#Default R repository
export DEFAULT_R_REPOS="http://cran.rstudio.com/"

[[ -z $TEMP  ]] && export TEMP=/scratch/${USER}/${ANALYSIS_NAME}


############
###CHECKS###
############

#Check if withdrawn subject file exists
if [[ ! -f "${WITHDRAWNSUBJECT_FILE}" ]]; then
    echo "File with withdrawn subjects does not exist: ${WITHDRAWNSUBJECT_FILE}"
    exit -1
fi

#Check if phenotype .tab file exists
if [[ ! -f "${PHENOTYPE_FILE}.tab" ]];
  then
    echo "Combined phenotype file does not exist: ${PHENOTYPE_FILE}.tab"
    exit -1
fi

#Check if phenotype R file exists
if [[ ! -f "${PHENOTYPE_FILE}.r" ]];
  then
    echo "Combined phenotype R file does not exist: ${PHENOTYPE_FILE}.r"
    exit -1
fi

#Check if extractPhenotypes.sh exists
if [[ ! -f "${UKBIO_SCRIPTDIR}/extractPhenotypes.sh" ]];
  then
    echo "extract phenotype script does not exist: ${UKBIO_SCRIPTDIR}/extractPhenotypes.sh"
    exit -1
fi


#Check if bgen sample file exists
if [[ ! -f "${BGEN_SAMPLE_FILE}" ]]; then
    echo "UKBIO file with sample ids does not exist: ${BGEN_SAMPLE_FILE}"
    exit -1
fi


#Check if analyzeChunksJob.sh exists
if [[ ! -f "${UKBIO_SCRIPTDIR}/analyzeChunksJob.sh" ]]; then
    echo "chunk analysis job script analyzeChunksJob.sh does not exist: ${UKBIO_SCRIPTDIR}/analyzeChunksJob.sh"
    exit -1
fi

#Check if mergeSampleFile.sh exists
if [[ ! -f "${UKBIO_SCRIPTDIR}/mergeSampleFile.sh" ]]; then
    echo "mergeSampleFile.sh does not exist: ${UKBIO_SCRIPTDIR}/mergeSampleFile.sh"
    exit -1
fi

#Set ANALYSIS as directory from which this script is called
ANALYSIS_DIR="$PBS_O_WORKDIR"
if [[ "$ANALYSIS_DIR" == "" ]]; then
  ANALYSIS_DIR=`pwd`    
fi

cd ${ANALYSIS_DIR}


echo "Settings OK"
