module PoolParty
  extend self
  
  module Monitors
    class Cpu < Monitor
      def monitor!
        cpu_load = 0

        # run vmstat measurement 6 times with a delay of 10 seconds between measurements
        IO.popen("vmstat -n 10 6") { |io|
          # the first line of input is the header; we can discard it
          io.gets

          6.downto(1) {
            # get an array of all integers returned by vmstat
            stats = io.gets.split

            # sum together the run queue load
            cpu_load += stats[0].to_i
          }
        }
        cpu_load
      end
    end
  end
end