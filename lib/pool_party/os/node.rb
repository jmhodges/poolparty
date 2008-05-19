module PoolParty
  module Os
    
    class Node
      attr_accessor :ip, :name
      
      def initialize(info={})
        @ip = info[:ip]
        @name = info[:name]
      end
      
      def host_entries
        
      end
      
    end
    
  end
end