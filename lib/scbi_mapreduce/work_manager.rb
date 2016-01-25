# = WorkManager
#
# One instance of this class is created automatically by EM to attend each worker.
#
#This class handles server <-> worker communications. It waits for workers connections, sends them the initial configuration parameters,
#and later sends new jobs each time a worker request a new one until no more works are available.
#
# Reliability can be incremented by using a hash @@running_jobs tracking the object_id of each running work. This approach should be slower than current one.

# require 'error_handler'

# TODO - Data preload (queue?) instead of under demand loading
# DONE - Add serializer with marshal + zlib deflate/inflate

require 'json'

module ScbiMapreduce

  PENDING_TO_SAVE=10
  CHECKPOINT_FILE='scbi_mapreduce_checkpoint'
  OLD_CHECKPOINT_FILE='old_scbi_mapreduce_checkpoint'
  PROCESSING_TIMEOUT_MULTIPLIER=10

  class WorkManagerData

    @@job_id=1
    @@longest_processing_time=0

    attr_reader :job_identifier
    attr_accessor :status, :data, :sent_time, :received_time, :working_time, :worker_start_time, :worker_end_time, :worker_identifier

    def initialize(objs)
      @worker_identifier=0
      @job_identifier=@@job_id
      @@job_id+=1
      @data=objs

      @received_time=nil
      @sent_time=0
      @processing_time=nil
      
      @worker_start_time=0
      @worker_end_time=0
      @worker_time=0
      
      sent!
    end

    def update_with_received!(job)
      @received_time=job.received_time
      @sent_time=job.sent_time
      @worker_end_time=job.worker_end_time
      @worker_start_time=job.worker_start_time
      
      @processing_time=@received_time-@sent_time
      @worker_time=@worker_end_time-@worker_start_time

      # save longer processing time
      @@longest_processing_time=[@@longest_processing_time,@processing_time].max

      @data=job.data
      
      # if job.worker_identifier==0
      #   puts print_worker_time
      # end

      @status=:received
      
    end
    def received!(objs)
      
      @received_time=Time.now_us
      
      @processing_time=@received_time-@sent_time
      @worker_time=@worker_end_time-@worker_start_time

      # save longer processing time
      @@longest_processing_time=[@@longest_processing_time,@processing_time].max

      @data=objs

      @status=:received
    end

    def end_worker_time!
      @worker_end_time=Time.now_us
      @worker_time= (@worker_end_time - @worker_start_time)
      
    end
    
    def start_worker_time!
      @worker_start_time=Time.now_us      
    end

    def sent!
      @status=:running
      @sent_time=Time.now_us
    end

    def stuck?
      (@status==:running) && (@@longest_processing_time>0) && (processing_time>(@@longest_processing_time*PROCESSING_TIMEOUT_MULTIPLIER))
    end

    # return running or real processing time
    def processing_time
      return (@processing_time || (Time.now_us-@sent_time))
    end
    
    def worker_time
      return (@worker_time)
    end
    
    def transmission_time
      return (processing_time - worker_time)
    end    

    def inspect
      time="; time: #{processing_time} usecs"
      return "WorkManagerData: #{@job_identifier} => #{@status} #{time}"
    end
    
    def print_worker_time
      return "WorkManagerData Times: #{@worker_start_time} => #{@worker_end_time} #{worker_time}"
    end

    def self.job_id=(c)
      # puts "Setting job_id to #{c}"
      @@job_id=c
    end

    def self.job_id
      # puts "Setting job_id to #{c}"
      @@job_id
    end

  end

  #require 'json'
  class WorkManager < EventMachine::Connection

    include EM::P::ObjectProtocol

    def self.init_work_manager

    end

    def self.end_work_manager

    end

    def self.work_manager_finished

    end

    def next_work

    end

    def work_received(obj)

    end

    def worker_initial_config

    end

    def error_received(worker_error, obj)

    end

    def too_many_errors_received

    end

    def read_until_checkpoint(checkpoint)

    end

    # if this function returns -1, then automatic checkpointing is done.
    # Return 0 to no checkpointing.
    # Return the restored checkpoint number to start in this point.
    def load_user_checkpoint(checkpoint)
      return -1
    end

    def save_user_checkpoint
    end

    def trash_checkpointed_work

    end

    ############
    def self.stats
      @@stats
    end
    
    def self.save_stats(stats=nil, filename='scbi_mapreduce_stats.json')
      f=File.open(filename,'w')
      
      if stats.nil?
        f.puts JSON::pretty_generate @@stats
      else
        f.puts JSON::pretty_generate stats
      end
      
      f.close
    end

    def self.init_work_manager_internals(checkpointing, keep_order, retry_stuck_jobs,exit_on_many_errors,chunk_size)
      @@stats={}
      @@count = 0
      @@retried_jobs=0
      @@sent_chunks=0
      @@received_objects=0
      @@want_to_exit=false
      @@chunk_count = 0
      @@workers = 0
      @@max_workers = 0
      @@error_count = 0
      @@running_jobs=[]
      # @@compress=true

      @@checkpointing=checkpointing
      @@keep_order=keep_order
      @@retry_stuck_jobs=retry_stuck_jobs
      @@exit_on_many_errors=exit_on_many_errors

      # TODO - Implement a dynamic chunk_size

      @@chunk_size=chunk_size
      $SERVER_LOG.info "Processing in chunks of #{@@chunk_size} objects"
      $SERVER_LOG.info "Checkpointing: #{@@checkpointing}"
      $SERVER_LOG.info "Keeping output order: #{@@keep_order}"
      $SERVER_LOG.info "Retrying stuck jobs: #{@@retry_stuck_jobs}"
      $SERVER_LOG.info "Exiting on too many errors: #{@@exit_on_many_errors}"

      @@checkpoint=0
      if @@checkpointing
        @@checkpoint=self.get_checkpoint
        $SERVER_LOG.info "Detected checkpoint at #{@@checkpoint}"
      end
      
      # for statistics:
      @@total_seconds=0
      @@total_manager_time=0
      # mean_worker_time=0
      @@each_worker_time={}
      @@each_transmission_time={}
      
      @@total_read_time=0
      @@total_write_time=0
      # mean_transmission_time=0

    end


    def mean_time(h)
      r=0
      i=0
      
      h.each do |k,v|
        r+=h[k]
        i+=1
      end
      
      if r>0
        r=r/i.to_f
      end
      
      return r
    end
    def each_worker_time(worker,time)
      if @@each_worker_time[worker].nil? then
        @@each_worker_time[worker]=0
      end
      @@each_worker_time[worker]+=time
    end
    
    def each_transmission_time(worker,time)
      if @@each_transmission_time[worker].nil? then
        @@each_transmission_time[worker]=0
      end
      @@each_transmission_time[worker]+=time
    end
    
    
    def self.checkpoint
      return @@checkpoint
    end

    def remove_checkpoint
      if File.exists?(CHECKPOINT_FILE)
        checkpoint_file = FileUtils.mv(CHECKPOINT_FILE,OLD_CHECKPOINT_FILE)
      end
    end


    def save_checkpoint
      checkpoint_file = File.open(CHECKPOINT_FILE,'w')
      
      if !@@running_jobs.empty?
        checkpoint_value = @@running_jobs.first.job_identifier
      else
         checkpoint_value = WorkManagerData.job_id
      end
      
      $SERVER_LOG.info "Saving checkpoint: #{checkpoint_value}"
      
      checkpoint_file.puts checkpoint_value
      
      checkpoint_file.close
      
      save_user_checkpoint

    end

    def self.get_checkpoint
      res = 0
      begin
        if File.exists?(CHECKPOINT_FILE)
          res=File.read(CHECKPOINT_FILE).chomp
          # puts "read checkpoint #{res}"

          res = res.to_i
        end
      rescue
        res = 0
      end

      return res
    end

    def send_initial_config
      config = worker_initial_config

      if config.nil?
        obj = :no_initial_config
      else
        obj = {:initial_config => config}
      end

      send_object(obj)
    end

    def print_running_jobs
      jobs=@@running_jobs.map{|j| j.inspect}.join("\n")
      $SERVER_LOG.debug("Running Jobs:\n#{jobs}")
    end

    def send_stuck_work
      sent=false

      if @@retry_stuck_jobs
        # $SERVER_LOG.debug("="*40)
        # print_running_jobs
        # count stuck jobs and re-sent the first one
        stuck_works=@@running_jobs.select{|job| job.stuck?}

        if !stuck_works.empty?
          jobs=stuck_works.map{|j| j.inspect}.join("\n")
          $SERVER_LOG.info("Stuck Jobs:\n#{jobs}")

          # send_object
          stuck_works.first.sent!
          send_object(stuck_works.first)
          @@sent_chunks+=1
          @@retried_jobs+=1
          $SERVER_LOG.info("Sending stuck work #{stuck_works.first.inspect}")
          sent=true
        end
      end

      return sent
    end

    # send next work to worker
    def send_next_work

      # if we need to exit, send quit to workers
      
      if @@want_to_exit
        send_object(:quit)
        
      elsif !send_stuck_work
        
      #send stuck work
        objs=[]
        
        t=Time.now_us
        
        # prepare new data
        @@chunk_size.times do
          obj=next_work
          if obj.nil?
            break
          else
            # add to obj array
            objs << obj
          end
        end
        
        @@total_read_time+=(Time.now_us - t)
        
        # if new was data collected, send it
        if objs.count>0
          @@count += objs.count
          @@chunk_count += 1

          work_data=WorkManagerData.new(objs)
          send_object(work_data)
          @@sent_chunks+=1

          # to keep order or retry failed job, we need job status
          if @@keep_order || @@retry_stuck_jobs
            # do not remove data to be able to sent it again
            # work_data.data=nil
            @@running_jobs.push work_data
            # print_running_jobs
          end
        else
          # otherwise, 
          if @@running_jobs.count >0
            $SERVER_LOG.info("Worker, go to sleep")
            send_object(:sleep)
            
          else
            # send a quit value indicating no more data available
            send_object(:quit)
          end
        end
      end
    end

    # loads a checkpoint
    def goto_checkpoint
      if @@checkpoint>0
        $SERVER_LOG.info "Skipping until checkpoint #{@@checkpoint}"

        checkpoint=load_user_checkpoint(@@checkpoint)

        # do an automatic checkpoint restore
        if checkpoint==-1
          (@@checkpoint - 1).times do |i|
            $SERVER_LOG.info "Automatic trashing Chunk #{i+1}"
            # get next work
            @@chunk_size.times do
              obj=next_work
            end
            # trash_checkpointed_work
          end

          $SERVER_LOG.info "Automatic checkpoint finished"

          WorkManagerData.job_id=@@checkpoint

          #user has done the checkpoint restoration
        elsif checkpoint>0
          
          WorkManagerData.job_id=checkpoint
          
        elsif checkpoint==0
          $SERVER_LOG.info "Automatic checkpoint not done"
        end


        @@checkpoint=0

      end

    end

    def post_init
      @@workers += 1
      @@max_workers +=1
      # when first worker is connected, do special config
      if @@workers == 1
        @@total_seconds = Time.now_us
        $SERVER_LOG.info "First worker connected"

        if @@checkpointing
          $SERVER_LOG.info "Checking for checkpoint"
          goto_checkpoint
        end
      end

      $SERVER_LOG.info "#{@@workers} workers connected"
      send_initial_config
      send_next_work
    end
    
    def self.controlled_exit
      $SERVER_LOG.info("Controlled exit. Workers will be noticed in next round")
      @@want_to_exit=true
    end


    def receive_object(obj)

      # check if response is an error
      if obj.is_a?(Exception)
        $SERVER_LOG.error("Error in worker #{obj.worker_id} while processing object #{obj.object.inspect}\n" + obj.original_exception.message + ":\n" + obj.original_exception.backtrace.join("\n"))

        @@error_count += 1

        error_received(obj,obj.object.data)

        # if there are too many errors
        if (@@count>100) && (@@error_count >= @@count*0.8)

          # notice programmer
          res=too_many_errors_received

          # force exit if too_many_errors_received returns true
          if @@exit_on_many_errors || res
            $SERVER_LOG.error("Want to exit due to too many errors")
            self.controlled_exit
          end
        end

      elsif obj == :waking_up
        $SERVER_LOG.info("Worker woke up")
      else
        
        # if not using checkpointing
        obj.received!(obj.data)

        if @@checkpointing || @@keep_order || @@retry_stuck_jobs
          # print_running_jobs
          checkpointable_job_received(obj)
        else
          # change this job's status to received
          
          t=Time.now_us
          work_received(obj.data)
          @@received_objects+=obj.data.count
          @@total_write_time+=(Time.now_us - t)
        end
        
        # puts obj.worker_identifier,obj.worker_identifier.class
        # if obj.worker_identifier==0 then
        # end
        
        each_worker_time(obj.worker_identifier, obj.worker_time)
        each_transmission_time(obj.worker_identifier, obj.transmission_time)
      end

      # free mem
      obj=nil
      send_next_work

    end


    def checkpointable_job_received(obj)

      # find reveived object between sent jobs
      received_job=@@running_jobs.find{|o| o.job_identifier==obj.job_identifier}

      # save job if there is was a valid work previously sent
      if received_job

        # change this job's status to received, already done in previous method
        received_job.update_with_received!(obj)

        # # if there are sufficient jobs, count pending ones
        # if (@@running_jobs.count>=PENDING_TO_SAVE)

        # count received objects pending to be written, only until one that is still running is found
        pending_to_save=0
        @@running_jobs.each do |job|
          if job.status==:received
            pending_to_save += 1
          else
            break
          end
        end

        # if there are a few pending to save works, or all remaining works are pending, then save
        if (pending_to_save>=PENDING_TO_SAVE) || (pending_to_save==@@running_jobs.count)
          # save pending jobs and write to disk
          to_remove = 0
          
          if @@checkpointing
            remove_checkpoint
          end
          
          @@running_jobs.each do |job|
            if job.status==:received
              # puts "Sent to save: #{job.inspect}"
              t=Time.now_us
              work_received(job.data)
              @@received_objects+=job.data.count
              @@total_write_time+=(Time.now_us - t)

              job.status=:saved
              to_remove += 1
            else
              break
            end
          end

          # if some objects were saved, remove them from the running_jobs
          if to_remove > 0
            to_remove.times do |i|
              o=@@running_jobs.shift

              # puts "Job removed #{o.inspect}"
              o=nil
            end

            # print_running_jobs

            if @@checkpointing && !@@want_to_exit

              save_checkpoint
            end
          end
        end
        # end
      else
        $SERVER_LOG.warn "Job already processed #{obj.inspect}"
      end
    end

    def initialize(*args)
      super
      #puts "WORK MANAGER INITIALIZE NEWWWWWWWWWW, ONE per worker"
    end

    # A worker has disconected
    def unbind

      @@workers -= 1
      #puts @@running_jobs.to_json

      $SERVER_LOG.info  "Worker disconnected. #{@@workers} kept running"

      # no more workers left, shutdown EM and stop server
      if @@workers == 0
        $SERVER_LOG.info  "All workers finished"
        stop_work_manager
      end
    end
    
    
    
    def stop_work_manager
      
      
      
      EM.stop
      $SERVER_LOG.info  "Exiting server"


      self.class.end_work_manager


      @@total_seconds = (Time.now_us-@@total_seconds)
      @@total_manager_time= @@total_manager_time 
      
      @@total_read_time=@@total_read_time
      @@total_write_time=@@total_write_time

      mean_worker_time=mean_time(@@each_worker_time)
      mean_transmission_time=mean_time(@@each_transmission_time)
      
      idle_time=(@@total_seconds - @@total_read_time -@@total_write_time - mean_transmission_time)
      
      @@stats={}
      @@stats[:total_objects]=@@count
      @@stats[:total_seconds]=@@total_seconds
      @@stats[:sent_chunks]=@@sent_chunks
      @@stats[:received_objects]=@@received_objects
      @@stats[:processing_rate]=(@@count/@@total_seconds.to_f)
      @@stats[:total_read_time]=@@total_read_time
      @@stats[:total_write_time]=@@total_write_time
      @@stats[:mean_worker_time]=mean_worker_time
      @@stats[:mean_transmission_time]=mean_transmission_time
      @@stats[:total_manager_idle_time]=idle_time
      
      @@stats[:error_count]=@@error_count
      @@stats[:retried_jobs]=@@retried_jobs
      @@stats[:chunk_size]=@@chunk_size
      @@stats[:connected_workers]=@@max_workers
      @@stats[:each_transmission_time]=@@each_transmission_time
      @@stats[:each_worker_time]=@@each_worker_time


      
      
      $SERVER_LOG.info  "Total processed: #{@@count} objects in #{@@total_seconds} seconds"
      $SERVER_LOG.info  "Total sent chunks: #{@@sent_chunks} objects"
      
      $SERVER_LOG.info  "Total sent objects: #{@@count} objects"
      $SERVER_LOG.info  "Total received objects: #{@@received_objects} objects"
      
      $SERVER_LOG.info  "Processing rate: #{"%.2f" % (@@count/@@total_seconds.to_f)} objects per second"
      $SERVER_LOG.info  "Connection rate: #{"%.2f" % (@@chunk_count/@@total_seconds.to_f)} connections per second"
      
      $SERVER_LOG.info "Total read time #{@@total_read_time} seconds"
      $SERVER_LOG.info "Total write time #{@@total_write_time} seconds"
      # mean_worker_time=mean_worker_time/@@max_workers
      $SERVER_LOG.info "Total worker time #{mean_worker_time} seconds"
      $SERVER_LOG.info "Total transmission time #{mean_transmission_time} seconds"
      $SERVER_LOG.info "Total manager_idle time #{idle_time} seconds"
      # $SERVER_LOG.info "Total manager time #{@@total_read_time + @@total_write_time + mean_transmission_time} seconds"
      
      $SERVER_LOG.info  "Number of errors: #{@@error_count}"
      $SERVER_LOG.info  "Number of retried stuck jobs: #{@@retried_jobs}"
      $SERVER_LOG.info  "Chunk size: #{@@chunk_size}"
      $SERVER_LOG.info  "Total connected workers: #{@@max_workers}"
      
      self.class.work_manager_finished

    end

  end
end
