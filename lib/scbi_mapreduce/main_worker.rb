#!/usr/bin/env ruby

# $: << '/Users/dariogf/progs/ruby/gems/scbi_mapreduce/lib'
$: << File.expand_path(File.join(__FILE__,'..','..'))
# puts $:

require 'scbi_mapreduce'

class String
  def camelize
    self.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
  end

  def decamelize
    self.to_s.
      gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z]+)([A-Z\d])/, '\1_\2').
      gsub(/([A-Z]{2,})(\d+)/i, '\1_\2').
      gsub(/(\d+)([a-z])/i, '\1_\2').
      gsub(/(.+?)\&(.+?)/, '\1_&_\2').
      gsub(/\s/, '_').downcase
  end
end

#================= MAIN

if ARGV.size != 4
  puts "Usage #{$0} worker_id server_ip server_port custom_worker_class"
  puts "Eg.: #{$0} 1 localhost 50000 MyWorker"
  exit
end

worker_id = ARGV[0]
ip = ARGV[1]
port = ARGV[2].to_i
custom_worker_file = ARGV[3]

using_slurm=false

if worker_id.upcase == 'AUTO'
  worker_id = ENV['SLURM_PROCID']
  using_slurm=true
end

if worker_id.to_i == 0 && using_slurm
  puts "Launching worker with: worker_id:#{worker_id}, ip:#{ip}, port:#{port}, worker_file:#{custom_worker_file}"
  puts "Ignoring first worker in manager node worker_id:#{worker_id}"
else

  puts "Launching worker with: worker_id:#{worker_id}, ip:#{ip}, port:#{port}, worker_file:#{custom_worker_file}"

  #$: << File.expand_path(File.dirname(custom_worker_file))

  require custom_worker_file

  klass_name = File.basename(custom_worker_file,File.extname(custom_worker_file)).camelize

  worker_class = Object.const_get(klass_name)

  worker_class.start_worker(worker_id,ip,port)

end

puts "FINISH WORKER"



# ============
