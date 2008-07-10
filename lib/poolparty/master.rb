=begin rdoc
  The basic master for PoolParty
=end
module PoolParty
  class Master < Remoting
    include Aska
    include Callbacks
    # ############################
    include Remoter
    # ############################
    include FileWriter
    
    def initialize
      super            
      
      self.class.send :rules, :contract_when, Application.options.contract_when unless are_rules?(:contract_when)
      self.class.send :rules, :expand_when, Application.options.expand_when unless are_rules?(:expand_when)
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
      
      wait_for_all_instances_to_boot
      
      setup_cloud
    end
    def setup_cloud
      install_cloud
      configure_cloud
    end
    alias_method :start, :start!
    def wait_for_all_instances_to_boot
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
    end
    def wait_for_all_instances_to_terminate
      reset!
      while !list_of_terminating_instances.size.zero?
        wait "2.seconds" unless Application.test?
        waited = true
        reset!
      end
      unless Application.test? || waited.nil?
        message "Give some time for the instance ssh to start up"
        wait "15.seconds"
      end
      reset!
    end
    # Configure the master because the master will take care of the rest after that
    def configure_cloud
      message "Configuring master"
      build_and_send_config_files_in_temp_directory
      remote_configure_instances
      
      nodes.each do |node|
        node.configure
      end      
    end
    before :install_cloud, :add_ssh_key
    after :configure_cloud, :remove_ssh_key
    def add_ssh_key(i)
      Kernel.system("ssh-add #{Application.keypair_path}")
    end
    def remove_ssh_key(i)
      Kernel.system("ssh-add -d #{Application.keypair_name}")
    end
    def install_cloud(bool=false)
      if Application.install_on_load? || bool
        # Just in case, add the new ubuntu apt-sources as well as updating and fixing the 
        # update packages.
        update_apt_string =<<-EOE        
          touch /etc/apt/sources.list
          echo 'deb http://mirrors.cs.wmich.edu/ubuntu hardy main universe' >> /etc/apt/sources.list
          sudo apt-get update --fix-missing
        EOE
        
        ssh(update_apt_string)
        
        Provider.install_poolparty
        Provider.install_userpackages
        
        # For plugins
        nodes.each do |node|
          node.install
        end
        
      end
    end
    def cloud_ips
      @ips ||= nodes.collect {|a| a.ip }
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
          add_task {PoolParty.message "Checking cloud"}
          add_task {launch_minimum_instances}
          add_task {reconfigure_cloud_when_necessary}
          add_task {scale_cloud!}
          add_task {check_stats}
        end
      rescue Exception => e
        Process.kill("HUP", Process.pid)
      end
    end
    alias_method :start_monitor, :start_monitor!
    def user_tasks
    end
    # Sole purpose to check the stats, mainly in a plugin
    def check_stats
      str = registered_monitors.collect {|m| "#{m}"}
      PoolParty.message "Monitors: #{str.join(", ")}"
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
      PoolParty.message "#{number_of_unconfigured_nodes} unconfigured nodes"
      configure_cloud if number_of_unconfigured_nodes > 0
    end
    def number_of_unconfigured_nodes
      # TODO: Find a better way to tell if the nodes are configured.
      nodes.reject {|a| a.stack_installed? }.size
    end
    def grow_by(num=1)
      request_launch_new_instances(num)
      
      wait_for_all_instances_to_boot
      
      reset!
      configure_cloud
    end
    def shrink_by(num=1)
      num.times do |i|
        # Get the last node that is not the master
        node = nodes.reject {|a| a.master? }[-1]
        res = request_termination_of_instance(node.instance_id) if node
        PoolParty.message "#{res ? "Could" : "Could not"} shutdown instance"
      end
      wait_for_all_instances_to_terminate
      configure_cloud
    end
    def make_base_tmp_dir(c)
      `mkdir #{base_tmp_dir}` unless File.directory?(base_tmp_dir)
    end
    before :build_and_send_config_files_in_temp_directory, :make_base_tmp_dir
    def build_and_send_config_files_in_temp_directory
      require 'ftools'
      if File.directory?(Application.plugin_dir)
        Kernel.system("tar -czf #{base_tmp_dir}/plugins.tar.gz #{File.basename(Application.plugin_dir)}")
      end
      
      File.copy(get_config_file_for("cloud_master_takeover"), "#{base_tmp_dir}/cloud_master_takeover")
      File.copy(get_config_file_for("heartbeat.conf"), "#{base_tmp_dir}/ha.cf")
      
      File.copy(Application.config_file, "#{base_tmp_dir}/config.yml") if Application.config_file && File.exists?(Application.config_file)
      File.copy(Application.keypair_path, "#{base_tmp_dir}/keypair") if File.exists?(Application.keypair_path)
      
      File.copy(get_config_file_for("monit.conf"), "#{base_tmp_dir}/monitrc")
      
      copy_config_files_in_directory_to_tmp_dir("config/resource.d")
      copy_config_files_in_directory_to_tmp_dir("config/monit.d")
      
      build_and_copy_heartbeat_authkeys_file
      build_haproxy_file
      Master.build_user_global_files
        
      Master.with_nodes do |node|
        build_hosts_file_for(node)
        build_reconfigure_instances_script_for(node)
        Master.build_user_node_files_for(node)
        
        if Master.requires_heartbeat?
          build_heartbeat_config_file_for(node)
          build_heartbeat_resources_file_for(node)
        end
      end
    end
    def cleanup_tmp_directory(c)
      Dir["#{base_tmp_dir}/*"].each {|f| FileUtils.rm_rf f} if File.directory?("tmp/")
    end
    before :build_and_send_config_files_in_temp_directory, :cleanup_tmp_directory
    # Send the files to the nodes
    def send_config_files_to_nodes(c)
      run_array_of_tasks(rsync_tasks("#{base_tmp_dir}/*", "#{remote_base_tmp_dir}"))
    end
    after :build_and_send_config_files_in_temp_directory, :send_config_files_to_nodes
    def remote_configure_instances
      arr = []
      Master.with_nodes do |node|
        script_file = "#{remote_base_tmp_dir}/#{node.name}-configuration"
        str=<<-EOC
chmod +x #{script_file}
/bin/sh #{script_file}
        EOC
        arr << "#{self.class.ssh_string} #{node.ip} '#{str.strip.runnable}'"
      end
      run_array_of_tasks(arr)
    end
    # Add an instance if the load is high
    def add_instance_if_load_is_high
      if expand?
        PoolParty.message "Cloud needs expansion"
        grow_by(1)
      end
    end
    alias_method :add_instance, :add_instance_if_load_is_high
    # Teardown an instance if the load is pretty low
    def terminate_instance_if_load_is_low      
      if contract?
        PoolParty.message "Cloud to shrink"
        shrink_by(1)
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
    # Build the basic haproxy config file from the config file in the config directory and return a tempfile
    def build_haproxy_file
      write_to_file_for("haproxy") do
        servers=<<-EOS
#{nodes.collect {|node| node.haproxy_entry}.join("\n")}
        EOS
        open(Application.haproxy_config_file).read.strip ^ {:servers => servers, :host_port => Application.host_port}
      end
    end
    # Build host file for a specific node
    def build_hosts_file_for(n)
      write_to_file_for("hosts", n) do
        "#{nodes.collect {|node| node.ip == n.ip ? node.local_hosts_entry : node.hosts_entry}.join("\n")}"
      end
    end
    # Build the basic auth file for the heartbeat
    def build_and_copy_heartbeat_authkeys_file
      write_to_file_for("authkeys") do
        open(Application.heartbeat_authkeys_config_file).read
      end
    end
    # Build heartbeat config file
    def build_heartbeat_config_file_for(node)
      write_to_file_for("heartbeat", node) do
        servers = "#{node.node_entry}\n#{get_next_node(node).node_entry}" rescue ""
        open(Application.heartbeat_config_file).read.strip ^ {:nodes => servers}
      end
    end
    def build_heartbeat_resources_file_for(node)
      write_to_file_for("haresources", node) do
        "#{node.haproxy_resources_entry}\n#{get_next_node(node).haproxy_resources_entry}" rescue ""
      end        
    end
    # Build basic configuration script for the node
    def build_reconfigure_instances_script_for(node)
      write_to_file_for("configuration", node) do
        open(Application.sh_reconfigure_instances_script).read.strip ^ node.configure_tasks
      end        
    end
    
    # Try the user's directory before the master directory
    def get_config_file_for(name)
      if File.exists?("#{user_dir}/config/#{name}")
        "#{user_dir}/config/#{name}"
      else
        "#{root_dir}/config/#{name}"
      end
    end
    # Copy all the files in the directory to the dest
    def copy_config_files_in_directory_to_tmp_dir(dir)
      dest_dir = "#{base_tmp_dir}/#{File.basename(dir)}"
      FileUtils.mkdir_p dest_dir
      
      if File.directory?("#{user_dir}/#{dir}")        
        Dir["#{user_dir}/#{dir}/*"].each do |file|
          File.copy(file, dest_dir)
        end
      else
        Dir["#{root_dir}/#{dir}/*"].each do |file|
          File.copy(file, dest_dir)
        end
      end      
    end
    # Return a list of the nodes and cache them
    def nodes
      @nodes ||= list_of_nonterminated_instances.collect_with_index do |inst, i|
        RemoteInstance.new(inst.merge({:number => i}))
      end
    end
    # Return a list of the nodes for each keypair and cache them
    def cloud_nodes
      @cloud_nodes ||= begin
        nodes_list = []
        cloud_keypairs.each {|keypair| 
          list_of_nonterminated_instances(list_of_instances(keypair)).collect_with_index { |inst, i|
            nodes_list << RemoteInstance.new(inst.merge({:number => i}))
          }
        }
        nodes_list
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
    def clouds_list
      if number_of_all_pending_and_running_instances > 0
        out = "-- ALL CLOUDS (#{number_of_all_pending_and_running_instances})--\n"
        keypair = nil
        out << cloud_nodes.collect {|node|
          str = ""
          if keypair != node.keypair
            keypair = node.keypair;
            str = "key pair: #{keypair} (#{number_of_pending_and_running_instances(keypair)})\n"
          end
          str += "\t"+node.description if !node.description.nil?
        }.join("\n")
      else
        out = "Clouds are not running"
      end
      out
    end
    # Reset and clear the caches
    def reset!
      @cached_descriptions = nil
      @nodes = nil
      @cloud_nodes = nil
    end
    
    class << self
      include PoolParty
      include FileWriter
            
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
      def cloud_ips
        new.cloud_ips
      end
      def get_next_node(node)
        new.get_next_node(node)
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
      
      # Placeholders
      def build_user_global_files
        global_user_files.each do |arr|
          write_to_file_for(arr[0]) &arr[1]
        end
      end
      def build_user_node_files_for(node)
        user_node_files.each do |arr|
          write_to_file_for(arr[0], node) do
            arr[1].call(node)
          end
        end
      end
      def define_global_user_file(name, &block)
        global_user_files << [name, block]
      end
      def global_user_files;@global_user_files ||= [];end
      def define_node_user_file(name, &block)
        user_node_files << [name, block]
      end
      def user_node_files;@user_node_files ||= [];end
    end
    
  end
end