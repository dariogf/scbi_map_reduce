#!/usr/bin/env ruby

# load required libraries
require 'scbi_mapreduce'

# in order to load fastq files
require 'scbi_fastq'

# modify include path
$: << File.join(File.dirname(__FILE__),'lib')

require 'find_mids'
include FindMids

# check arguments
if ARGV.count != 2

  puts "Usage #{File.basename($0)} fastq_file chunk"
  puts ""
  puts "#{File.basename($0)} iterates over all sequences in fastq_file (a file in FastQ format) and removes a KNOWN_MID from it"
  exit
end

fastq_file_path=ARGV[0]

if !File.exists?(fastq_file_path)
  puts "Error, #{fastq_file_path} doesn't exists"
  exit
end


# make processing

# open files
@@fastq_file=FastqFile.new(fastq_file_path)
@@results=FastqFile.new('./results2.fastq','w+')

# process
chunk_size=ARGV[1].to_i

# iterate over file
begin
  seqs=[]

  chunk_size.times do
    # read data from file
    name,fasta,qual,comments=@@fastq_file.next_seq
    
    if name.nil?
      break
    end
    seqs<<[name,fasta,qual,comments]

  end

  if !seqs.empty?


    # process it
    find_mid_without_blast(seqs)

    # # find a known MID position
    # pos=fasta.upcase.index(KNOWN_MID)
    #
    # if pos
    #
    #   # keep fasta from pos to end
    #   fasta.slice!(0,pos + KNOWN_MID.length)
    #   # keep qual from pos to end
    #   qual.slice!(0,pos + KNOWN_MID.length)
    #
    # end
    #

    # write data to disk
    seqs.each do |name,fasta,qual,comments|
        @@results.write_seq(name,fasta,qual,comments)
    end

  end

end until seqs.empty?


# close files
@@fastq_file.close
@@results.close
