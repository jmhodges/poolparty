module PoolParty
  class RemoteInstance
    include PoolParty # WTF -> why isn't message included
    
    attr_reader :ip, :instance_id, :name, :number, :status, :launching_time
    attr_accessor :name
    
    def initialize(obj)
      @ip = obj[:ip]
      @instance_id = obj[:instance_id]      
      @name = obj[:name] || "node"
      @number = obj[:number] || 0 # Defaults to the master
      @status = obj[:status] || "running"
      @launching_time = obj[:launching_time] || Time.now
    end
    
    # Host entry for this instance
    def hosts_entry
      "#{name}\t#{@ip}"
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
      "#{name}\t#{@ip}"
    end
    # Is this the master?
    def master?
      @number == 0
    end
    # Status of the remote instance - contains the 
    # load of the remote instance
    def status
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
      configure_master if master?
      configure_linux
      configure_hosts
      configure_haproxy
      configure_heartbeat if Master.requires_heartbeat?
      configure_s3fuse
      configure_monit      
    end
    # Setup the master tasks
    def configure_master
      message "configuring master (#{name})"
    end
    # Change the hostname for the instance
    def configure_linux
      ssh("'hostname -v #{name}'") rescue message "error in setting hostname"
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
      install_heartbeat unless has?("heartbeat")
      
      file = write_to_temp_file(open(Application.heartbeat_authkeys_config_file).read.strip)
      scp(file.path, "/etc/ha.d/authkeys")
      
      file = Master.new.build_heartbeat_config_file_for(self)
      scp(file.path, "/etc/ha.d/ha.cf")
      
      file = Master.new.build_heartbeat_resources_file_for(self)
      scp(file.path, "/etc/ha.d/haresources")
    end
    # Some configures for monit
    def configure_monit
      message "Configuring monit"
      install_monit unless has?("monit -V")
      
      scp(Application.monit_config_file, "/etc/monit/monitrc")
      ssh("mkdir /etc/monit.d")
      Dir["#{File.dirname(Application.monit_config_file)}/monit/*"].each do |f|
        scp(f, "/etc/monit.d/#{File.basename(f)}")
      end
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
      file = Master.new.build_hosts_file
      scp(file.path, "/etc/hosts") rescue message "Error in uploading new /etc/hosts file"
    end
    # Send a generic version command to test if the stdout contains
    # any information to test if the software is on the instance
    def has?(str)
      !ssh("#{str} -v").empty?
    end
    
    # MONITORS
    # Monitor the number of web requests that can be accepted at a time
    def web_status_level
      Web.monitor_from_string ssh("httperf --server localhost --port #{Application.port} --num-conn 3 --timeout 5 | grep 'Request rate'")
    end
    # Monitor the cpu status of the instance
    def cpu_status_level
      Cpu.monitor_from_string ssh("uptime")
    end
    # Monitor the memory
    def memory_status_level
      Memory.monitor_from_string ssh("free -m | grep -i mem")
    end
    
    # Scp src to dest on the instance
    def scp(src="", dest="")
      `scp -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}`
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
    # Include the os specific tasks as specified in the application options (config.yml)
    instance_eval "include PoolParty::Os::#{Application.os.capitalize}"
  end
end