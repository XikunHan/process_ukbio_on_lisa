#!/sara/sw/R-3.2.1/bin/Rscript
source(file.path(Sys.getenv("UKBIO_SCRIPTDIR"),"scriptSettings.R"))

# Saves a list of all subject IDs that are:
#1) discordant for self-reported and genetic sex
#2) non-causcasian (includes subjects with no genetic data)
#3) recommended by UKBIO to exclude due to poor heterozygosity/missingness
#4) withdrawn from UKBIO project
#5) related > specified kinship coefficient threshold


#File name of output file with subject IDs to exclude
outFile <- args[1]
#Kinship coefficient threshold when removing relatedness among subjects (0.5 clone,0.25 sibling,etc) 
kinshipThresh <- args[2]

#Default output filename
if (is.na(outFile)){
  outFile <- "defaultSubjectExclusions.txt"
}


#Default threshold 
if (is.na(kinshipThresh)){
  kinshipThresh <- 0.05  
}


#Create default
message("Extract exclusion variables...")

cmd <- "cat << 'EOF' > exclusionVarList.temp
31\tsex (0=female, 1=male)
34\tyear of birth
21003\tage when attended assesment center
21022\tage at recruitment
22001\tgenetic sex; sometimes incongruent with self-reported sex (UKBIO field code 31)
22003\theterozygosity
22004\theterozygosity PCA corrected
22005\tmissingness percentage per individual
22006\tgenetic ethnic grouping (1=caucasian, NA=other)
22009\tGenetic PCs (f.2209.0.1-f.2209.0.15)
22010\tUKBIO recommended genomic analysis exclusions (1=poor heterozygosity/missingness,NA=other)
22011\tGenetic relatedness pairing (f.22011.0.0-f.22011.0.4): subject id of second individual of the relatedness pair
22012\tGenetic relatedness factor (f.22012.0.0-f.22012.0.4): kinship coefficient (0.5=genetically identical)
22013\tGenetic relatedness IBS0 (f.22012.0.0-f.22012.0.4): percentage of genotypes with no shared SNPs.
22050\tUKBiLEVE Affymetrix quality control for samples (1 pass, 0 fail)
22051\tUKBiLEVE genotype quality control for samples (1 pass, 0 fail)
22052\tUKBiLEVE unrelatedness indicator  (1 pass, 0 fail,-1 not tested)
EOF"
system(cmd)

cmd <- "extractPhenotypes.sh exclusionVarList.temp defaultExclusionVars.txt"
system(cmd)

phenotypeRFile <- file.path(".","defaultExclusionVars.txt.R")

message("Creating list of exlusion subjects...")
message("output file: ", outFile)
message("Kinship coefficient threshold applied: ", kinshipThresh)

#User settings#

stopifnot(!is.na(outFile))

# UKBIO variables used for exclusion criteria
#f.eid: subject id
#f.31.0.0: self-reported sex
#f.22001.0.0: genetic sex 
#f.22006.0.0: ethnicity (1=caucasian)
#f.22010.0.0: recommended genomic analysis exclussions (1=poor heterzygosity/missing)
#f.22011.0.0-4: genetic relatedness pairing (if any)
#f.22012.0.0-4: genetic relatedness factor (estimated kinship coefficient [approx 0.5 x values in GRM matrix])
requiredVariables <- c("f.eid","f.31.0.0","f.22001.0.0","f.22006.0.0","f.22010.0.0",
  paste0("f.22011.0.",0:4),
  paste0("f.22012.0.",0:4))

stopifnot(file.exists(phenotypeRFile))

message("Load phenotype data..")

source(phenotypeRFile)

bd <- data.table(bd)
stopifnot(all(requiredVariables %in% names(bd)))

#Remove subjects that have inconsistent self-reported and genetic sex

message("Filter out subjects with inconsistent self-reported and genetic sex...")
inconsistentSexIds <- bd[f.31.0.0!=f.22001.0.0,f.eid]
message(paste(length(inconsistentSexIds),"subjects with inconsistent sex removed"))

message("Filter out non-caucasians and subjects with no genetic data...")
nonCaucasian <- bd[is.na(f.22006.0.0) |f.22006.0.0!="Caucasian",f.eid] #includes people with no genetic data
message(paste(length(nonCaucasian),"non-caucasians or people with no genetic data removed"))

message("Filter out poor heterozygosity or missingness..")
ukbioExclusion <-  bd[f.22010.0.0=="poor heterozygosity/missingness",f.eid] #recommende exclusions by UKBIO
message(paste(length(ukbioExclusion),"subjects with poor heterozygosity or missingness removed"))

message("Filter out withdrawn subjects...")
withdrawnSubjects <- fread(Sys.getenv("WITHDRAWNSUBJECT_FILE"))[[1]]
message(paste(length(withdrawnSubjects),"withdrawn subjects removed"))

#Remove relationship > kinship coefficient threshold
message("Filter out related subjects...")

nrOfRelations <- rowSums(with(bd,cbind(!is.na(f.22011.0.0),!is.na(f.22011.0.1),!is.na(f.22011.0.2),!is.na(f.22011.0.3),!is.na(f.22011.0.4))))

maxRel <- apply(with(bd,cbind(f.22012.0.0,f.22012.0.1,f.22012.0.2,f.22012.0.3,f.22012.0.4)),1,max,na.rm=T)

bd[,nrOfRelations:=nrOfRelations]
bd[,maxRel:=maxRel]
setorder(bd,-nrOfRelations,-maxRel)
relatedSubjectIDs <- bd[nrOfRelations>0,f.eid]
relativeExclusions <- c()
#For each person
for (id in relatedSubjectIDs){
  #If focus subject is not previously excluded, check if its relations are all excluded.
  #If not, exclude focus subject
  if(!(id %in% relativeExclusions)){
    relatives <- na.omit(unlist(bd[f.eid==id,.(f.22011.0.0,f.22011.0.1,f.22011.0.2,f.22011.0.3,f.22011.0.4)]))
    kinship <- na.omit(unlist(bd[f.eid==id,.(f.22012.0.0,f.22012.0.1,f.22012.0.2,f.22012.0.3,f.22012.0.4)]))
    if(!all(relatives[kinship>kinshipThresh] %in% relativeExclusions)){
      #add focus subject
      relativeExclusions <- c(id,relativeExclusions)
    }
    
  }
}
message(paste(length(relativeExclusions),"related subjects"))

#Check that all remaining subjects are unrelated
stopifnot(mean(bd[, is.na(f.22011.0.0) | f.22011.0.0 %in% relativeExclusions | f.eid %in% relativeExclusions | f.22012.0.0<= kinshipThresh])==1)
stopifnot(mean(bd[, is.na(f.22011.0.1) | f.22011.0.1 %in% relativeExclusions | f.eid %in% relativeExclusions | f.22012.0.1<= kinshipThresh])==1)
stopifnot(mean(bd[, is.na(f.22011.0.2) | f.22011.0.2 %in% relativeExclusions | f.eid %in% relativeExclusions | f.22012.0.2<= kinshipThresh])==1)
stopifnot(mean(bd[, is.na(f.22011.0.3) | f.22011.0.3 %in% relativeExclusions | f.eid %in% relativeExclusions | f.22012.0.3<= kinshipThresh])==1)
stopifnot(mean(bd[, is.na(f.22011.0.4) | f.22011.0.4 %in% relativeExclusions | f.eid %in% relativeExclusions | f.22012.0.4<= kinshipThresh])==1)


excludedSubjects <- unique(c(inconsistentSexIds,nonCaucasian,ukbioExclusion,withdrawnSubjects,relativeExclusions))
message(length(excludedSubjects)," subjects filtered out")
message(nrow(bd)-length(excludedSubjects)," subjects remain")
message("write to ",outFile)
write.table(excludedSubjects,file=outFile,row.names=F,col.names=F,quote=F)

message("Remove temporary files...")
cmd <- "rm exclusionVarList.temp; rm defaultExclusionVars.txt; rm defaultExclusionVars.txt.R"
system(cmd)
message("Done")
