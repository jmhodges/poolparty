module PoolParty
  module Monitors
    module Memory
      def self.monitor!
        IO.popen("free -m | grep -i mem") { |io|
          line = io.gets.split

          @total_memory = line[1].to_f
          # we're only interested in the fourth item in the array
          @used_memory = line[2].to_f
        }
        used_memory / total_memory
      end
    end
  end
end