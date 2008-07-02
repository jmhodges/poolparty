=begin rdoc
  Basic monitor on the cpu stats
=end
require "poolparty"

module Memory
  module Master
    # Get the average memory usage over the cloud
    def memory
      nodes.size > 0 ? nodes.inject(0) {|i,a| i += a.memory } / nodes.size : 0.0
    end
  end

  module Remote
    def memory
      out = begin
        str = run("free -m | grep -i mem")

        total_memory = str.split[1].to_f
        used_memory = str.split[2].to_f

        used_memory / total_memory
      rescue Exception => e
        0.0
      end
      PoolParty.message "Memory: #{out}"
      out  
    end
  end
  
end

PoolParty.register_monitor Memory