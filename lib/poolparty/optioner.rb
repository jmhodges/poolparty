module PoolParty
  class Optioner
    # Parse the command line options for options without a switch
    def self.parse(argv, safe=[])
      args = []
      # Default options
      safe.push "-v"
      safe.push "-i"
      
      argv.each_with_index do |arg,i|
        unless arg.index("-") == 0# && !arg.match(/(?:[^"']+)/)
          args << arg
        else          
          argv.shift unless safe.include?(arg)
        end
      end
      args
    end
  end
end