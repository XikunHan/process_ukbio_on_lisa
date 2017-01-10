module BgenHandler

export createIndexFile, extractChunk, readBgenHeader

###########################
### HEADER related code ###
###########################

type Header
	offset::Int64
	length::Int64
	m::Int64
	n::Int64
	mbyte1::Char
	mbyte2::Char
	mbyte3::Char
	mbyte4::Char
	flags::Array{UInt8,1}
	freeData::Array{UInt8,1}
end

Header() = Header(Int64(100),Int64(100),Int64(0),Int64(0),'b','g','e','n',UInt8[0x05,0x00,0x00,0x00],Array{UInt8,1}(100-20))

function Base.show(io::IOStream,header::Header)
	str = """Offset: $(header.offset)
	Header length: $(header.length)
	Nr of SNPs: $(header.m)
	Nr of samples: $(header.n)
	Magic byte1: $(header.mbyte1)
	Magic byte2: $(header.mbyte2)
	Magic byte3: $(header.mbyte3)
	Magic byte4: $(header.mbyte4)
	Free data bytes: $(header.freeData)
	Flag bytes: $(header.flags)"""
	Base.show(io,str)
end

function readHeader(io::IOStream)
	header = Header()

	#Read offset
	header.offset = Int64(read(io, UInt32))

	### HEADER ###

	#Read length header
	header.length = Int64(read(io, UInt32))

	#Read number of variants
	header.m = Int64(read(io, UInt32))

	#Read number of samples
	header.n = Int64(read(io, UInt32))

	#Read magic bytes
	header.mbyte1 = read(io, Char)
	header.mbyte2 = read(io, Char)
	header.mbyte3 = read(io, Char)
	header.mbyte4 = read(io, Char)

	#Check if magic bytes are correct
	if !((header.mbyte1=='b' || header.mbyte1=='\0') && (header.mbyte2=='g' || header.mbyte1=='\0')  &&  (header.mbyte3=='e' || header.mbyte1=='\0')  && (header.mbyte4=='n' || header.mbyte1=='\0') )
		println("Magic bytes are not 'bgen'! Not a valid .bgen v1.1 file.")
		println("length:",header.length)
		println("nr of snps:",header.m)
		println("nr of subjects:",header.n)
		println("mbyte1: ",header.mbyte1)
		println("mbyte2: ",header.mbyte2)
		println("mbyte3: ",header.mbyte3)
		println("mbyte4: ",header.mbyte4)
		close(io)
		exit(-1)
	end

	#Read free data (currently ignored)
	header.freeData = readbytes(io, header.length-20)

	#Read flags
	header.flags = readbytes(io, 4) 

	isCompressed = (header.flags[1] & 0b0001) != 0
	isv1_1 = (header.flags[1] & 0b0100) != 0 && (header.flags[1] & 0b1010) == 0 && (header.flags[2] & 0b1111) == 0

	#Check if v1.1 and compressed
	if !(isCompressed && isv1_1)
		println("Only compressed v.1.1 .bgen files are currently supported!")
		close(io)
		exit(-1)
	end

	return header
end



function writeHeader(destFileName::ASCIIString,header::Header,nrOfSnps::Int)
	outFile = open(destFileName,"w")
	write(outFile,UInt32(header.offset),UInt32(header.length),
		UInt32(nrOfSnps), UInt32(header.n),
		header.mbyte1, header.mbyte2, header.mbyte3, header.mbyte4,
		header.freeData, header.flags)
	close(outFile)
end



###########################
### SNP meta data related code ###
###########################


#SNP meta data
type SnpMetaData
	n::Int64
	lengthSnpId::Int64
	snpId::ASCIIString
	lengthRsId::Int32
	rsId::ASCIIString
	lengthChr::Int32
	chrom::ASCIIString
	snpPos::Int64
	lengthA1::Int64
	allele1::ASCIIString
	lengthA2::Int64
	allele2::ASCIIString
	snpDataLength::Int64
	startOffset::Int64
	totalLength::Int64
end




SnpMetaData() = SnpMetaData(Int64(0),
		Int32(0),
		"",
		Int32(0),
		"",
		Int32(0),
		"",
		Int64(0),
		Int64(0),
		"",
		Int64(0),
		"",
		Int64(0),
		Int64(0),
		Int64(0))

function Base.show(io::IOStream,metaData::SnpMetaData)
	str = """
	Nr of subjects: $(metaData.n)
	Length SNP ID: $(metaData.lengthSnpId)
	SNP ID: $(metaData.snpId)
	Length rsID: $(metaData.lengthRsId)
	rsID: $(metaData.rsId)
	length Chrom label: $(metaData.lengthChr)
	Chromosome label: $(metaData.chrom)
	SNP position: $(metaData.snpPos)
	length A1: $(metaData.lengthA1)
	Allele 1: $(metaData.allele1)
	length A2: $(metaData.lengthA2)
	Allele 2: $(metaData.allele2)
	Length compressed SNP data block: $(metaData.snpDataLength)"""
	Base.show(io,str)
end


function readSnpMetaData(io)
	metaData = SnpMetaData()
	metaData.startOffset = Int64(position(io))
	metaData.n = Int64(read(io, UInt32))
	metaData.lengthSnpId = Int32(read(io, UInt16))
	metaData.snpId = ASCIIString(readbytes(io, metaData.lengthSnpId))
	metaData.lengthRsId = Int32(read(io, UInt16))
	metaData.rsId = ASCIIString(readbytes(io, metaData.lengthRsId))
	metaData.lengthChr = Int32(read(io, UInt16))
	metaData.chrom = readChromosomeLable(ASCIIString(readbytes(io, metaData.lengthChr)))
	metaData.snpPos = Int64(read(io, UInt32))
	metaData.lengthA1 = Int64(read(io, UInt32))
	metaData.allele1 = ASCIIString(readbytes(io, metaData.lengthA1))
	metaData.lengthA2 = Int64(read(io, UInt32))
	metaData.allele2 = ASCIIString(readbytes(io, metaData.lengthA2))
	metaData.snpDataLength = Int64(read(io, UInt32))
	skip(io, metaData.snpDataLength)
	metaData.totalLength = Int64(position(io)-metaData.startOffset)
	return metaData
end

function readChromosomeLable(lable::ASCIIString)
	result = try 
		"$(parse(Int,lable))"
	catch
		lable
	end
	return result
end

function writeSnpToIndex(io::IOStream,metaData::SnpMetaData,sep="\t")
	write(io,join((metaData.chrom, metaData.snpPos, 
		metaData.snpId, metaData.rsId, 
		metaData.allele1,metaData.allele2, 
		metaData.startOffset, metaData.totalLength), sep), "\n")
end


function copySnpDataChunk(sourceFileName::ASCIIString,destFileName::ASCIIString,skipBytes::Int64,nrOfBytes::Int64)
	run(`/home/ctgukbio/programs/bgentools/appendChunk.sh $(sourceFileName) $(destFileName) $(skipBytes) $(nrOfBytes)`)
end



#####################
### Exported files ##
#####################
""" 
	readBgenHeader(fileName::ASCIIString)

Read header from .bgen file (returns Bgen Header object)
"""
function readBgenHeader(fileName::ASCIIString)
	outFile = open(fileName)
	header = readHeader(outFile)
	close(outFile)
	return header
end

"""
	extractChunk(sourceFileName::ASCIIString,destFileName::ASCIIString,nrOfSnps::Int,skipBytes::Int64,nrOfBytes::Int64)

Extract a chunk of SNPs from  .bgen/.snp source files and copy to destination .bgen/.snp files.

fromSnp to toSnp provide the range of SNPs to extract (1-based .i.e. 1-10 mean from the first SNP in the
	file to the 10th SNP in the file, including the latter).
The results is a valid .bgen file including the same header as the source file,
but with the correct number of SNPs present in the destination file.
"""
function extractChunk(sourceFileName::ASCIIString,destFileName::ASCIIString,fromSnp::Int,toSnp::Int)
	nrOfSnps = toSnp-fromSnp+1
	println("Read header...")
	header = readBgenHeader("$(sourceFileName).bgen")
	println("Read SNP index...")
	index = readdlm("$(sourceFileName).snp",'\t',Any,'\n',skipstart=fromSnp-1,quotes=false)[1:nrOfSnps,:]

	offsetCol = 7
	byteLengthCol = 8
	skipBytes = index[1,offsetCol]
	nrOfBytes = index[nrOfSnps,offsetCol] + index[nrOfSnps,byteLengthCol] - skipBytes
	println("Write header...")	
	writeHeader("$(destFileName).bgen",header,nrOfSnps)
	println("Copy chunk to $(destFileName).bgen...")
	copySnpDataChunk("$(sourceFileName).bgen","$(destFileName).bgen",skipBytes,nrOfBytes)
	println("Create index file...")
	createIndexFile("$(destFileName).bgen","$(destFileName).snp")
end

"""
	createIndexFile(bgenFileName::ASCIIString,snpFileName::ASCIIString)

Create an index file (snpFileName) from a .bgen file.

The index file contains one line per SNP with information about chromosome,
position, SNPID, rsID, startposition in bytes (0-based), and total number of bytes.
"""
function createIndexFile(bgenFileName::ASCIIString,snpFileName::ASCIIString)
	#Write Index file
	inFile = open(bgenFileName)
	indexFile = open(snpFileName,"w")

	header = readHeader(inFile)

	#Write Snps to index file
	i = 0
	while(!eof(inFile))
		snpMetaData = readSnpMetaData(inFile)
		writeSnpToIndex(indexFile,snpMetaData)
		i +=1
		if (i % 100000 == 0)
			println("SNP ",i)
		end
	end
	close(inFile)
	close(indexFile)
end


end
