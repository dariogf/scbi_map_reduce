require 'json'

# MyWorkerManager class is used to implement the methods
# to send and receive the data to or from workers
class MyWorkerManager < ScbiMapreduce::WorkManager

  # init_work_manager is executed at the start, prior to any processing.
  # You can use init_work_manager to initialize global variables, open files, etc...
  # Note that an instance of MyWorkerManager will be created for each
  # worker connection, and thus, all global variables here should be
  # class variables (starting with @@)
  def self.init_work_manager
    
    # execute dummy_calc in workers @remaining_data times
    @@remaining_data = 1000
  end

  # end_work_manager is executed at the end, when all the process is done.
  # You can use it to close files opened in init_work_manager
  def self.end_work_manager

  end

  # worker_initial_config is used to send initial parameters to workers.
  # The method is executed once per each worker
  def worker_initial_config

  end

  # next_work method is called every time a worker needs a new work
  # Here you can read data from disk
  # This method must return the work data or nil if no more data is available
  def next_work
    @@remaining_data -= 1

    e = @@remaining_data

    e = nil if @@remaining_data<=0
    
    return e

  end


  # work_received is executed each time a worker has finished a job.
  # Here you can write results down to disk, perform some aggregated statistics, etc...
  def work_received(results)

    # write_data_to_disk(results)
  end

end
