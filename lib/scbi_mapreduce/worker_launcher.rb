# TODO - Make a per-node launcher: launch_workers server_ip server_port count

module ScbiMapreduce

  require 'resolv'

  INTERPRETER='ruby'

  class WorkerLauncher

    attr_accessor :server_ip, :server_port
    
    @@worker_id=0

    def initialize(server_ip,server_port, server_ip_list,workers, worker_file, log_file=nil, init_env_file=nil)
      @server_ip = server_ip
      @server_port = server_port
      @worker_file = worker_file
      @workers=workers
      @init_env_file=init_env_file
      @server_ip_list=server_ip_list



      if log_file.nil?
        log_file = "logs/launcher_global_log.txt"
      end

      FileUtils.mkdir_p(File.dirname(log_file)) if ((log_file!=STDOUT) && (!File.exists?(File.dirname(log_file))))


      $LAUNCHER_LOG = Logger.new(log_file)

      $LAUNCHER_LOG.datetime_format = "%Y-%m-%d %H:%M:%S"
    end

    def launch_workers_and_wait
      launch_workers
      Process.waitall
    end

    def launch_workers

      if system("which srun > /dev/null 2>&1")
          $LAUNCHER_LOG.info "SLURM DETECTED"
          $LAUNCHER_LOG.info "Launching #{@workers} workers via srun"
          launch_workers_srun
      else
          $LAUNCHER_LOG.info "Launching #{@workers} workers via SSH"
          launch_workers_ssh
      end

    end

    def launch_workers_srun
      # TODO - si aqui falla algo, no peta, se bloquea
      $LAUNCHER_LOG.info "Launching #{@workers} local workers"
        
        pid=fork{
          $LAUNCHER_LOG.info "Connecting #{@workers} local workers to #{@server_ip}:#{@server_port}"
          cmd = "srun #{File.join(File.dirname(__FILE__),'main_worker.rb')} auto #{server_ip} #{server_port} #{@worker_file}"
          $LAUNCHER_LOG.info cmd
          exec(cmd)
        }

        $LAUNCHER_LOG.info "All workers launched"
    
    end

    def launch_workers_ssh
      # TODO - si aqui falla algo, no peta, se bloquea
      $LAUNCHER_LOG.info "Launching #{@workers} local workers"
      if @workers > 0
        $LAUNCHER_LOG.info "Connecting #{@workers} local workers to #{@server_ip}:#{@server_port}"
        threads = []
        @workers.times do |i|
          pid=fork{
            launch_worker(@@worker_id,@server_ip,@server_port)
            $LAUNCHER_LOG.info "Worker #{i} launched [#{@server_ip}:#{@server_port}]"
          }
          @@worker_id+=1
          #threads.each { |aThread|  aThread.join }
        end
        #Process.waitall
        $LAUNCHER_LOG.info "All workers launched"
      end
    end

    # override this
    def launch_worker(worker_id, server_ip, server_port)

      cmd = "#{INTERPRETER} #{File.join(File.dirname(__FILE__),'main_worker.rb')} #{worker_id.to_s} #{server_ip} #{server_port} #{@worker_file}"
      puts cmd
      exec(cmd)
    end

    def find_common_ip(machine_ip,ip_list)

      def left_largest_common_substr(s1,s2)
        res=''

        s2.scan(/./).each_with_index do |l1,i|
          if s1[i]==l1
            res << l1
          else
            break
          end
        end
        res

      end

      def remove_final_dot(s)
        res=s
        # remove final dot
        if res[res.length-1]=='.'
          res=res[0,res.length-1]
        end

        return res
      end


      res=''
      common_ip=''

      ip_list.each do |ip|

        res=left_largest_common_substr(ip,machine_ip)
        res=remove_final_dot(res)

        if res.length>common_ip.length
          common_ip=res
        end
      end

      return common_ip
    end


    def launch_external_workers(workers)
      puts "Launching #{workers.count} external workers: #{workers}"
      puts "INIT_ENV_FILE: #{@init_env_file}"
      
      # This sleep is necessary to leave time to lustre fylesystems to sync the log folder between all nodes. If not, external workers will not be launched.
      if !workers.empty?
        puts "SLEEP 10 for logs folder sync in lustre fs"
        sleep 10
      end
      
      init=''
      if @init_env_file
        init_path = File.expand_path(@init_env_file)
        # path = File.join($ROOT_PATH)
        # puts "init_env file: #{path}"
        if File.exists?(init_path)
          puts "File #{init_path} exists, using it"
          init=". #{init_path}; "
        end
      end

      init_dir=Dir.pwd

      cd =''

      if File.exists?(init_dir)
        cd = "cd #{init_dir}; "
      end

      

      workers.each do |machine|
        
        log_file=File.join(init_dir,'logs',"launcher_#{@@worker_id}")
        log_dir=File.join(init_dir,'logs')
        
        # if server_ip is not in valid ips
        if !@server_ip_list.include?(@server_ip)
          # find matching ip between server and worker
          machine_ip = Resolv.getaddress(machine)
          matching_ip=find_common_ip(machine_ip,@server_ip_list)
          found_ip=@server_ip_list.select{|one_ip| one_ip.index(matching_ip)==0}.first
        else
          found_ip=@server_ip
        end

        if !found_ip.nil?
          # cmd = "ssh #{machine} \"#{init} #{cd} #{INTERPRETER} #{File.join(File.dirname(__FILE__),'main_worker.rb')} #{worker_id.to_s} #{@server_ip} #{@server_port} #{@worker_file}\""
          # cmd = "ssh #{machine} \"nohup #{File.join(File.dirname(__FILE__),'launcher.sh')} #{worker_id.to_s} #{@server_ip} #{@server_port} #{@worker_file} #{init_dir} #{init_path}  </dev/null >> #{log_file} 2>> #{log_file} & \""
          cmd = "ssh #{machine} \"nohup  #{File.join(File.dirname(__FILE__),'launcher.sh')} #{@@worker_id.to_s} #{found_ip} #{@server_port} #{@worker_file} #{init_dir} #{init_path}  </dev/null >> #{log_file} 2>> #{log_file} & \""

          $LAUNCHER_LOG.info cmd

          pid=fork{
            exec(cmd)
          }

          @@worker_id+=1
        else
          $LAUNCHER_LOG.error("Couldn't find a matching ip between worker (#{machine_ip}) and server #{ip_list.to_json}")
        end
      end
    end

  end
end
