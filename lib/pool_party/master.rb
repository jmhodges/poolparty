module PoolParty
  class Master < Remoting
    include Server
    attr_reader :servers
    def initialize
      super
      self
    end
    def start_cloud!
      message "Starting cloud"
      @servers = start!
    end
    
    def start!
      launch_minimum_instances
    end
    
    def launch_minimum_instances
      request_launch_new_instances(Application.minimum_instances - number_of_pending_and_running_instances)
      nodes
    end
    
    def start_monitor!
      begin
        trap("INT") do
          on_exit
        end
        run_thread_loop(:daemonize => true) do
          add_task {launch_minimum_instances} # If the base instances go down...
          # add_task {add_instance_if_load_is_high}
          # add_task {terminate_instance_if_load_is_low}
        end
      rescue Exception => e
        puts "There was an error: #{e.nice_message}"
      end
    end
    
    def restart_running_instances_services
      nodes.each do |node|
        node.restart_with_monit
      end
    end
    def reconfigure_and_restart_running_instances
      reconfigure_running_instances
      reconfigure_and_restart_running_instances
    end
    def reconfigure_running_instances
      hosts = build_hosts_file
      hproxy = build_haproxy_file
      
      nodes.each do |node|
        node.configure_hosts
        node.configure_haproxy
      end
    end
    def build_haproxy_file
      self.class.build_haproxy_file
    end
    def build_hosts_file
      self.class.build_hosts_file
    end
    
    def nodes
      @nodes ||= list_of_nonterminated_instances.collect_with_index do |inst, i|
        RemoteInstance.new(inst.merge({:number => i}))
      end
    end
    
    def get_node(i=0)
      nodes.select {|a| a.number == i}.first
    end
    
    def on_exit      
    end
    
    def reset!
      @cached_descriptions = nil
      @nodes = nil
    end
    
    def self.build_hosts_file
      write_to_temp_file(nodes.collect {|a| a.hosts_entry }.join("\n"))
    end
    
    def self.build_haproxy_file
      servers=<<-EOS        
#{nodes.collect {|node| node.haproxy_entry}.join("\n")}
      EOS
      write_to_temp_file(open(Application.haproxy_config_file).read.strip ^ {:servers => servers, :host_port => Application.host_port})
    end
    
  end
end