A simple scbi_mapreduce application demo
========================================

This application is a basic sequence processing template. It processes all 
sequences in fastq_file (a file in FastQ format) removing a MIDs from it. It 
needs some external requisites to work:

EXTERNAL REQUISITES
===================

* Blast+ 2.2.24 or greater installed
* scbi_blast gem installed


At lib/db you can find a preformated MID database for blast+ (formatted with makeblastdb).

You can modify the files to perform more complicated processing. 
There are other templates available, you can list them by issuing this command:

scbi_mapreduce

You can launch the application right now with the following command:

  ruby main.rb fastq_file

A server and some workers will be launched, and all sequences in fastq_file will
be processed in blocks of 100 sequences.

A sequential example is also provided, you can launch it by issuing:

ruby linear_implementation.rb fastq_file
