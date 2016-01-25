class GMatch
  
  attr_accessor :offset
  attr_accessor :match
  
  
end

class String
		def lcs(s2)
			s1=self
			res="" 
			num=Array.new(s1.size){Array.new(s2.size)}
			len,ans=0
			lastsub=0
			s1.scan(/./).each_with_index do |l1,i |
				s2.scan(/./).each_with_index do |l2,j |
				  unless l1==l2
				    num[i][j]=0
				  else
				    (i==0 || j==0)? num[i][j]=1 : num[i][j]=1 + num[i-1][j-1]
				    if num[i][j] > len
				      len = ans = num[i][j]
				      thissub = i
				      thissub -= num[i-1][j-1] unless num[i-1][j-1].nil?  
				      if lastsub==thissub
				        res+=s1[i,1]
				      else
				        lastsub=thissub
				        res=s1[lastsub, (i+1)-lastsub]
				      end
				    end
				  end
				end
			end
			res
		end
end


class Regexp
  def global_match(input_str,overlap_group_no = 0)
    res = []
    
    str=input_str
    
    last_end = 0
    
    loop do
      str = input_str.slice(last_end,input_str.length-last_end)
      if str.nil? or str.empty?
        break
      end
      
      m = self.match(str)
      # puts "find in: #{str}"
      
      if !m.nil?
        # puts m.inspect
        
        
        new_match=GMatch.new()
        new_match.offset = last_end
        new_match.match = m
        
        res.push new_match
        
        if overlap_group_no == 0
          last_end += m.end(overlap_group_no)
        else
          last_end += m.begin(overlap_group_no)
        end
        
      else
        break
      end
      
    end
    
    
    return res
  end
    
  
  # def global_match(str, &proc)
  #     retval = nil
  #     loop do
  #       res = str.sub(self) do |m|
  #         proc.call($~) # pass MatchData obj
  #         ''
  #       end
  #       break retval if res == str
  #       str = res
  #       retval ||= true
  #     end
  #   end
end
