module PoolParty
  module Os
    
    class Node
      attr_accessor :ip, :name, :number
      
      def initialize(info={})
        @ip = info[:ip]
        @name = info[:name] || "node"
        @number = info[:number] || 1
      end
      
      def host_entry
        "#{@name}\t#{@ip}"
      end
      
      def name
        "#{@name}-#{@number}"
      end
      
      def haproxy_entry
        "server #{name} #{@ip}:#{Application.client_port} weight 1 minconn 3 maxconn 6 check inter 30000"
      end
      
    end
    
  end
end