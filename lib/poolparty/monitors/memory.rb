=begin rdoc
  Basic monitor on the cpu stats
=end
module Memory
  module Master
    # Get the average memory usage over the cloud
    def memory
      nodes.size > 0 ? nodes.inject(0) {|i,a| i += a.memory } / nodes.size : 0.0
    end
  end

  module Remote
    def memory
      str = ssh("free -m | grep -i mem")
      total_memory = str.split[1].to_f
      used_memory = str.split[2].to_f

      used_memory / total_memory        
    rescue
      0.0
    end    
  end
  
end

PoolParty.register_monitor Memory