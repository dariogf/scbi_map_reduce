= scbi_mapreduce

* http://www.scbi.uma.es/downloads

== DESCRIPTION:

scbi_mapreduce brings parallel and distributed computing capabilities to your code, with a very easy to use framework that allows you to exploit your clustered or cloud computational resources.

== FEATURES:

scbi_mapreduce provides a black boxed distributed programming. Users only need to code some predefined methods in order to achieve distribution. Programming remains sequential at user level (this avoids the hassle of threads or processes handling).

When a project using scbi_mapreduce is run, a Manager process and a bunch of workers are created (workers can be in different machines). Manager will dispatch new data to available workers (mapping phase), each worker receives its data, manipulates it and returns the data again to Manager that will aggregate it as desired (reducction phase). 

The manager is always waiting for workers connections or requests. When a new worker connects, it automatically receives some initial params from the server. After the initial configuration, each worker receives a first chunk of work data. Once a worker has done its job with the received data, it sends the results back to the manager, the manager saves the data, and sends a new assignment to the worker. This process is repeated until manager doesn’t have more data to be processed.

=== Some cool features of scbi_mapreduce are:

- Automatic project creation using a generator and templates (you only need to modify some methods since a scaffold is automatically created for you)
- Variable data-chunksizes: data can be grouped on variable size chunks in order to optimize network transfers and processing
- Fixed order: order of input data can be maintained after the parallel execution (uses a cache to store out of order data until it is needed)
- Checkpoint: current processing status can be committed to disk allowing to retake the execution of an interrupted job at the last committed point
- Compression: data transfers can be automatically compressed
- Encription: data transfers can be automatically encripted

=== Worker-specific features:

- Workers are automatically spawned over the cluster (be sure to configure automatic login via ssh with ssh keys)
- Additional workers can be launched/stopped at any time
- Workers can be executed over a mixture of architectures and operating systems simultaneously (x86 64, ia64, i686 - OSX, Linux, UNIX)
- Workers of different speeds works at full capacity all the time, without producing delays on faster workers
- scbi_mapreduce uses tcp/ip and because of that it can be used over a wide variety of interconnection networks (ethernet, Gigabit, InfinyBand, Myrinet, optic-fiber with ip, etc...), and of course, over the internet (although performance will be restricted by network latency and speed)
- High work throughput. About 18000 works (1 kb of data) per second with a single core manager
- Number of workers is highly scalable. Done tests with up to 80 distributed cores.
- Same solution works on standalone machines, clusters, cloud, SMP machines, or a mixture of them

=== Other features

- Exhaustive log option: manager and by worker logs are very useful at development stages
- Processing stats: scbi_mapreduce calculates individual performance statistics for each worker and a global one for manager process.
- scbi_mapreduce makes use of evented IO (EventMachine) being efficient regarding to networked I/O operations
- Reduced disk I/O: data is read only once, subsequent transfers and splitting are done in RAM (this is very appropriate when disk I/O is already quoted in Cloud or pay per use services)
- There is no need to use shared storage, (although the software must be installed on all worker machines)
- Worker error handling: when an exception raises in a worker, it is reported to manager, where it can be handled appropriately
- High error rate aborting: if a high error rate is detected, execution is aborted in order to preserve computational resources so the user don’t need to execute the whole dataset to find that there was a programming mistake (very useful with pay per use services)


scbi_mapreduce has been tested on production with PBS and Moab/Slurm queue systems, but it can be easily adapted to other ones.

== SYNOPSIS:

scbi_mapreduce provides an automated code generator like rails. To use it, you only need to issue this command:

  scbi_mapreduce app_name template
  
E.g.: To create a simple app demo (other templates are avaiable, to list them execute scbi_mapreduce without arguments):

  scbi_mapreduce my_app simple
  
A full project template will be created for you with (at least) the following files:

  my_app/main.rb
  my_app/my_worker.rb
  my_app/my_worker_manager.rb
  my_app/README.txt


You can run main.rb as any other ruby script.

  cd my_app
  ruby main.rb
  
Now that evething is working, you must modify +my_worker+ and +my_worker_manager+ in order to do the desired work.

=== my_worker_manager.rb

In my_worker_manager you open input files, split data in chunks that are automatically sent to workers, and later on writes down data to disk when workers finished them. Here are the basic methods that can be personalized.

The most important ones are +next_work+ (where data is splitted into chunks), and +work_received+ (where processed data is received from workers):

  # next_work method is called every time a worker needs a new work
  # Here you can read data from disk
  # This method must return the work data or nil if no more data is available
  def next_work
    @@remaining_data -= 1

    e = @@basic_string

    e = nil if @@remaining_data<0
    return e

  end
  
-

  # work_received is executed each time a worker has finished a job.
  # Here you can write results down to disk, perform some aggregated statistics, etc...
  def work_received(results)

    # write_data_to_disk(results)
  end


There are also some other methods that can be used to send initial configuration parameters, open and close files, etc...

  # init_work_manager is executed at the start, prior to any processing.
  # You can use init_work_manager to initialize global variables, open files, etc...
  # Note that an instance of MyWorkerManager will be created for each
  # worker connection, and thus, all global variables here should be
  # class variables (starting with @@)
  def self.init_work_manager
  
    # use 200000 strings
    @@remaining_data = 200000
  
    # of 1024 characters each
    @@basic_string='a'*1024

  end

-

  # end_work_manager is executed at the end, when all the process is done.
  # You can use it to close files opened in init_work_manager
  def self.end_work_manager

  end

-

  # worker_initial_config is used to send initial parameters to workers.
  # The method is executed once per each worker
  def worker_initial_config

  end

 
=== my_worker.rb

The main method that needs to be modified on my_worker.rb is +process_object+. It is executed each time new data is available, and is where the real distributed processing takes place since it is executed simultaneously on different machines.

  def process_object(objs)

    # iterate over all objects received
    objs.each do |obj|
      # convert to uppercase
      obj.upcase!
    end

    # return objs back to manager
    return objs
  end


There are other useful methods:

   # starting_worker method is called one time at initialization
   # and allows you to initialize your variables
   def starting_worker

     # You can use worker logs at any time in this way:
     # $WORKER_LOG.info "Starting a worker"

   end

-

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

-

   # process_object method is called for each received object.
   # Be aware that objs is always an array, and you must iterate
   # over it if you need to process it independently
   #
   # The value returned here will be received by the work_received
   # method at your worker_manager subclass.
   def process_object(objs)

     # iterate over all objects received
     objs.each do |obj|

       # convert to uppercase
       obj.upcase!
     end

     # return objs back to manager
     return objs
   end

-

   # called once, when the worker is about to be closed
   def closing_worker

   end
 
=== main.rb


On main.rb is where the manager and workers are launched. Here you define listening ip. 

  # listen on all ips at port 50000
  ip='0.0.0.0'
  port = 50000
  
If you are using a cluster and thus don't know where manager will be executed, you can specify the initial part of the ip interface. Eg.: if you specify ip='10.16', scbi_mapreduce will use the network interface that matches this ip:

The number of workers can be a number (workers are launched on the same machine than Manager), or a list of machine names, in which case workers are launched via ssh on remote machines and automatically connected to Manager.

  # set number of workers. You can also provide an array with worker names.
  # Those workers names can be read from a file produced by the existing
  # queue system, if any.
  workers = 8

Your worker file will be used to launch workers.

  # we need the path to my_worker in order to launch it when necessary
  custom_worker_file = File.join(File.dirname(__FILE__),'my_worker.rb')

  # initialize the work manager. Here you can pass parameters like file names
  MyWorkerManager.init_work_manager

  # launch processor server
  mgr = ScbiMapreduce::Manager.new(ip, port, workers, MyWorkerManager, custom_worker_file, STDOUT)

You can also set additional properties:

  # if you want basic checkpointing. Some performance drop should be expected
  # mgr.checkpointing=true

  # if you want to keep the order of input data. Some performance drop should be expected
  # mgr.keep_order=true

	# Enable fault tolerance for stuck jobs. Those jobs that has been stuck will be sent again to another worker. Some performance drop should be expected
	# mgr.retry_stuck_jobs=true

  # you can set the size of packets of data sent to workers
  mgr.chunk_size=100


And finally, start the server, and write a file with specific statistics if desired:

  # start processing
  mgr.start_server

	# save full stats and a custom value in json format to a file
	mgr.stats[:my_stats]=11

	mgr.save_stats 

  # this line is reached when all data has been processed
  puts "Program finished"


== REQUIREMENTS:

* Ruby 1.9.2 (you can install it by: rvm install 1.9.2)
* OSX, Linux, UNIX and other UNIX-like operating systems. (Windows may work if ssh is available to spawn jobs. Not tested)
* eventmachine gem (is automatically installed)

== INSTALL:

* gem install scbi_mapreduce

== LICENSE:

(The MIT License)

Copyright (c) 2010 Dario Guerrero

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.