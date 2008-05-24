module PoolParty
  class RemoteInstance
    include PoolParty # WTF -> why isn't message included
    
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
    def node_entry
      "node #{name}"
    end    
    # Naming scheme internally
    def name
      "#{@name}#{@number}"
    end        
    def heartbeat_entry
      "#{name} #{ip} #{Application.managed_services}"
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
      configure_master if master?
      configure_linux
      configure_hosts
      configure_haproxy
      configure_s3fuse
      configure_monit      
    end
    def configure_master
      message "configuring master (#{name})"
    end
    def configure_linux
      ssh("'hostname -v #{name}'") rescue message "error in setting hostname"
    end
    def configure_s3fuse
      message("Configuring s3fuse")
      unless Application.shared_bucket.empty?
        install_s3fuse unless ssh("s3fs -v") =~ /missing\ bucket/
        ssh("/usr/bin/s3fs #{Application.shared_bucket} -ouse_cache=/tmp -o accessKeyId=#{Application.access_key_id} -o secretAccessKey=#{Application.secret_access_key} -o nonempty /data")
      end      
    end
    def configure_heartbeat
      message "Configuring heartbeat"
      install_heartbeat unless has?("heartbeat")
      
      file = write_to_temp_file(open(Application.heartbeat_authkeys_config_file).read.strip)
      scp(file.path, "/etc/ha.d/authkeys")
      file = Master.new.build_heartbeat_config_file
      scp(file.path, "/etc/ha.d/ha.cf")
      
      servers=<<-EOS        
#{nodes.collect {|node| node.haproxy_entry}.join("\n")}
      EOS
      file = write_to_temp_file(servers)
      scp(file.path, "/etc/ha.d/haresources")
    end
    # Some configures
    def configure_monit
      message "Configuring monit"
      install_monit unless has?("monit -V")
      
      scp(Application.monit_config_file, "/etc/monit/monitrc")
      ssh("mkdir /etc/monit.d")
      Dir["#{File.dirname(Application.monit_config_file)}/monit/*"].each do |f|
        scp(f, "/etc/monit.d/#{File.basename(f)}")
      end
    end
    def configure_haproxy
      message "Configuring haproxy"
      install_haproxy unless has?("haproxy")
      
      file = Master.new.build_haproxy_file
      scp(file.path, "/etc/haproxy.cfg")
    end
    def configure_hosts
      file = Master.new.build_hosts_file
      scp(file.path, "/etc/hosts") rescue message "Error in uploading new /etc/hosts file"
    end
    def has?(str)
      !ssh("#{str} -v").empty?
    end
    def scp(src="", dest="")
      `scp -i #{Application.keypair_path} #{src} #{Application.username}@#{@ip}:#{dest}`
    end
    def ssh(cmd="")
      ssh = "ssh -i #{Application.keypair_path} #{Application.username}@#{@ip}"
      if cmd.empty?
        system "#{ssh}"
      else
        %x[#{ssh} '#{cmd.runnable}']
      end
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