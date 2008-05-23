module PoolParty
  class RemoteInstance
    attr_reader :ip, :instance_id, :name, :number, :status
    attr_accessor :name
    
    def initialize(obj)
      @ip = obj[:ip]
      @instance_id = obj[:instance_id]      
      @name = obj[:name] || "node"
      @number = obj[:number] || 0 # Defaults to the master
      @status = obj[:status] || "running"
    end
    
    # Host entry for this instance
    def hosts_entry
      "#{name}\t#{@ip}"
    end
    
    # Naming scheme internally
    def name
      "#{@name}#{@number}"
    end        
    # Entry for haproxy
    def haproxy_entry
      "server #{name} #{@ip}:#{Application.client_port} weight 1 check"
    end
    # Is this the master?
    def master?
      @number == 0
    end
    def status      
    end
    # Let's define some stuff for monit
    %w(stop start restart).each do |cmd|
      define_method "#{cmd}_with_monit" do
        ssh("monit #{cmd} all")
      end
    end
    def configure
      configure_hosts
      configure_haproxy
      configure_monit
    end
    # Some configures
    def configure_monit
      scp(Application.monit_config_file, "/etc/monit/monitrc")
      ssh("mkdir /etc/monit.d")
      Dir["#{File.dirname(Application.monit_config_file)}/monit/*"].each do |f|
        scp(f, "/etc/monit.d/#{File.basename(f)}")
      end
    end
    def configure_haproxy
      file = Master.new.build_haproxy_file
      scp(file.path, "/etc/haproxy.cfg")
    end
    def configure_hosts
      file = Master.new.build_hosts_file
      scp(file.path, "/etc/hosts")
    end
    def scp(src="", dest="")
      Kernel.system "scp -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}"
    end
    def ssh(cmd="")
      Kernel.system "ssh -i #{Application.keypair_path} #{Application.username}@#{@ip}#{cmd.empty? ? nil : " '#{cmd}'"}"
    end
    
    # Description in the rake task
    def description
      case @status
      when "running"
        "#{@number}: INSTANCE: #{name} - #{@ip} - #{@instance_id}"
      when "shutting-down"
        "(terminating) INSTANCE: #{name} - #{@ip} - #{@instance_id}"
      when "pending"
        "(booting) INSTANCE: #{name} - #{@ip} - #{@instance_id}"
      end
    end
    
    instance_eval "include PoolParty::Os::#{Application.os.capitalize}"
  end
end