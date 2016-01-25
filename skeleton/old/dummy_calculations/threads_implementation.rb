#!/usr/bin/env ruby

# load required libraries

# modify include path
$: << File.join(File.dirname(__FILE__),'lib')

require 'thread_pool'
require 'calculations'
include Calculations


@pool=ThreadPool.new(4)

# process
  
times_to_calculate=1000

times_to_calculate.times do

  @pool.process {do_dummy_calculations}

end


puts "wait"
@pool.join
puts "final"

