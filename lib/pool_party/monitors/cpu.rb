module PoolParty
  extend self
  
  module Monitors
    class Cpu < Monitor
      def monitor!
        IO.popen("uptime") do |up|
          @line = up.gets.split(/\s+/)          
        end
        @line[-3]
      end
    end
  end
end