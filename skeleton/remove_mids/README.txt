A simple scbi_mapreduce application demo
========================================

This application is a basic sequence processing template. It processes all 
sequences in fastq_file (a file in FastQ format) removing a MIDs from it. It 
needs some external requisites to work:

EXTERNAL REQUISITES
===================

* scbi_blast gem installed


At lib/db you can find a preformated MID database.

You can modify the files to perform more complicated processing. 
There are other templates available, you can list them by issuing this command:

scbi_mapreduce

You can launch the application right now with the following command using 4 cpus/cores and chunks of 100 sequences at a time:

  ruby main.rb fastq_file 4 100

A server and some workers will be launched, and all sequences in fastq_file will
be processed in blocks of 100 sequences.

A sequential lineal example is also provided, you can launch it by issuing:

ruby linear_implementation.rb fastq_file
