module PoolParty
  class RemoteInstance
    include PoolParty # WTF -> why isn't message included
    include Callbacks
    
    attr_reader :ip, :instance_id, :name, :status, :launching_time, :stack_installed
    attr_accessor :name, :number
    
    def initialize(obj={})
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
    # Gets called everytime the cloud reloads itself
    # This is how the cloud reconfigures itself
    def configure
      configure_ruby
      configure_master if master?
      configure_master_failover if secondary?
      configure_linux
      configure_hosts      
      configure_haproxy
      configure_heartbeat if Master.requires_heartbeat?
      configure_s3fuse # Sets up /data
      configure_monit
    end
    # Setup the master tasks
    def configure_master
      message "configuring master (#{name})"      
      ssh("ps aux | grep ruby | awk '{ print $2 }' | xargs kill -9")
      ssh("pool maintain -c ~/.config") # Let's set it to maintain, ey?
    end
    def configure_master_failover
      message "Installing secondary master failover"
      ssh("mkdir /etc/ha.d/resource.d/")
      scp("config/cloud_master_takeover", "/etc/ha.d/resource.d/")
    end
    # Setup ruby on this instance
    def configure_ruby
      message "Configuring ruby, rubygems and pool party"
      install_ruby unless has?("ruby -v") 
      install_rubygems unless has?("gem1.8 -v") # Install ruby and the gems required to run the master
      install_required_gems unless has?("pool -h")
      scp(Application.config_file, "~/.config")
    end
    # Change the hostname for the instance
    def configure_linux
      ssh("hostname -v #{name}") rescue message "error in setting hostname"
    end
    # Configure s3fs if the bucket is specified in the config.yml
    def configure_s3fuse
      message("Configuring s3fuse")
      
      unless Application.shared_bucket.empty?
        install_s3fuse unless ssh("s3fs -v") =~ /missing\ bucket/
        ssh("/usr/bin/s3fs #{Application.shared_bucket} -ouse_cache=/tmp -o accessKeyId=#{Application.access_key} -o secretAccessKey=#{Application.secret_access_key} -o nonempty /data")
      end
    end
    # Configure heartbeat only if there is enough servers
    def configure_heartbeat
      message "Configuring heartbeat"
      install_heartbeat unless has?("/etc/init.d/heartbeat")
      
      file = write_to_temp_file(open(Application.heartbeat_authkeys_config_file).read.strip)
      scp(file.path, "/etc/ha.d/authkeys")
      
      file = Master.build_heartbeat_config_file_for(self)
      scp(file.path, "/etc/ha.d/ha.cf")
      
      file = Master.build_heartbeat_resources_file_for(self)
      scp(file.path, "/etc/ha.d/haresources")
      
      message "Installing services in config/resouce.d"
      ssh("mkdir /etc/ha.d/resource.d/")
      scp("config/resource.d/*", "/etc/ha.d/resource.d/", {:switches => "-r"})
      
      ssh("/etc/init.d/heartbeat start")
    end
    # Some configures for monit
    def configure_monit
      message "Configuring monit"
      install_monit unless has?("monit -V")
      
      scp(Application.monit_config_file, "/etc/monit/monitrc")
      ssh("mkdir /etc/monit.d")
      scp("#{File.dirname(Application.monit_config_file)}/monit/*", "/etc/monit.d/", {:switches => "-r"})
    end
    # Configure haproxy
    def configure_haproxy
      message "Configuring haproxy"
      install_haproxy unless has?("haproxy")
      
      file = Master.new.build_haproxy_file
      scp(file.path, "/etc/haproxy.cfg")
    end
    # Configure the hosts for the linux file
    def configure_hosts
      message "Configuring hosts"
      file = Master.build_hosts_file_for(self)
      scp(file.path, "/etc/hosts") rescue message("Error in uploading new /etc/hosts file")
    end
    # Restart all services with monit
    # Send a generic version command to test if the stdout contains
    # any information to test if the software is on the instance
    def has?(str)
      !ssh("#{str} -v").empty?
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
    
    # CALLBACKS
    after :install_stack, :configure # After we install the stack, let's make sure we configure it too
    before :configure, :mark_installed # We want to make sure
    after :configure, :restart_with_monit # Anytime we configure the server, we want the server to restart it's services
  end
end