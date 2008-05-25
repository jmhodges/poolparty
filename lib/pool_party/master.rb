=begin rdoc
  The basic master for PoolParty
=end
module PoolParty
  class Master < Remoting
    include Server
    def initialize
      super
      self
    end
    # Start the cloud
    def start_cloud!
      message "Starting cloud"
      start!
    end
    # Start the cloud, which launches the minimum_instances
    def start!
      launch_minimum_instances
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
        end
        run_thread_loop(:daemonize => !development?) do
          add_task {launch_minimum_instances} # If the base instances go down...
          # add_task {add_instance_if_load_is_high}
          # add_task {terminate_instance_if_load_is_low}
        end
      rescue Exception => e
        puts "There was an error: #{e.nice_message}"
      end
    end
    # Restart the running instances services with monit on all the nodes
    def restart_running_instances_services
      nodes.each do |node|
        node.restart_with_monit
      end
    end
    # Reconfigure the running instances and restart all their services
    def reconfigure_and_restart_running_instances
      reconfigure_running_instances
      restart_running_instances_services
    end
    # Reconfigure the running instances
    def reconfigure_running_instances
      hosts = build_hosts_file
      hproxy = build_haproxy_file
      
      nodes.each do |node|
        node.configure
      end
    end
    # Build the basic haproxy config file from the config file in the config directory and return a tempfile
    def build_haproxy_file
      servers=<<-EOS        
#{nodes.collect {|node| node.haproxy_entry}.join("\n")}
      EOS
      write_to_temp_file(open(Application.haproxy_config_file).read.strip ^ {:servers => servers, :host_port => Application.host_port})
    end
    # Build the hosts file and return a tempfile
    def build_hosts_file
      write_to_temp_file(nodes.collect {|a| a.hosts_entry }.join("\n"))
    end
    # Build a heartbeat_config_file from the config file in the config directory and return a tempfile
    def build_heartbeat_config_file
      servers=<<-EOS        
#{nodes.collect {|node| node.node_entry}.join("\n")}
      EOS
      write_to_temp_file(open(Application.heartbeat_config_file).read.strip ^ {:nodes => servers})
    end
    # Build a heartbeat resources file from the config directory and return a tempfile
    def build_heartbeat_resources_file
      servers=<<-EOS        
#{nodes.collect {|node| node.heartbeat_entry}.join("\n")}
      EOS
      write_to_temp_file(open(Application.heartbeat_config_file).read.strip ^ {:nodes => servers})
    end
    # Return a list of the nodes and cache them
    def nodes
      @nodes ||= list_of_nonterminated_instances.collect_with_index do |inst, i|
        RemoteInstance.new(inst.merge({:number => i}))
      end
    end
    # Get the node at the specific index from the cached nodes
    def get_node(i=0)
      nodes.select {|a| a.number == i}.first
    end
    # On exit command
    def on_exit      
    end
    # List the clouds
    def list
      if number_of_pending_and_running_instances > 0
        puts "-- CLOUD (#{number_of_pending_and_running_instances})--"
        nodes.each do |node|
          puts node.description
        end
      else
        puts "Cloud is not running"
      end
    end
    # Reset and clear the caches
    def reset!
      @cached_descriptions = nil
      @nodes = nil
    end
        
  end
end