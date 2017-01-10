ukbioCTGscripts version 0.1

A collection of scripts for CTGlab to easily perform (genetic) analysis on the ukbio bank data on the lisa server.

INSTALLATION:
=============
1) Make sure you have sufficient permissions on the ctgukbio account.
To run the scripts of this pipeline you need 'read' and 'execute' permissions on ctgukbio.
Ask the ctgukbio administrator for details.

2) Make variable UKBIO_SCRIPTDIR available on your lisa account and add it
to your PATH by adding the following two lines to your ~/.bashrc file:

export UKBIO_SCRIPTDIR=/home/ctgukbio/programs/ukbioCTGscriptsV0.1
export PATH=$UKBIO_SCRIPTDIR:$PATH

You can now call any executable .sh script from ukbioCTGscriptsV0.1 from any directory on your lisa account as well as on computing nodes. To call .R scripts from the pipeline directory only necessary for debug purposes) first type

source scriptSettings.sh

to set all necssary variables. Otherwise the .R scripts may not run. 

AVAILABLE SCRIPTS:
==================

This section provides and overview of the available scripts. See below for detailed documentation for each script separately.

Notation:
<text>: required argument
[text]: optional argument; if omitted, a default value will be chosen.


extractPhenotypes.sh 
---------------------
Extract specific phenotype columns from the combined ukbio phenotype data available at CTGlab.

Usage on login node: 
extractPhenotypes.sh <phenolist-filename> <output-filename>

Usage on cluster: 
qsub -v PHENOLIST_FILE=<phenolist-filename>,OUTPUT_FILE=<output_filename> ${UKBIO_SCRIPTDIR}/extractPhenotypes.sh <phenolist-filename> <output-filename>


filterOutSubjects.sh
--------------------
Create a default list of UKBIO subject ids that should be excluded in most genetic analyses.

Usage on login node:
filterOutSubjects.sh [output-filename] [kinship-coefficient-threshold]

Usage on cluster:
qsub -v OUT_FILE=[output-filename],KINSHIP_THRESH=[kinship-coefficient-threshold] ${UKBIO_SCRIPTDIR}/filterOutSubjects.sh [output-filename]


startChunkAnalysis.sh
---------------------
Start a specified analysis per chunk. Jobs are automatically started and all chunk outputs are saved in a single folder.

usage on login node: startChunkAnalysis.sh <analysis-filename> [chunk-type]


mergeSNPtestResults.sh
---------------------
Merge snptest output files. This script assumes your are running it in the analysis directory that contains ./results.

Usage on cluster: 
qsub ${UKBIO_SCRIPTDIR}/mergeSNPtestResults.sh

Usage on loginnode: 
processSNPtestResults.sh


FOLLOWING SCRIPTS ARE STILL WORK IN PROGRESS...


filterSNPtestResults.sh
----------------------
Filter snptestresult files on maf and info.

usage on cluster node: qsub -v RESULT_FILE=<snptest-result-file>,MAF_THRESH=<maf-thresh>,INFO_THRESH=<info-thresh> filterSNPtestResults.sh

usage on login node: filterSNPtestResults.sh <snptest-result-file> <maf-thresh> <info-thresh>


createGWASplots.sh
------------------
Create QQ-plot and manhattan plot.

usage on cluster node: qsub -v RESULTFILE=<snptest-result-file> createGWASplots.R

usage on login node: createGWASplots.R <snptest-result-file>


processSNPtestResults.sh
------------------------
Process chunk results from snptest: merge, filter, and plot results.

usage on cluster node: qsub -v RESULTFILE=<snptest-result-file> processSNPtestResults.sh

usage on login node: processSNPtestResults.sh <snptest-result-file>



extractPhenotypes.sh 
==================

Extract specific phenotype columns from the combined ukbio phenotype data available at CTGlab.

Usage on cluster: 

qsub -v PHENOLISTFILE=<phenolist-filename>,OUTFILE=<output-filename> extractPhenotypes.sh

Usage on loginnode: 

extractPhenotypes.sh <phenolist-filename> <output-filename>

Specify UKBIO phenotype codes in a text file (<phenolist-filename>). The requested phenotype variables are saved to a tab-delimited output file (<output-filename>.tab). The header starts with f.eid, containing the UKBIO subject id, followed by phenotypes variables f.<ukbiocode>.<measurement-id>.<value-id>. For example, requesting UKBIO variable code 50 (stainding height), will result in one variable named f.50.0.0. Other UKBIO variables may result in multiple variable containing multiple measurements and/or values. For example, specifying UKBIO code 22009 (UKBIO genetic principal components) results in 15 principal component variables named f.22009.0.1-f.22009.0.15.

In addition an R script file (<output-filename>.R) is created which contains R code to load the file <output-filename>.tab in R and create factors with apropriate value labels for all discrete variables (e.g., female/male instead of 0/1).

The text file <phenolist-filename> should follow the following conventions: 

First column contains a ukbiobank field code number.
In addition it can contain ranges of codes (-), and list of codes (,)

Example lines:
123 #Extract all available variables corresponding to ukbio code 123 (e.g., f.123.0.0 and f.123.1.0)
123-125 #Extract all available variables corresponding to ukbio codes 123 to 125.
123,125 #Extract all available variables corresponding to ukbio codes 123 and 125.

First column should be separated by tabs.
Other (optional) columns may contain arbitrary text such as field descriptions.
The file should not contain a header.

In addition to any phenotypes required for a particular research questions, the following UKBIO field codes can be considered to include for quality control checks or as covariates in downstream genetic analysis:

31      sex (0=female, 1=male)
34      year of birth
21003   age when attended assesment center
21022   age at recruitment
22001   genetic sex; sometimes incongruent with self-reported sex (UKBIO field code 31)
22003   heterozygosity
22004   heterozygosity PCA corrected
22005   missingness percentage per individual
22006   genetic ethnic grouping (1=caucasian, NA=other)
22009   Genetic PCs (f.22009.0.1-f.22009.0.15)
22010   UKBIO recommended genomic analysis exclusions (1=poor heterozygosity/missingness,NA=other)
22011   Genetic relatedness pairing (f.22011.0.0-f.22011.0.4): subject id of second individual of the relatedness pair
22012   Genetic relatedness factor (f.22012.0.0-f.22012.0.4): kinship coefficient (0.5=genetically identical)
22013   Genetic relatedness IBS0 (f.22012.0.0-f.22012.0.4): percentage of genotypes with no shared SNPs.
22050   UKBiLEVE Affymetrix quality control for samples (1 pass, 0 fail)
22051   UKBiLEVE genotype quality control for samples (1 pass, 0 fail)
22052   UKBiLEVE unrelatedness indicator  (1 pass, 0 fail,-1 not tested)


filterOutSubjects.sh
====================
Create a default list of UKBIO subject ids that should be excluded in most genetic analyses.

Usage on login node: 

filterOutSubjects.sh [output-filename] [kinship-coefficient-threshold]

[output-filename] is an optional filename for the output file with UKBIO subjects ids to be excluded. Default name is defaultSubjectExclusions.txt.

[kinship-coefficient-threshold] is an optional threshold for the relatedness that is allowed between pairs. The default threshold is 0.05. Subjects with most relatedness are excluded first, untill no relationship > 0.05 remains. Note that the kinship coefficient is 0.5 (not 1!) if two people are genetically identical.

The output subject id lists contains all subjects that meet one of the following conditions:
- inconsistent self-reported and genetic sex
- non-Caucasian or no genetic data available
- recommended to exclude by UKBIOBANK based on poor heterozygosity and/or individual missingness
- resulting in a kinship coefficient > specified threshold (0.05 by default)
- withdrawn from UKBIO projects


startChunkAnalysis.sh
=====================

Start a specified analysis per chunk, such as a GWAS analysis using snptest. Jobs are automatically started and all chunk outputs are saved in a single subdirectory in the current working directory.


Usage (on loginnode): 

startChunkAnalysis.sh <analysis-filename> [chunk-type]

The output directory structure is:
./<analysis-name>
    /logs                          #contains all job output and error files 
    /results                       #contains .snptestresult files for each processed chunks
    chunk_names.stopos             #filenames of chunks to process     
    chunk_names.stopos.processed   #filenames of processed chunks
    mergedPhenoData.sample         #the merged phenotype data for your reference

<analysis-file> contains all options/details of the analysis to run. The optional parameter [chunk-type]  determines the chunk directory that is used. Chunk type should be one value out of [bgen,bgentest]. By default bgen is assumed. The value bgentest is meant for quick testing of analysis scripts and uses a chunk directory with two very small chunks for test purposes.

An example <analysis-file> to perform a snptest analysis per chunk: is

runSNPtestOnChunk.R
phenoFile:=phenotypes.txt
subjectExclusionFile:=excludeSubjects.txt 
method:=score
frequentist:=1
pheno:=f.50.0.0
cov_names:=f.22001.0.0 f.22009.0.1

This analysis file results in the following snptest call for all .bgen chunks:
snptest -data <chunk-prefix>.bgen <sample-file> -o <chunk-prefix>.snptestresult -method score -frequentist 1 -pheno f.50.0.0 -cov_names f.22001.0.0 f.22009.0.1

See the documentation of runSNPtestOnChunk.R for more details performing a snptest analysis. In principle any script <script-name> can be applied to all chunks using startChunkAnalysis.sh as long as these conventions are followed when creating the script:

1) <analysis-file> should start with <script-name>, the filename of the script to be applied, not the file path.
<script-name> should be located either in the current working directory or in <ukbio-scriptdir>.

2) <script-name> should start with

#!/path/to/program/to/interpret/the/script

Typically this will be somtehing like #!/bin/bash for .sh scripts and #!/sara/sw/R-3.2.1/bin/Rscript
 for R scripts.

3) <script-name> should be made executable with 

chmod u+x <script-name>

4) The following command with exactly four arguments should process a single .bgen chunk:

/path/to/<script-name> <analysis-file> <sample-file> <chunk-prefix>.bgen <chunk-output-prefix>

5) Any further lines in <analysis-file> are assumed to be options that <script-name> can process.
No restrictions apply to the format of these analysis options, as long as <script-name> can understand them.

mergeSNPtestResults.sh
========================

Merge snptest output files. This script assumes your are running it in the analysis directory that contains ./results.

Usage on cluster: 

qsub mergeSNPtestResults.sh

Usage on loginnode: 

processSNPtestResults.sh