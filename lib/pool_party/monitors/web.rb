module PoolParty
  extend self
  
  module Monitors
    class Memory < Monitor
      def monitor!
        IO.popen("httperf --server localhost --port #{Application.port} --num-conn 3 --timeout 5 | grep 'Request rate'") do |io|
          @req = io.gets.gsub(/.* (\d*\.\d*) req\/s .*/, $1).chomp.to_f
        end
        @req
      end
    end
  end
  
end