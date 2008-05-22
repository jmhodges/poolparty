module PoolParty
  class Master < Remoting    
    def start_cloud!
      message "Starting cloud"
      launched = start!
    end
    
    def start!
      launch_minimum_instances
    end
    
    def launch_minimum_instances
      request_launch_new_instances(Application.minimum_instances - number_of_pending_and_running_instances).collect do |inst|
        RemoteInstance.new(inst)
      end
    end
    
    def start_monitor!
      run_thread_loop do
        # add_task {launch_minimum_instances} # If the base instances go down...
        # add_task {update_instance_values} # Get the updated values
        # add_task {add_instance_if_load_is_high}
        # add_task {terminate_instance_if_load_is_low}
      end
    end
    
    def nodes
      list_of_running_instances.collect do |inst|
        RemoteInstance.new(inst)
      end
    end
    
    def master;@master;end
    def slaves;@slaves;end
    
  end
end