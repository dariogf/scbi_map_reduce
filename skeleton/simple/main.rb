#!/usr/bin/env ruby

# load required libraries
require 'scbi_mapreduce'
require './my_worker_manager.rb'

# listen on all ips at port 50000
ip='0.0.0.0'
port = 50000

# set number of workers. You can also provide an array with worker names.
# Those workers names can be read from a file produced by the existing
# queue system, if any.
workers = 8

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
mgr.chunk_size=100

# start processing
mgr.start_server

# this line is reached when all data has been processed
puts "Program finished"
