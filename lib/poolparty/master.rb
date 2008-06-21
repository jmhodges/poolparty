=begin rdoc
  The basic master for PoolParty
=end
module PoolParty
  class Master < Remoting
    include Aska
    include Callbacks
    include Monitors
    include Remoter
    
    def initialize
      super
      
      self.class.send :rules, :contract_when, Application.options.contract_when
      self.class.send :rules, :expand_when, Application.options.expand_when
    end
    # Start the cloud
    def start_cloud!
      start!
    end
    alias_method :start_cloud, :start_cloud!
    # Start the cloud, which launches the minimum_instances
    def start!
      message "Launching minimum_instances"
      launch_minimum_instances
      message "Waiting for master to boot up" 
      reset!
      while !number_of_pending_instances.zero?
        wait "2.seconds" unless Application.test?
        waited = true
        reset!
      end
      unless Application.test? || waited.nil?
        message "Give some time for the instance ssh to start up"
        wait "15.seconds"
      end
      install_cloud if Application.install_on_load?
      configure_cloud
    end
    alias_method :start, :start!
    def configure_cloud
      message "Configuring master"
      master = get_node 0      
      master.configure
    end
    def install_cloud
      update_apt_string =<<-EOE        
        echo 'deb http://mirrors.cs.wmich.edu/ubuntu hardy main universe' >> /etc/apt/sources.list
        sudo apt-get update --fix-missing
      EOE
      Master.with_nodes do |node|
        node.run_now update_apt_string
      end
      Provider.install_poolparty(nodes.collect {|a| a.ip })
    end
    # Launch the minimum number of instances. 
    def launch_minimum_instances
      request_launch_new_instances(Application.minimum_instances - number_of_pending_and_running_instances)
      nodes
    end
    # Start monitoring the cloud with the threaded loop
    def start_monitor!
      begin
        trap("INT") do
          on_exit
          exit
        end
        # Daemonize only if we are not in the test environment
        run_thread_loop(:daemonize => !Application.test?) do
          add_task {launch_minimum_instances} # If the base instances go down...
          add_task {reconfigure_cloud_when_necessary}
          add_task {scale_cloud!}
          add_task {check_stats}
        end
      rescue Exception => e
        puts "There was an error: #{e.nice_message}"
      end
    end
    alias_method :start_monitor, :start_monitor!
    def user_tasks
      puts "in user_tasks"
    end
    # Sole purpose to check the stats, mainly in a plugin
    def check_stats
    end
    # Add an instance if the cloud needs one ore terminate one if necessary
    def scale_cloud!
      add_instance_if_load_is_high
      terminate_instance_if_load_is_low
    end
    alias_method :scale_cloud, :scale_cloud!
    # Tough method:
    # We need to make sure that all the instances have the required software installed
    # This is a basic check against the local store of the instances that have the 
    # stack installed.
    def reconfigure_cloud_when_necessary
      reconfigure_running_instances if number_of_unconfigured_nodes > 0
    end
    alias_method :reconfiguration, :reconfigure_cloud_when_necessary
    def number_of_unconfigured_nodes
      nodes.reject {|a| a.stack_installed? }.size
    end
    def grow_by_one
      request_launch_new_instance      
      self.class.get_master.configure
    end
    def shrink_by_one
      node = nodes.reject {|a| a.master? }[-1]
      request_termination_of_instance(node.instance_id) if node
    end
    # Add an instance if the load is high
    def add_instance_if_load_is_high
      request_launch_new_instance if expand?
    end
    alias_method :add_instance, :add_instance_if_load_is_high
    # Teardown an instance if the load is pretty low
    def terminate_instance_if_load_is_low
      if contract?
        shrink_by_one
      end
    end
    alias_method :terminate_instance, :terminate_instance_if_load_is_low
    # FOR MONITORING
    def contract?
      valid_rules?(:contract_when)
    end
    def expand?
      valid_rules?(:expand_when)
    end
    # Restart the running instances services with monit on all the nodes
    def restart_running_instances_services
      nodes.each do |node|
        node.restart_with_monit
      end
    end
    # Reconfigure the running instances
    # Since we are using vlad, running configure on one of the instances
    # should configure all of the instances. We set the hosts in this file
    def reconfigure_running_instances      
      # nodes.each do |node|
      #   node.configure if node.status =~ /running/
      # end
      master = get_node(0)
      master.configure
    end
    # Build the basic haproxy config file from the config file in the config directory and return a tempfile
    def build_haproxy_file
      servers=<<-EOS
#{nodes.collect {|node| node.haproxy_entry}.join("\n")}
      EOS
      open(Application.haproxy_config_file).read.strip ^ {:servers => servers, :host_port => Application.host_port}
    end
    # Build the hosts file and return a tempfile
    def build_hosts_file
      write_to_temp_file(nodes.collect {|a| a.hosts_entry }.join("\n"))
    end
    # Build host file for a specific node
    def build_hosts_file_for(n)
      servers=<<-EOS        
#{nodes.collect {|node| node.ip == n.ip ? node.local_hosts_entry : node.hosts_entry}.join("\n")}
      EOS
      servers
    end
    # Build the basic auth file for the heartbeat
    def build_heartbeat_authkeys_file
      write_to_temp_file(open(Application.heartbeat_authkeys_config_file).read)
    end
    # Build heartbeat config file
    def build_heartbeat_config_file_for(node)
      servers = "#{node.node_entry}\n#{get_next_node(node).node_entry}"
      open(Application.heartbeat_config_file).read.strip ^ {:nodes => servers}
    end
    # Return a list of the nodes and cache them
    def nodes
      @nodes ||= list_of_nonterminated_instances.collect_with_index do |inst, i|
        RemoteInstance.new(inst.merge({:number => i}))
      end
    end
    # Get the node at the specific index from the cached nodes
    def get_node(i=0)
      nodes.select {|a| a.number == i.to_i}.first
    end
    # Get the next node in sequence, so we can configure heartbeat to monitor the next node
    def get_next_node(node)
      i = node.number + 1
      i = 0 if i >= nodes.size
      get_node(i)
    end
    # On exit command
    def on_exit      
    end
    # List the clouds
    def list
      if number_of_pending_and_running_instances > 0
        out = "-- CLOUD (#{number_of_pending_and_running_instances})--\n"
        out << nodes.collect {|node| node.description }.join("\n")
      else
        out = "Cloud is not running"
      end
      out
    end
    # Reset and clear the caches
    def reset!
      @cached_descriptions = nil
      @nodes = nil
    end
    
    class << self
      include PoolParty
            
      def with_nodes(&block)
        new.nodes.each &block
      end
      
      def collect_nodes(&block)
        new.nodes.collect &block
      end
      
      def requires_heartbeat?
        new.nodes.size > 1
      end
      def is_master_responding?
        `ping -c1 -t5 #{get_master.ip}`
      end
      def get_master
        new.nodes[0]
      end
      def get_next_node(node)
        new.get_next_node(node)
      end
      # Build a heartbeat_config_file from the config file in the config directory and return a tempfile
      def build_heartbeat_config_file_for(node)
        return nil unless node
        new.build_heartbeat_config_file_for(node)
      end
      # Build a heartbeat resources file from the config directory and return a tempfile
      def build_heartbeat_resources_file_for(node)
        return nil unless node
        "#{node.haproxy_resources_entry}\n#{get_next_node(node).haproxy_resources_entry}"
      end
      # Build hosts files for a specific node
      def build_hosts_file_for(node)
        new.build_hosts_file_for(node)
      end
      # Build the scp script for the specific node
      def build_scp_instances_script_for(node)
        authkeys_file = write_to_temp_file(open(Application.heartbeat_authkeys_config_file).read.strip)
        if Master.requires_heartbeat?
          ha_d_file =  Master.build_heartbeat_config_file_for(node)
          haresources_file = Master.build_heartbeat_resources_file_for(node)
        end
        haproxy_file = Master.build_haproxy_file
        hosts_file = Master.build_hosts_file_for(node)        
                
        str = open(Application.sh_scp_instances_script).read.strip ^ {
            :cloud_master_takeover => "#{node.scp_string("#{root_dir}/config/cloud_master_takeover", "/etc/ha.d/resource.d/", :dir => "/etc/ha.d/resource.d")}",
            :config_file => "#{node.scp_string(Application.config_file, "~/.config")}",
            :authkeys => "#{node.scp_string(authkeys_file.path, "/etc/ha.d/authkeys", :dir => "/etc/ha.d/")}",
            :resources => "#{node.scp_string("#{root_dir}/config/resource.d/*", "/etc/ha.d/resource.d/", {:switches => "-r"})}",
            :monitrc => "#{node.scp_string(Application.monit_config_file, "/etc/monit/monitrc", :dir => "/etc/monit")}",
            :monit_d => "#{node.scp_string("#{File.dirname(Application.monit_config_file)}/monit/*", "/etc/monit.d/", {:switches => "-r", :dir => "/etc/monit.d/"})}",
            :haproxy => "#{node.scp_string(haproxy_file, "/etc/haproxy.cfg")}",
            
            :ha_d => Master.requires_heartbeat? ? "#{node.scp_string(ha_d_file, "/etc/ha.d/ha.cf")}" : "",
            :haresources => Master.requires_heartbeat? ? "#{node.scp_string(haresources_file, "/etc/ha.d/ha.cf")}" : "",
            
            :hosts => "#{node.scp_string(hosts_file, "/etc/hosts")}"
          }
        write_to_temp_file(str)
      end
      # Build basic configuration script for the node
      def build_reconfigure_instances_script_for(node)
        str = open(Application.sh_reconfigure_instances_script).read.strip ^ {
          :config_master => "#{node.update_plugin_string}",
          :start_pool_maintain => "pool maintain -c ~/.config -l ~/plugins",
          :set_hostname => "hostname -v #{node.name}",
          :start_s3fs => "/usr/bin/s3fs #{Application.shared_bucket} -o accessKeyId=#{Application.access_key} -o secretAccessKey=#{Application.secret_access_key} -o nonempty /data"
        }
        write_to_temp_file(str)        
      end
      
      def set_hosts(c, remotetask=nil)
        unless remotetask.nil?
          rt = remotetask
        end
        
        ssh_location = `which ssh`.gsub(/\n/, '')
        rsync_location = `which rsync`.gsub(/\n/, '')
        rt.set :user, Application.username
        # rt.set :domain, "#{Application.user}@#{ip}"
        rt.set :application, Application.app_name
        rt.set :ssh_flags, "-i #{Application.keypair_path} -o StrictHostKeyChecking=no"
        rt.set :rsync_flags , ['-azP', '--delete', "-e '#{ssh_location} -l #{Application.username} -i #{Application.keypair_path} -o StrictHostKeyChecking=no'"]
        
        master = get_master
        rt.set :domain, "#{master.ip}" if master
        Master.with_nodes { |node|
          rt.host "#{Application.username}@#{node.ip}",:app if node.status =~ /running/
        }
      end
            
      def ssh_configure_string_for(node)
        cmd=<<-EOC
          #{node.update_plugin_string(node)}
          pool maintain -c ~/.config -l #{PoolParty.plugin_dir}
          hostname -v #{node.name}
          /usr/bin/s3fs #{Application.shared_bucket} -o accessKeyId=#{Application.access_key} -o secretAccessKey=#{Application.secret_access_key} -o nonempty /data
        EOC
      end
      def build_haproxy_file
      servers=<<-EOS
#{collect_nodes {|node| node.haproxy_entry}.join("\n")}
      EOS
      open(Application.haproxy_config_file).read.strip ^ {:servers => servers, :host_port => Application.host_port}
      end
      # Write a temp file with the content str
      def write_to_temp_file(str="")
        tempfile = Tempfile.new("pool-party-#{rand(1000)}-#{rand(1000)}")
        tempfile.print(str)
        tempfile.flush
        tempfile
      end
      def with_temp_file(str="", &block)
        Tempfile.open "pool-party-#{rand(10000)}" do |fp|
          fp.puts str
          fp.flush
          block.call(fp)
        end
      end
    end
    
  end
end