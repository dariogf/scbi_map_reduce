require "scbi_mapreduce/version"

module ScbiMapreduce
  # Your code goes here...
end

class Time
  def self.now_us
    return (Time.now.to_f)
  end
end


require 'scbi_mapreduce/manager'
require 'scbi_mapreduce/worker_launcher'
require 'scbi_mapreduce/worker'
require 'scbi_mapreduce/work_manager'
require 'scbi_mapreduce/error_handler'
require 'scbi_mapreduce/zlib_serializer'
