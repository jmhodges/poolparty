module PoolParty
  extend self
  
  module Monitors
    class Memory < Monitor
      def monitor!
        free_memory = 0

        # run free measurement 6 times with a delay of 10 seconds between measurements
        6.downto(1) {
          IO.popen("free -m") { |io|
            # we can discard the first two lines of output
            io.gets; io.gets

            # get an array of all tokens returned by free
            stats = io.gets.split

            # we're only interested in the fourth item in the array
            free_memory += stats[3].to_i
          }
          sleep(10)
        }
        free_memory / 6 # return the average free memory available for all 6 measurements
      end
    end
  end
  
end