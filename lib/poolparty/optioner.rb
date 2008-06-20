module PoolParty
  class Optioner
    # Parse the command line options for options without a switch
    def self.parse(argv, safe=[])
      args = []
      argv.each_with_index do |arg,i|
        unless arg.index("-")
          args << arg 
        else
          argv.delete_at(i+1) unless safe.include?(arg)
        end
      end
      args
    end
  end
end