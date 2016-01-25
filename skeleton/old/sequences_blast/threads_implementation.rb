#!/usr/bin/env ruby

# load required libraries
require 'scbi_mapreduce'

# in order to load fastq files
# require 'scbi_fastq'

# modify include path
$: << File.join(File.dirname(__FILE__),'lib')

require 'thread_pool'

# require 'find_mids'
# include FindMids

# check arguments
# if ARGV.count != 1
# 
#   puts "Usage #{File.basename($0)} fastq_file"
#   puts ""
#   puts "#{File.basename($0)} iterates over all sequences in fastq_file (a file in FastQ format) and removes a KNOWN_MID from it"
#   exit
# end
# 
# fastq_file_path=ARGV[0]
# 
# if !File.exists?(fastq_file_path)
#   puts "Error, #{fastq_file_path} doesn't exists"
#   exit
# end
# 
# 
# # make processing
# 
# # open files
# @@fastq_file=FastqFile.new(fastq_file_path)
# @@results=FastqFile.new('./results3.fastq','w+')

@pool=ThreadPool.new(2)


def do_dummy_calculation
  numer_of_calcs=250000

  t=Time.now

  x1=1
  x2=1

  # do a loop with calculations
  numer_of_calcs.times do |i|
    x=x1+x2

    x1=x2
    x2=x

    # puts some info at regular intervals
    if (i % 100000)==0
      puts "Calculated #{i} by thread #{n}"
    end
  end
  puts Time.now-t

end


# process

# iterate over file
begin
  
  seqs=[]
  times_to_calculate=8

  times_to_calculate.times do
    # read data from file
    name,fasta,qual,comments=@@fastq_file.next_seq
    
    if name.nil?
      break
    end
    seqs<<[name,fasta,qual,comments]
  end

  if !seqs.empty?
    # puts "NEW"
    # process it
    @pool.process {do_dummy_calculations}
    # @pool.process {x=0; 1000000000000.times do x+=1 end}
    
    
    # # write data to disk
    # seqs.each do |name,fasta,qual,comments|
    #     @@results.write_seq(name,fasta,qual,comments)
    # end

  end

end until seqs.empty?

puts "wait"
@pool.join
puts "final"

# close files
@@fastq_file.close
@@results.close
