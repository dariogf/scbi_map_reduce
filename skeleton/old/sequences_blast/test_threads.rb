require 'thread'

# modify include path
$: << File.join(File.dirname(__FILE__),'lib')

require 'find_mids'
include FindMids


NUM_THREADS=8

threads=[]


# create NUM_THREADS threads
NUM_THREADS.times do |n|

  # that calculates some numbers
  threads << Thread.new do
    # thread identifier
    ident=n
    do_dummy_calculation
  end
end


# wait for threads termination
threads.each do |th|
  th.join
end

puts "The END"
