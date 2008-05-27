=begin rdoc
  Basic monitor on the cpu stats
=end
module PoolParty
  module Monitors
    module Cpu
      def self.monitor!
        IO.popen("uptime") do |up|
          ret = monitor_from_string(up)
        end
        ret
      end
      def self.monitor_from_string(str="")
        str.split(/\s+/)[-3].to_f
      end
    end
  end
end