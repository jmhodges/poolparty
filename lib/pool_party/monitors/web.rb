module PoolParty
  extend self
  
  module Monitors
    class Memory < Monitor
      def monitor!
        web_performance = 0

        ab_command = "ab -n 3000 -c 5 -d -S -k " + instance_url

        IO.popen(ab_command) { |io|

        	loop do
        		line = io.gets

        		if line =~ /Time per request: .* \[ms\] (mean)/
        			stats = line.split
        			web_performance = stats[3].to_i
        			break
        		end
        	end
        	
      end
    end
  end
  
end