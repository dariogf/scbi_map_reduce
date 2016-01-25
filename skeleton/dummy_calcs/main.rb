#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__))

# load required libraries
require 'scbi_mapreduce'
require 'my_worker_manager'

# listen on all ips at port 50000
server_ip='10.243'
ip_list = Socket.ip_address_list.select{|e| e.ipv4?}.map{|e| e.ip_address}

ip=ip_list.select{|ip| ip.index(server_ip)==0}.first

if !ip
  ip='0.0.0.0'
end

port = 0

# set number of workers. You can also provide an array with worker names.
# Those workers names can be read from a file produced by the existing
# queue system, if any.



workers = 4

# read optional workers parameter
input_workers = ARGV.shift
if !input_workers.nil?
  # if it is a file
  if File.exists?(input_workers)
    # read workers into array
    workers=File.read(input_workers).split("\n").map{|w| w.chomp}
  else
    # workers is a number
    workers = input_workers.to_i
  end
end

# we need the path to my_worker in order to launch it when necessary
custom_worker_file = File.join(File.dirname(__FILE__),'my_worker.rb')

# initialize the work manager. Here you can pass parameters like file names
MyWorkerManager.init_work_manager

# launch processor server
mgr = ScbiMapreduce::Manager.new(ip, port, workers, MyWorkerManager, custom_worker_file, STDOUT)

# you can set additional properties
# =================================

# if you want basic checkpointing. Some performance drop should be expected
# mgr.checkpointing=true

# if you want to keep the order of input data. Some performance drop should be expected
# mgr.keep_order=true

# you can set the size of packets of data sent to workers
mgr.chunk_size=1

# start processing
mgr.start_server

# this line is reached when all data has been processed
puts "Program finished"
