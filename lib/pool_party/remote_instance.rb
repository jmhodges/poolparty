module PoolParty
  class RemoteInstance
    include PoolParty
    include Callbacks
    
    attr_reader :ip, :instance_id, :name, :status, :launching_time, :stack_installed
    attr_accessor :name, :number
    
    # CALLBACKS
    before :configure, :mark_installed # We want to make sure
    after :install, :configure # After we install the stack, let's make sure we configure it too
    after :configure, :restart_with_monit # Anytime we configure the server, we want the server to restart it's services
    
    def initialize(obj={})
      super
      
      @ip = obj[:ip]
      @instance_id = obj[:instance_id]      
      @name = obj[:name] || "node"
      @number = obj[:number] || 0 # Defaults to the master
      @status = obj[:status] || "running"
      @launching_time = obj[:launching_time] || Time.now
    end
    
    # Host entry for this instance
    def hosts_entry
      "#{@ip} #{name}"
    end
    # Internal host entry for this instance
    def local_hosts_entry
      "127.0.0.1 #{name}\n127.0.0.1 localhost.localdomain localhost ubuntu"
    end
    # Node entry for heartbeat
    def node_entry
      "node #{name}"
    end    
    # Internal naming scheme
    def name
      "#{@name}#{@number}"
    end
    # Entry for the heartbeat config file
    def heartbeat_entry
      "#{name} #{ip} #{Application.managed_services}"
    end
    # Entry for haproxy
    def haproxy_entry
      "server #{name} #{@ip}:#{Application.client_port} weight 1 check"
    end
    def haproxy_resources_entry
      "#{name} #{@ip}"
    end
    # Is this the master?
    def master?
      @number == 0
    end
    def secondary?
      @number == 1
    end
    # Let's define some stuff for monit
    %w(stop start restart).each do |cmd|
      define_method "#{cmd}_with_monit" do
        ssh("monit #{cmd} all")
      end
    end
    # Configure the server with the new, sexy shell script
    # This compiles all the scp commands into a shell script and then executes it
    # then it will compile a list of the commands to operate on the instance
    # and execute it
    # This is how the cloud reconfigures itself
    def configure
      associate_public_ip
      file = Master.build_scp_instances_script_for(self)
      Kernel.system("chmod +x #{file.path} && /bin/sh #{file.path}")
      
      file = Master.build_reconfigure_instances_script_for(self)
      scp(file.path, "/usr/local/src/reconfigure.sh")
      ssh("chmod +x /usr/local/src/reconfigure.sh && /bin/sh /usr/local/src/reconfigure.sh")
    end
    # Installs with one commandline and an scp, rather than 10
    def install
      scp(base_install_script, "/usr/local/src/base_install.sh")
      ssh("chmod +x /usr/local/src/base_install.sh && /bin/sh /usr/local/src/base_install.sh")
    end
    # Associate a public ip if it is set and this is the master
    def associate_public_ip
      associate_address_with(Application.public_ip, @instance_id) if master? && Application.public_ip && !Application.public_ip.empty?
    end
    # MONITORS
    # Monitor the number of web requests that can be accepted at a time
    def web
      Monitors::Web.monitor_from_string ssh("httperf --server localhost --port #{Application.client_port} --num-conn 3 --timeout 5 | grep 'Request rate'") rescue 0.0
    end
    # Monitor the cpu status of the instance
    def cpu
      Monitors::Cpu.monitor_from_string ssh("uptime") rescue 0.0
    end
    # Monitor the memory
    def memory
      Monitors::Memory.monitor_from_string ssh("free -m | grep -i mem") rescue 0.0
    end
    def become_master
      @master = Master.new
      @number = 0
      @master.nodes[0] = self
      configure
    end
    def is_not_master_and_master_is_not_running?
      !master? && !Master.is_master_responding?
    end
    # Scp src to dest on the instance
    def scp(src="", dest="", opts={})
      `scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}`
    end
    def scp_string(src,dest,opts={})
      "scp #{opts[:switches]} -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}"
    end
    # Ssh into the instance or run a command, if the cmd is set
    def ssh(cmd="")
      ssh = "ssh -i #{Application.keypair_path} #{Application.username}@#{@ip}"

      cmd.empty? ? system("#{ssh}") : %x[#{ssh} '#{cmd.runnable}']
    end
    
    # Description in the rake task
    def description
      case @status
      when "running"
        "#{@number}: INSTANCE: #{name} - #{@ip} - #{@instance_id} - #{@launching_time}"
      when "shutting-down"
        "(terminating) INSTANCE: #{name} - #{@ip} - #{@instance_id} - #{@launching_time}"
      when "pending"
        "(booting) INSTANCE: #{name} - #{@ip} - #{@instance_id} - #{@launching_time}"
      end
    end
    def stack_installed?
      @stack_installed == true
    end
    def mark_installed
      @stack_installed = true
    end
    # Include the os specific tasks as specified in the application options (config.yml)
    instance_eval "include PoolParty::Os::#{Application.os.capitalize}"
    
    def base_install_script
      "#{root_dir}/config/installers/#{Application.os.downcase}_install.sh"
    end
  end
end