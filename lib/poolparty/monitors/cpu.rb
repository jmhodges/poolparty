=begin rdoc
  Basic monitor on the cpu stats
=end
module Cpu
  module Master
    def cpu
      nodes.size > 0 ? nodes.inject(0) {|i,a| i+=a.cpu } / nodes.size : 0.0
    end        
  end

  module Remote
    def cpu
      ssh("uptime").split(/\s+/)[-3].to_f rescue 0.0
    end
  end

end

PoolParty.register_monitor Cpu