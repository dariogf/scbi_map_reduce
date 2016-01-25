require "thread.rb"

######################################
# This class creates a thread's pool
######################################

class ThreadPool
  class Worker
    @@count=0
    def initialize

      @identifier = @@count
      @@count+=1
      
      Thread.abort_on_exception = true
      @mutex = Mutex.new
      @thread = Thread.new do
          while true
            sleep 0.001
              block = get_block
              if block
                begin        
                  block.call
                rescue Exception => e
                  puts "In thread: " + e.message
                  raise e
                end
                
                reset_block
              end
          end
      end
    end
    
    def get_block
      @mutex.synchronize {@block}
    end
    
    def set_block(block)
      # puts "set block #{@identifier}"
      @mutex.synchronize do
        raise RuntimeError, "Thread already busy." if @block
        @block = block
      end
    end
    
    def reset_block
      @mutex.synchronize {@block = nil}
    end
    
    def busy?
      @mutex.synchronize {!@block.nil?}
    end
  end
  
  attr_accessor :max_size
  attr_reader :workers

  # Defines the max number of threads that will be able to exist
  def initialize(max_size = 10)
    @max_size = max_size
    @workers = []
    @mutex = Mutex.new
  end
  
  def size
    @mutex.synchronize {@workers.size}
  end
  
  def busy?
    @mutex.synchronize {@workers.any? {|w| w.busy?}}
  end
  
  #Allows that main program doesn't finish until the thread have been executed
  def join
    sleep 0.01 while busy?
  end
  
  # Begin the block's processing. After using this method, will call to "join"
  def process(&block)
    wait_for_worker.set_block(block)
  end
  
  def wait_for_worker
    while true
      worker = find_available_worker
      return worker if worker
      sleep 0.01
    end
  end
  
  def find_available_worker
    @mutex.synchronize {free_worker || create_worker}
  end
  
  def free_worker
    @workers.each {|w| return w unless w.busy?}; nil
  end
  
  def create_worker
    return nil if @workers.size >= @max_size
    worker = Worker.new
    @workers << worker
    worker
  end
  private :wait_for_worker , :find_available_worker , :free_worker , :create_worker
end
