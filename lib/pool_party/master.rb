=begin rdoc
  The basic master for PoolParty
=end
require "aska"
module PoolParty
  class Master < Remoting
    include Server
    include Aska
    
    def initialize
      super
      
      self.class.send :rules, :contract_when, Application.options.contract_when
      self.class.send :rules, :expand_when, Application.options.expand_when
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
          exit
        end
        run_thread_loop(:daemonize => Application.production?) do
          add_task {launch_minimum_instances} # If the base instances go down...
          add_task {add_instance_if_load_is_high}
          add_task {terminate_instance_if_load_is_low}
        end
      rescue Exception => e
        puts "There was an error: #{e.nice_message}"
      end
    end
    # Add an instance if the load is high
    def add_instance_if_load_is_high      
      request_launch_new_instance if expand?
    end
    # Teardown an instance if the load is pretty low
    def terminate_instance_if_load_is_low
      if contract?
        node = nodes.reject {|a| a.master? }[-1]
        request_termination_of_instance(node.instance_id) if node
      end
    end
    # FOR MONITORING
    def contract?
      valid_rules?(:contract_when)
    end
    def expand?
      valid_rules?(:expand_when)
    end
    # Get the average web requests per cloud
    def web_requests
      nodes.collect {|a| a.web } / nodes.size
    end
    # Get the average cpu usage per cloud
    def cpu_usage
      nodes.collect {|a| a.cpu } / nodes.size
    end
    # Get the average memory usage over the cloud
    def memory_usage
      nodes.collect {|a| a.memory } / nodes.size
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
    # Build the basic auth file for the heartbeat
    def build_heartbeat_authkeys_file
      write_to_temp_file(open(Application.heartbeat_authkeys_config_file).read)
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
    # Get the next node in sequence, so we can configure heartbeat to monitor the next node
    def get_next_node(node)
      i = node.number + 1
      i = 0 if i == (nodes.size - 1)
      get_node(i)
    end
    # On exit command
    def on_exit      
    end
    # List the clouds
    def list
      if number_of_pending_and_running_instances > 0
        out = "-- CLOUD (#{number_of_pending_and_running_instances})--"
        nodes.each do |node|
          out << node.description
        end
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
      def requires_heartbeat?
        new.nodes.size > 1
      end
      def get_next_node(node)
        new.get_next_node(node)
      end
      # Build a heartbeat_config_file from the config file in the config directory and return a tempfile
      def build_heartbeat_config_file_for(node)
        return nil unless node
        servers = "#{node.node_entry}\n#{get_next_node(node).node_entry}"
        write_to_temp_file(open(Application.heartbeat_config_file).read.strip ^ {:nodes => servers})
      end
      # Build a heartbeat resources file from the config directory and return a tempfile
      def build_heartbeat_resources_file_for(node)
        return nil unless node
        write_to_temp_file("#{node.haproxy_resources_entry}\n#{get_next_node(node).haproxy_resources_entry}")
      end
    end
        
  end
end