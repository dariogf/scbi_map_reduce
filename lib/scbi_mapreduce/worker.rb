#!/usr/bin/env ruby

require 'eventmachine'
require 'logger'

# require 'error_handler'

module ScbiMapreduce

  class Worker < EventMachine::Connection
    include EM::P::ObjectProtocol

    @@want_to_exit_worker=false

    def receive_initial_config(obj)


    end


    def process_object(obj)

    end


    def starting_worker


    end

    def worker_connected

    end

    def closing_worker


    end
    ######################

    def initialize(*args)
      super
    end

    def post_init
      $WORKER_LOG.info('WORKER CONNECTED')

      worker_connected
    rescue Exception => e
      $WORKER_LOG.error("Exiting worker #{@@worker_id} due to exception:\n"	+ e.message+"\n"+e.backtrace.join("\n"))
      #raise e
    end

    def receive_object(obj)

      if @@count < 0
        @@count += 1
        # receive initial config
        if obj != :no_initial_config then
          receive_initial_config(obj[:initial_config])

          $WORKER_LOG.info('Initial config: received')
        else
          $WORKER_LOG.info('Initial config: empty config')
        end
        # At first iteration, start worker
        starting_worker
      else
        $WORKER_LOG.info("received:"+obj.to_s)
        
        
        if (obj == :quit) || @@want_to_exit_worker
          $WORKER_LOG.info('Quit received')
          
          stop_worker
          
        elsif @@want_to_exit_worker
          $WORKER_LOG.info('Want to exit worker')
          stop_worker
        elsif (obj== :sleep)
          $WORKER_LOG.info('Sleeping 10 secs')
          sleep 10
          send_object(:waking_up)
        else
          @@count += 1
          obj.worker_identifier=@@worker_id.to_i

          # OJO  - HAY QUE PASAR EL MODIFIED OBJECT
          #	 operation = proc {
          #	 							# calculations
          #								obj=process_object(obj)
          #								#puts '.' + obj.seq_name
          #								#return obj
          #							}
          #
          #							callback = proc { |modified_obj|
          #								send_object(modified_obj)
          #							}
          #
          #							EventMachine.defer(operation, callback)
          #send_object(obj)


          begin
            
            obj.start_worker_time!
            
            modified_data=process_object(obj.data)
            obj.data = modified_data
            
            obj.end_worker_time!
            
            # if obj.job_identifier==3
            #   sleep 15
            # end

            send_object(obj)

          rescue Exception => e
            $WORKER_LOG.error("Error processing object\n" + e.message + ":\n" + e.backtrace.join("\n"))
            exception= WorkerError.new('Message',e,@@worker_id,obj)
            send_object(exception)

          end


        end
      end
    end

    def unbind
      $WORKER_LOG.info "EXITING WORKER"
      EventMachine::stop_event_loop
    end

    def stop_worker
      $WORKER_LOG.info "Closing  connection with WORKER"
      $WORKER_LOG.info("Worker processed #{@@count} chunks")
      
      close_connection
      EventMachine::stop_event_loop
      closing_worker
    end
    
    def self.controlled_exit_worker
      @@want_to_exit_worker=true
    end

    def self.start_worker(worker_id,ip,port,log_file=nil)
      #puts "NEW WORKER - INIIIIIIIIIIIIIIIIIIIIT #{self}"
      
      
      ip = ip
      port = port
      @@count = -1

      @@worker_id=worker_id
      
      # Signal.trap("INT")  { puts "TRAP INT in worker #{@@worker_id}"; controlled_exit_worker; EM.stop}
      # Signal.trap("TERM") { puts "TRAP TERM in worker #{@@worker_id}";controlled_exit_worker; EM.stop}

      if log_file.nil?
        log_file = 'logs/worker'+worker_id+'_'+`hostname`.chomp+'_log.txt'
      end

      FileUtils.mkdir_p(File.dirname(log_file)) if ((log_file!=STDOUT) && (!File.exists?(File.dirname(log_file))))

      $WORKER_LOG = Logger.new(log_file)
      $WORKER_LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

      $LOG = $WORKER_LOG

      total_seconds = Time.now_us

      EM.error_handler{ |e|
        $WORKER_LOG.error(e.message + ' => ' + e.backtrace.join("\n"))
      }
      
      Signal.trap("CONT") do
        $WORKER_LOG.info("SIGCONT: Worker: #{@@worker_id} with PID: #{Process.pid} sleeping 15 seconds before waking up")
        puts "SIGCONT: Worker: #{@@worker_id} with PID: #{Process.pid} sleeping 15 seconds before waking up"
        
        sleep 15
      end

      EventMachine::run {

        EventMachine::connect ip, port, self
        $WORKER_LOG.info "Worker: #{@@worker_id} with PID: #{Process.pid} connected to #{ip}:#{port}"

      }

      total_seconds = Time.now_us-total_seconds
      $WORKER_LOG.info "Client #{@@worker_id} processed: #{@@count} objs"
      $WORKER_LOG.info "Client #{@@worker_id} proc rate: #{@@count/total_seconds.to_f} objects/seg"

    end


  end

end
