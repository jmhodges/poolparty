module PoolParty
  module Os
    
    class Node
      attr_accessor :ip, :name
      
      def initialize(info={})
        @ip = info[:ip]
        @name = info[:name]
      end
      
      def host_entry
        "#{@name}\t#{@ip}"
      end
      
      def haproxy_entry
        "server #{@name} #{@ip}:3010 weight 1 minconn 3 maxconn 6 check inter 30000"
      end
      
    end
    
  end
end