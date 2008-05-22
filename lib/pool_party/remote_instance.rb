module PoolParty
  class RemoteInstance
    attr_reader :ip, :instance_id, :name, :number, :status
    attr_accessor :name
    
    def initialize(obj)
      @ip = obj[:ip]
      @instance_id = obj[:instance_id]      
      @name = obj[:name] || "node"
      @number = obj[:number] || 1
      @status = obj[:status] || "running"
    end
    
    def host_entry
      "#{name}\t#{@ip}"
    end
    
    def name
      "#{@name}-#{@number}"
    end    
    
    def haproxy_entry
      "server #{name} #{@ip}:#{Application.client_port} weight 1 minconn 3 maxconn 6 check inter 30000"
    end
    
    def description
      case @status
      when "running"
        "INSTANCE: #{name} - #{@ip} - #{@instance_id}"
      when "shutting-down"
        "(terminating) INSTANCE: #{name} - #{@ip} - #{@instance_id}"
      when "pending"
        "(booting) INSTANCE: #{name} - #{@ip} - #{@instance_id}"
      end
    end    
  end
end