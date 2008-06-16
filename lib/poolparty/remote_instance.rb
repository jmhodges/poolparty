module PoolParty
  class RemoteInstance
    # ############################
    include Remoter # Included for legacy reasons.
    # ############################
    include PoolParty
    include Callbacks    
    
    attr_reader :ip, :instance_id, :name, :status, :launching_time, :stack_installed
    attr_accessor :name, :number
    
    # CALLBACKS
    before :configure, :mark_installed # We want to make sure
    after :install, :configure # After we install the stack, let's make sure we configure it too
    # after :configure, :restart_with_monit # Anytime we configure the server, we want the server to restart it's services
    
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
    def set_hosts
      Master.set_hosts
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
    def configure(caller=nil)
      associate_public_ip
      file = Master.build_scp_instances_script_for(self)
      Kernel.system("chmod +x #{file.path} && /bin/sh #{file.path}")
      
      file = Master.build_reconfigure_instances_script_for(self)
      scp(file.path, "/usr/local/src/reconfigure.sh")
      ssh("chmod +x /usr/local/src/reconfigure.sh && /bin/sh /usr/local/src/reconfigure.sh")
    end
    
    def set_hosts(c)
      ssh_location = `which ssh`.gsub(/\n/, '')
      rsync_location = `which rsync`.gsub(/\n/, '')
      rt.set :user, Application.username
      rt.set :domain, "#{user}@#{self.ip}"
      rt.set :application, Application.app_name
      # rt.set :ssh_cmd, ssh_location
      # rt.set :rsync_cmd, rsync_location
      rt.set :ssh_flags, "-i #{Application.keypair_path}"
      rt.set :rsync_flags , ['-azP', '--delete', "-e '#{ssh_location} -l #{Application.user} -i #{Application.keypair_path} -o StrictHostKeyChecking=no'"]

      Master.with_nodes { |node|
        rt.host "#{Application.user}@#{node.ip}",:app if node.status =~ /running/
      }
    end
    
    def scp local, remote
      data = open(local).read
      rtask(:scp) do
        rsync local, remote
      end.execute
    end
    before :scp, :set_hosts
    
    def ssh command="ls -l", &block
      blk = Proc.new do
        run "\"#{command.runnable}\""
      end
      ssh = "ssh -i #{Application.keypair_path} #{Application.username}@#{@ip} "

      command.empty? ? system("#{ssh}") : rtask(:ssh, &blk).execute
    end
    before :ssh, :set_hosts
    
    # Installs with one commandline and an scp, rather than 10
    def install      
      scp(base_install_script, "~/base_install.sh")
      ssh("chmod +x base_install.sh && /bin/sh base_install.sh")
    end
    # Associate a public ip if it is set and this is the master
    def associate_public_ip
      associate_address_with(Application.public_ip, @instance_id) if master? && Application.public_ip && !Application.public_ip.empty?
    end
    # Become the new master
    def become_master
      @master = Master.new
      @number = 0
      @master.nodes[0] = self
      configure
    end
    def update_plugin_string(caller)
      reset!
      str = "cd ~\n"
      installed_plugins.each do |plugin_source|
        str << "git clone #{plugin_source}\n"
      end
      str.runnable
    end
    after :become_master, :update_plugin_string
    
    # Is this the master and if not, is the master running?
    def is_not_master_and_master_is_not_running?
      !master? && !Master.is_master_responding?
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
    def mark_installed(caller=nil)
      @stack_installed = true
    end
    def base_install_script
      "#{root_dir}/config/installers/#{Application.os.downcase}_install.sh"
    end
  end
end