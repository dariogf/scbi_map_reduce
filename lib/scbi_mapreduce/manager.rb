require 'eventmachine'
require 'socket'
# require 'worker_launcher'
require 'logger'
require 'fileutils'

#
#= Manager class
#
# The manager side of scbi_mapreduce
#

module ScbiMapreduce




  class Manager

    attr_accessor :checkpointing, :keep_order, :retry_stuck_jobs, :exit_on_many_errors, :chunk_size

    # initialize Manager
    def initialize(server_ip, port, workers, work_manager_class,custom_worker_file,log_file=nil, init_env_file=nil)
      @port=port

      if log_file.nil?
        log_file = File.join('logs','server_log.txt')
      end
      
      if ((log_file!=STDOUT) && (!File.exists?(File.dirname(log_file))))
        FileUtils.mkdir_p(File.dirname(log_file)) 
        $SERVER_LOG.info("Creating logs folder")
      end
      
      $SERVER_LOG = Logger.new(log_file)


      ip_list = Socket.ip_address_list.select{|e| e.ipv4?}.map{|e| e.ip_address}
      # La forma de abajo no encuentra la myrinet
      # ip_list = Socket::getaddrinfo(Socket.gethostname, "echo", Socket::AF_INET).map{|x| x[3]}.uniq
      ip_list << '127.0.0.1'

      $SERVER_LOG.info("Available IPs: #{ip_list}")

      ip=ip_list.select{|one_ip| one_ip.index(server_ip)==0}.first


      if !ip
        $SERVER_LOG.info("Ip #{server_ip} not found in available IPs: #{ip_list}")
        ip='0.0.0.0'
        # gets
      end

      @ip = ip

      port = 0


      @checkpointing=false
      @keep_order=false
      @retry_stuck_jobs=false
      @exit_on_many_errors=true
      
      @chunk_size=1


      @worker_names=[]
      if workers.is_a?(Integer)
        @workers=workers
      else # workers is a file with names, or an array
        
        # read file
        if workers.is_a?(String) && File.exists?(workers)
          $SERVER_LOG.info("Loading workers file: #{workers}")
          workers = File.read(workers).split("\n").map{|w| w.chomp}
        end
        
        # puts "find worker_names"
        host_name=`hostname`.chomp
        @workers=workers.count(host_name)

        @worker_names=workers
        @worker_names.delete(host_name)
        # puts @workers
      end

      @work_manager_class = work_manager_class
            
      @worker_launcher = WorkerLauncher.new(@ip,port,ip_list,@workers,custom_worker_file,log_file,init_env_file)

      $SERVER_LOG.info("Local workers: #{@workers}")
      $SERVER_LOG.info("Remote workers: #{@worker_names}")


      $SERVER_LOG.datetime_format = "%Y-%m-%d %H:%M:%S"

    end

    #  Start a EventMachine loop acting as a server for incoming workers connections
    def start_server

      # set a custom error handler, otherwise errors are silently ignored when they occurs inside a callback.
      EM.error_handler{ |e|
        $SERVER_LOG.error(e.message + ' => ' + e.backtrace.join("\n"))
      }
      
      # $SERVER_LOG.info("Installing INT and TERM traps in #{@work_manager_class}")
      # Signal.trap("INT")  { puts "TRAP INT";@work_manager_class.controlled_exit; EM.stop}
      # Signal.trap("TERM") { puts "TRAP TERM";@work_manager_class.controlled_exit; EM.stop}

      # start EM loop
      EventMachine::run {

        @work_manager_class.init_work_manager_internals(@checkpointing, @keep_order, @retry_stuck_jobs,@exit_on_many_errors,@chunk_size)

        evm=EventMachine::start_server @ip, @port, @work_manager_class
        dir=Socket.unpack_sockaddr_in( EM.get_sockname( evm ))

        @port = dir[0].to_i
        @ip=dir[1].to_s

        $SERVER_LOG.info 'Server running at : ['+@ip.to_s+':'+@port.to_s+']'
        @worker_launcher.server_port=@port
        @worker_launcher.launch_workers
        @worker_launcher.launch_external_workers(@worker_names)

      }
    rescue Exception => e
      $SERVER_LOG.error("Exiting server due to exception:\n" + e.message+"\n"+e.backtrace.join("\n"))
      @work_manager_class.end_work_manager
    end



    def stats
      @work_manager_class.stats
    end

    def save_stats(stats=nil, filename='scbi_mapreduce_stats.json')
      @work_manager_class.save_stats(stats,filename)
    end


  end
  
  
end
