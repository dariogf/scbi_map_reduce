module ScbiMapreduce

  class WorkerError < Exception

    attr_reader :worker_id,:original_exception, :object

    def initialize(message, original_exception, worker_id, object)
      @message = message
      @worker_id = worker_id
      @original_exception = original_exception
      @object = object
    end

  end
end
