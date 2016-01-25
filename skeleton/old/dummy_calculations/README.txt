Comparison of workers with scbi_mapreduce vs ruby-threads
=========================================================

This application is only useful for testing. You can modify the files
to perform other tasks. There are other templates available, you 
can list them by issuing this command:

scbi_mapreduce

You can launch the tests application right now with the following command:

  time ruby main.rb
  
  
This launches 4 workers that do some simple calculations (only to keep busy 
the processor), to demonstrate the gain speed agains threads. 4 workers are 
used for a quad-core processor. Adjust it accordingly to your processor cores. 


To launch the threaded version of the application, you can do:

  time ruby threads_implementation.rb
  
You can compare the two times obtained. Threaded version will last the same with 1 thread or with 100.

