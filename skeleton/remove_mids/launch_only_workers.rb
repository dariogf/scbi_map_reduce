#!/usr/bin/env ruby

$: << File.dirname(__FILE__)

require "logger"

$: << '/Users/dariogf/progs/ruby/gems/scbi_mapreduce/lib'

require 'scbi_mapreduce'
require 'my_worker_manager'


$LOG = Logger.new(STDOUT)
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

ip='10.247.255.5'
port = 50000
workers = 8

custom_worker_file = File.join(File.dirname(__FILE__),'my_worker.rb')

$LOG.info 'Starting server'


worker_launcher = ScbiMapreduce::WorkerLauncher.new(ip,port, workers, custom_worker_file, STDOUT)
worker_launcher.launch_workers_and_wait

# launch processor server
$LOG.info 'Closing workers'
