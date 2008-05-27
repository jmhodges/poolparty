=begin rdoc
  Basic memory monitor on the instance
=end
module PoolParty
  module Monitors
    module Memory
      def self.monitor!
        IO.popen("free -m | grep -i mem") { |io|
          ret = monitor_from_string(io)
        }
        ret
      end
      def self.monitor_from_string(str="")
        total_memory = str.split[1].to_f
        used_memory = str.split[2].to_f
        
        used_memory / total_memory
      end
    end
  end
end