#!/usr/bin/env ruby

$: << File.dirname(__FILE__)

# load required libraries
require 'scbi_mapreduce'

require 'scbi_fastq' #to load fastq files
require 'my_worker_manager.rb'

# check arguments
if ARGV.count != 3
  puts "Usage #{File.basename($0)} fastq_file workers chunk_size"
  puts ""
  puts "#{File.basename($0)} iterates over all sequences in fastq_file (a file in FastQ format) and removes a MID (barcode) from it"  
  exit
end

fastq_file_path=ARGV.shift

if !File.exists?(fastq_file_path)
  puts "Error, #{fastq_file_path} doesn't exists"
  exit
end 

# listen on ip starting with 10.243 at first available port
server_ip='10.243'
port = 0

# set number of workers. You can also provide an array with worker names.
# Those workers names can be read from a file produced by the existing
# queue system, if any.
workers = 4

# read optional workers parameter
input_workers = ARGV.shift
if !input_workers.nil?
  if File.exists?(input_workers) # if it is a file
    # read workers into array
    workers=File.read(input_workers).split("\n").map{|w| w.chomp}
  else
    # workers is a number
    workers = input_workers.to_i
  end
end

# read chunk size from args
chunk_size = ARGV.shift.to_i

# we need the path to my_worker in order to launch it when necessary
custom_worker_file = File.join(File.dirname(__FILE__),'my_worker.rb')

# initialize the work manager. Here you can pass parameters like file names
MyWorkerManager.init_work_manager(fastq_file_path)

# launch processor server
mgr = ScbiMapreduce::Manager.new(server_ip, port, workers, MyWorkerManager, custom_worker_file, STDOUT,'~seqtrimnext/init_env')

# you can set additional properties
# =================================

# if you want basic checkpointing. Some performance drop should be expected
# mgr.checkpointing=true

# if you want to keep the order of input data. Some performance drop should be expected
# mgr.keep_order=true

# you can set the size of packets of data sent to workers
mgr.chunk_size=chunk_size

# start processing
mgr.start_server

# this line is reached when all data has been processed
puts "Program finished"
