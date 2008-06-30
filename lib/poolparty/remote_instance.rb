module PoolParty
  class RemoteInstance
    # ############################
    include Remoter
    # ############################
    include PoolParty
    include Callbacks
    include FileWriter
    
    attr_reader :ip, :instance_id, :name, :status, :launching_time, :stack_installed, :keypair 
    attr_accessor :name, :number, :scp_configure_file, :configure_file, :plugin_string, :keypair
    
    # CALLBACKS
    after :install, :mark_installed
    after :configure, :associate_public_ip
    def initialize(obj={})
      super
      
      @ip = obj[:ip]
      @instance_id = obj[:instance_id]      
      @name = obj[:name] || "node"
      @number = obj[:number] || 0 # Defaults to the master
      @status = obj[:status] || "running"
      @launching_time = obj[:launching_time] || Time.now
      @keypair = obj[:keypair] || Application.keypair
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
    def configure_tasks
      {
        :move_hostfile => change_hostname,
        :config_master => configure_master,
        :move_config_file => move_config_file,
        :set_hostname => change_hostname,
        :mount_s3_drive => mount_s3_drive,
        :update_plugins => update_plugin_string,
        :configure_monit => configure_monit,
        :configure_authkeys => configure_authkeys,
        :configure_resource_d => configure_resource_d,
        :configure_haproxy => setup_haproxy,
        :configure_heartbeat => configure_heartbeat,
        :user_tasks => user_tasks
      }
    end
    def user_tasks
      @@user_tasks ||= []
    end
    def move_config_file
      <<-EOC
        mv #{remote_base_tmp_dir}/config.yml ~/.config
        mkdir -p ~/.ec2
        mv #{remote_base_tmp_dir}/keypair ~/.ec2/id_rsa-#{Application.keypair}
      EOC
    end
    def configure_heartbeat
      <<-EOC
        mv #{remote_base_tmp_dir}/ha.cf /etc/ha.d/ha.cf
        /etc/init.d/heartbeat start
      EOC
    end    
    def configure_authkeys
      <<-EOC
        mkdir -p /etc/ha.d
        mv #{remote_base_tmp_dir}/authkeys /etc/ha.d/
      EOC
    end
    
    def configure_master
      if master?
        <<-EOC
          pool maintain -c ~/.config -l ~/plugins
        EOC
      else
        ""
      end
    end
    
    def configure_resource_d
      <<-EOC
        mkdir -p /etc/ha.d/resource.d
        mv #{remote_base_tmp_dir}/cloud_master_takeover /etc/ha.d/resource.d
        mv #{remote_base_tmp_dir}/resource.d/* /etc/ha.d/resource.d
      EOC
    end
    
    def configure_monit
      <<-EOC
        mv #{remote_base_tmp_dir}/monitrc /etc/monit/monitrc
        mkdir -p /etc/monit.d/
        mv #{remote_base_tmp_dir}/monit.d/* /etc/monit.d/
        chown #{Application.username} /etc/monit/monitrc
        chmod 700 /etc/monit/monitrc
      EOC
    end
    
    def change_hostname
      <<-EOC
        mv #{remote_base_tmp_dir}/#{name}-hosts /etc/hosts
        hostname -v #{name}
      EOC
    end
    
    def setup_haproxy
      <<-EOS
        mv #{remote_base_tmp_dir}/haproxy /etc/haproxy.cfg
        sed -i "s/ENABLED=0/ENABLED=1/g" /etc/default/haproxy
        sed -i 's/SYSLOGD=""/SYSLOGD="-r"/g' /etc/default/syslogd
        echo "local0.* /var/log/haproxy.log" >> /etc/syslog.conf && /etc/init.d/sysklogd restart
        /etc/init.d/haproxy restart
      EOS
    end
    
    def mount_s3_drive
      if Application.shared_bucket.empty?
        ""
      else
        <<-EOC
          mkdir -p /data && /usr/bin/s3fs #{Application.shared_bucket} -o accessKeyId=#{Application.access_key} -o secretAccessKey=#{Application.secret_access_key} -o nonempty /data
        EOC
      end
    end        
    # Installs with one commandline and an scp, rather than 10
    def install
    end
    # Login to store the authenticity
    def login_once
      run_now "ls -l"
    end
    # Associate a public ip if it is set and this is the master
    def associate_public_ip(c)
      associate_address_with(Application.public_ip, @instance_id) if master? && Application.public_ip && !Application.public_ip.empty?
    end
    # Become the new master
    def become_master
      @master = Master.new
      @number = 0
      @master.nodes[0] = self
      @master.configure_cloud
      configure
    end
    # Placeholder
    def configure      
    end
    def update_plugin_string
      dir = File.basename(Application.plugin_dir)
      "mkdir -p #{dir} && tar -zxf plugins.tar.gz -C #{dir}"
    end
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
      @stack_installed ||= false
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