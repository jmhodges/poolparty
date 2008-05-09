module PoolParty
  extend self
  
  class Remoting < Scheduler
    include PoolParty
    include Ec2Wrapper
                
    # == GENERAL METHODS    
    # == LISTING
    # List all the running instances associated with this account
    def list_of_running_instances
      get_instances_description.select {|a| a[:status] =~ /running/}
    end
    # Get a list of the pending instances
    def list_of_pending_instances
      get_instances_description.select {|a| a[:status] =~ /pending/}
    end
    # list of shutting down instances
    def list_of_terminating_instances
      get_instances_description.select {|a| a[:status] =~ /shutting/}
    end
    # Get number of pending instances
    def number_of_pending_instances
      list_of_pending_instances.size
    end
    def number_of_running_instances
      list_of_running_instances.size
    end
    # == LAUNCHING
    # Request to launch a new instance
    # Will only luanch if the last_startup_time has been cleared
    # Clear the last_startup_time if instance does launch
    def request_launch_new_instance
      if can_start_a_new_instance?
        update_startup_time
        return request_launch_one_instance_at_a_time
      else
        return nil
      end
    end
    def can_start_a_new_instance?
      eval(interval_wait_time).ago >= startup_time && maximum_number_of_instances_are_running?
    end
    def maximum_number_of_instances_are_running?
      list_of_running_instances.size < maximum_instances
    end
    def update_startup_time
      @last_startup_time = Time.now
    end
    def startup_time
      @last_startup_time ||= Time.now
    end
    # Request to launch a number of instances
    def request_launch_new_instances(num=1)
      num.times {request_launch_one_instance_at_a_time}
    end
    # Launch one instance at a time
    def request_launch_one_instance_at_a_time
      while !number_of_pending_instances.zero?
        sleep 2
      end
      return launch_new_instance!
    end
    # == SHUTDOWN
    # Terminate all running instances
    def request_termination_of_running_instances
      list_of_running_instances.each {|a| terminate_instance!(a[:instance_id])}
    end
    # Terminate instance by id
    def request_termination_of_instance(id)
      if can_shutdown_an_instance?
        update_shutdown_time
        terminate_instance! id
        return true
      else
        return false
      end
    end
    def can_shutdown_an_instance?      
      eval(interval_wait_time).ago >= shutdown_time && minimum_number_of_instances_are_running?
    end
    def minimum_number_of_instances_are_running?
      list_of_running_instances.size > minimum_instances
    end
    def update_shutdown_time 
      @last_shutdown_time = Time.now
    end
    def shutdown_time
      @last_shutdown_time ||= Time.now
    end
        
  end
    
end