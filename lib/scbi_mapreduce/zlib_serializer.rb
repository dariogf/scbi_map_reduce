require 'zlib'
require 'json'

# A serializer class that provides compression
# 
# To use this instead of the default Marshal serializer, redefine the serializer method in your worker and worker_manager as this:
# 
# def serializer
#   ZlibSerializer
#   
# end
# 

class ZlibSerializer

  def self.dump(data)
    input=Marshal.dump(data)
    zipper = Zlib::Deflate.new(Zlib::BEST_COMPRESSION,15,9)
    res= zipper.deflate(input, Zlib::FINISH)
    zipper.close
    
    return res
  end

  def self.load(input)
    unzipper = Zlib::Inflate.new(15)
    res= unzipper.inflate(input)
    unzipper.close

    return Marshal.load(res)
  end
end
