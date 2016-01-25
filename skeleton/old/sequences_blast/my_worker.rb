
# adjust import paths
$: << File.join(File.dirname(__FILE__),'lib')

# load external module
require 'find_mids'
include FindMids


# MyWorker defines the behaviour of workers.
# Here is where the real processing takes place
class MyWorker < ScbiMapreduce::Worker

  # starting_worker method is called one time at initialization
  # and allows you to initialize your variables
  def starting_worker

    # You can use worker logs at any time in this way:
    # $WORKER_LOG.info "Starting a worker"

  end


  # receive_initial_config is called only once just after
  # the first connection, when initial parameters are
  # received from manager
  def receive_initial_config(parameters)

    # Reads the parameters

    # You can use worker logs at any time in this way:
    # $WORKER_LOG.info "Params received"

    # save received parameters, if any
    # @params = parameters
  end


  # process_object method is called for each received object.
  # Be aware that objs is always an array, and you must iterate
  # over it if you need to process it independently
  #
  # The value returned here will be received by the work_received
  # method at your worker_manager subclass.
  def process_object(objs)

    # find mid in sequences
    find_mid_with_blast(objs)

    # return modified objs back to manager
    return objs
  end


  def closing_worker

  end
end
