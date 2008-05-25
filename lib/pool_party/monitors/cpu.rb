=begin rdoc
  Basic monitor on the cpu stats
=end
module PoolParty
  module Monitors
    module Cpu
      def self.monitor!
        IO.popen("uptime") do |up|
          @line = up.gets.split(/\s+/)          
        end
        @line[-3]
      end
    end
  end
end