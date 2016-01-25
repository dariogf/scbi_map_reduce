require 'json'

# MyWorkerManager class is used to implement the methods
# to send and receive the data to or from workers
class MyWorkerManager < ScbiMapreduce::WorkManager

  # init_work_manager is executed at the start, prior to any processing.
  # You can use init_work_manager to initialize global variables, open files, etc...
  # Note that an instance of MyWorkerManager will be created for each
  # worker connection, and thus, all global variables here should be
  # class variables (starting with @@)
  def self.init_work_manager(fastq_file_path)

    # puts "tiempo1",Time.now
    # open file using scbi_fastq gem
    @@fastq_file=FastqFile.new(fastq_file_path)
    @@results=FastqFile.new('./results.fastq'+Time.now.usec.to_s,'w+')
    @@cache = []
    
    # @@fastq_file.each do |name,fasta,qual,comments|
    #   @@cache << [name,fasta,qual,comments]
    # end
    # puts "tiempo2",Time.now
  end

  # end_work_manager is executed at the end, when all the process is done.
  # You can use it to close files opened in init_work_manager
  def self.end_work_manager
    @@fastq_file.close

    @@results.close
  end

  # worker_initial_config is used to send initial parameters to workers.
  # The method is executed once per each worker
  def worker_initial_config
    
  end

  # next_work method is called every time a worker needs a new work
  # Here you can read data from disk
  # This method must return the work data or nil if no more data is available
  def next_work
    name,fasta,qual,comments=@@fastq_file.next_seq
    # name,fasta,qual,comments=@@cache.shift

    if !name.nil?
      return name,fasta,qual,comments
    else
      return nil
    end

  end


  # work_received is executed each time a worker has finished a job.
  # Here you can write results down to disk, perform some aggregated statistics, etc...
  def work_received(results)

    # write results to disk
    results.each do |name,fasta,qual,comments|
      # puts "comments: #{comments}\n"
      @@results.write_seq(name,fasta,qual,comments)
    end
    
  end

end
