=begin rdoc
  Monitor the web stats for the request rate the server can handle at a time
=end
module PoolParty
  module Monitors
    module Web
      def self.monitor!(port)
        IO.popen("httperf --server localhost --port #{port} --num-conn 3 --timeout 5 | grep 'Request rate'") do |io|
          @req = io.gets.gsub(/.* (\d*\.\d*) req\/s .*/, $1).chomp.to_f
        end
        @req
      end
    end
  end
end