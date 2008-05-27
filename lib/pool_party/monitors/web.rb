=begin rdoc
  Monitor the web stats for the request rate the server can handle at a time
=end
module PoolParty
  module Monitors
    module Web
      def self.monitor!(port)
        IO.popen("httperf --server localhost --port #{port} --num-conn 3 --timeout 5 | grep 'Request rate'") do |io|
          @req = monitor_from_string(io.gets)
        end
        @req
      end
      def self.monitor_from_string(str="")
        p str.gsub(/([a-zA-Z\s])+/, '')
        str.gsub(/.* (\d*\.\d*) req\/s .*/, $1).chomp.to_f
      end
    end
  end
end