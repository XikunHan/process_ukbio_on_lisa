using BgenHandler

#Open file
if length(ARGS)==0
	inputFilePrefix = "test"
	#outputFileName = "test.bgen.snp"
else
	inputFilePrefix = ARGS[1]
	#outputFileName = "$(ARGS[1]).snp"
end

createIndexFile("$(inputFilePrefix).bgen","$(inputFilePrefix).snp")


#Write chunk header
#chunkFileName = "test.chunk"
#nrOfSnps = 50
#writeHeader(chunkFileName,header,nrOfSnps)



#snpIndex = readdlm("test.snp",'\t')