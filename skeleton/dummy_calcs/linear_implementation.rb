#!/usr/bin/env ruby

# load required libraries

# modify include path
$: << File.join(File.dirname(__FILE__),'lib')

require 'calculations'
include Calculations

# process
  
times_to_calculate=1000

times_to_calculate.times do

  do_dummy_calculations

end

puts "final"

