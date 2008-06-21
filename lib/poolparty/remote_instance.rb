module PoolParty
  class RemoteInstance
    # ############################
    include Remoter
    # ############################
    include PoolParty
    include Callbacks
    
    attr_reader :ip, :instance_id, :name, :status, :launching_time, :stack_installed 
    attr_accessor :name, :number, :scp_configure_file, :configure_file, :plugin_string
    
    # CALLBACKS
    after :install, :mark_installed    
    
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
      "\tserver #{name} #{@ip}:#{Application.client_port} weight 1 minconn 3 maxconn 6 check inter 20000 check"
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
    def set_hosts(c)
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
      scp_basic_config_files

      Master.with_nodes do |node|
        # These are node-specific
        PoolParty.message "configuring #{node.name}"
        node.scp_specific_config_files
      end
      configure_basics_through_ssh
    end
    
    def configure_basics_through_ssh
      # -l #{Application.plugin_dir}
      cmd=<<-EOC
        #{update_plugin_string.join("\n").strip}        
        chmod 700 /etc/monit/monitrc        
        hostname -v #{name}
        /usr/bin/s3fs #{Application.shared_bucket} -o accessKeyId=#{Application.access_key} -o secretAccessKey=#{Application.secret_access_key} -o nonempty /data        
      EOC
      execute_tasks do
        ssh("#{setup_haproxy.strip}")
        ssh(cmd.runnable)
        ssh("pool maintain -c ~/.config")
      end
    end
    
    def setup_haproxy
      <<-EOS
        sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/haproxy
        sed '$d' < /etc/default/syslogd > /etc/default/syslogd2 ; mv /etc/default/syslogd2 /etc/default/syslogd
        echo 'SYSLOGD=-r' >> /etc/default/syslogd
        echo 'local0.* /var/log/haproxy.log' >> /etc/syslog.conf && /etc/init.d/sysklogd restart
        /etc/init.d/haproxy restart
      EOS
    end
    
    def scp_string(src,dest,opts={})
    end
    
    def scp_basic_config_files
      cmd=<<-EOC
        mkdir -p /etc/ha.d/resource.d
        mkdir -p /etc/monit
        mkdir -p /etc/monit.d
      EOC
      execute_tasks do
        scp(Application.heartbeat_authkeys_config_file, "/etc/ha.d", :dir => "/etc/ha.d/resource.d")
        scp(conf_file("cloud_master_takeover"), "/etc/ha.d/resource.d/cloud_master_takeover", :dir => "/etc/ha.d/resource.d/")

        scp(Application.config_file, "~/.config") if File.file?(Application.config_file)
        Dir["#{root_dir}/config/resource.d/*"].each do |file|
          scp(file, "/etc/ha.d/resource.d/#{File.basename(file)}")
        end
        scp(Application.monit_config_file, "/etc/monit/monitrc", :dir => "/etc/monit")
        Dir["#{root_dir}/config/monit.d/*"].each do |file|
          scp(file, "/etc/monit.d/#{File.basename(file)}")
        end
        
        `mkdir -p tmp/`
        File.open("tmp/pool-party-haproxy.cfg", 'w') {|f| f.write(Master.build_haproxy_file) }
        scp("tmp/pool-party-haproxy.cfg", "/etc/haproxy.cfg")
      end
    end
    def scp_specific_config_files
      execute_tasks({:dont_set_hosts => true}) do
        if Master.requires_heartbeat?
          hafile = "tmp/#{name}-pool-party-ha.cf"
          File.open(hafile, 'w') {|f| f.write(Master.build_heartbeat_config_file_for(self)) }
          single_scp(hafile, "/etc/ha.d/ha.cf")

          haresources_file = "tmp/#{name}-pool-party-haresources"
          File.open(haresources_file, 'w') {|f| f.write(Master.build_heartbeat_resources_file_for(self)) }
          single_scp(haresources_file, "/etc/ha/haresources", :dir => "/etc/ha")
        end
        hosts_file = "tmp/#{name}-pool-party-hosts"
        File.open(hosts_file, 'w') {|f| f.write(Master.build_hosts_file_for(self)) }
        single_scp(hosts_file, "/etc/hosts")
      end
    end
    
    # Installs with one commandline and an scp, rather than 10
    def install
      # unless stack_installed?
      #   execute_tasks do
      #     # scp(base_install_script, "~/base_install.sh")          
      #     ssh("chmod +x base_install.sh && /bin/sh base_install.sh && rm base_install.sh && echo 'installed!' ")
      #   end
      #   PoolParty.message "After install execute_tasks"
      #   mark_installed
      # end
    end
    # Login to store the authenticity
    def login_once
      run_now "ls -l"
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
    def update_plugin_string
      reset!
      str = "mkdir -p #{Application.plugin_dir} && cd #{Application.plugin_dir}\n"
      installed_plugins.each do |plugin_source|
        str << "git clone #{plugin_source}\n"
      end
    end
    def update_plugins(c)
      ssh(c.update_plugin_string)
    end
    after :configure, :update_plugins
    # Is this the master and if not, is the master running?
    def is_not_master_and_master_is_not_running?
      !master? && !Master.is_master_responding?
    end
    # User conf file if it exists, or default one
    def conf_file(name)
      user_conf = File.join(PoolParty.user_dir, "config", name)
      if File.file?(user_conf)
        File.join(PoolParty.user_dir, "config", name)
      else
        File.join(PoolParty.root_dir, "config", name)
      end        
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
      @stack_installed ||= run_now('if [ $(cat installed) == "installed" ]; then echo "installed in here"; fi') != ""
    end
    def mark_installed(caller=nil)
      run_now("echo 'installed' > ~/.installed")
      @stack_installed = true
    end
    def base_install_script
      "#{root_dir}/config/installers/#{Application.os.downcase}_install.sh"
    end
  end
end