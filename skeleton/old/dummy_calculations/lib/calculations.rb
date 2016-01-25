module Calculations
  
  
  def do_dummy_calculations
    t=Time.now
    x=0
  	20000000.times do |i|
		x+=1
	end
    puts Time.now-t
  end

  def do_dummy_calculations2
    numer_of_calcs=250000

    # t=Time.now

    x1=1
    x2=1

    # do a loop with calculations
    numer_of_calcs.times do |i|
      x=x1+x2

      x1=x2
      x2=x

      # puts some info at regular intervals
      # if (i % 100000)==0
      #   puts "Calculated #{i}"
      # end
    end
    # puts Time.now-t

  end

end
