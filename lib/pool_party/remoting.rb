module PoolParty
  extend self
  
  class Remoting
    include PoolParty
    include Ec2Wrapper
    include Scheduler
                
    # == GENERAL METHODS    
    # == LISTING
    # List all the running instances associated with this account
    def list_of_running_instances
      list_of_nonterminated_instances.select {|a| a[:status] =~ /running/}
    end
    # Get a list of the pending instances
    def list_of_pending_instances
      list_of_nonterminated_instances.select {|a| a[:status] =~ /pending/}
    end
    # list of shutting down instances
    def list_of_terminating_instances
      list_of_nonterminated_instances.select {|a| a[:status] =~ /shutting/}
    end
    # list all the nonterminated instances
    def list_of_nonterminated_instances
      list_of_instances.reject {|a| a[:status] =~ /terminated/}
    end
    # List the instances, regardless of their states
    def list_of_instances
      get_instances_description
    end
    # Get number of pending instances
    def number_of_pending_instances
      list_of_pending_instances.size
    end
    # get the number of running instances
    def number_of_running_instances
      list_of_running_instances.size
    end
    # get the number of pending and running instances
    def number_of_pending_and_running_instances
      number_of_running_instances + number_of_pending_instances
    end
    # == LAUNCHING
    # Request to launch a new instance
    def request_launch_new_instance
      if can_start_a_new_instance?
        request_launch_one_instance_at_a_time
        return true
      else
        return false
      end
    end
    # Can we start a new instance?
    def can_start_a_new_instance?
      maximum_number_of_instances_are_not_running?
    end
    # Are the maximum number of instances running?
    def maximum_number_of_instances_are_not_running?
      list_of_running_instances.size < Application.maximum_instances
    end
    # Request to launch a number of instances
    def request_launch_new_instances(num=1)
      out = []
      num.times {out << request_launch_one_instance_at_a_time}
      out
    end
    # Launch one instance at a time
    def request_launch_one_instance_at_a_time
      reset!
      while !number_of_pending_instances.zero?
        wait "5.seconds"
        reset!
      end
      return launch_new_instance!
    end
    # == SHUTDOWN
    # Terminate all running instances
    def request_termination_of_running_instances
      list_of_running_instances.each {|a| terminate_instance!(a[:instance_id])}
    end
    # Request termination of all instances regardless of their state (includes pending instances)
    def request_termination_of_all_instances
      get_instances_description.each {|a| terminate_instance!(a[:instance_id])}
    end
    # Terminate instance by id
    def request_termination_of_instance(id)
      if can_shutdown_an_instance?
        terminate_instance! id
        return true
      else
        return false
      end
    end
    # Can we shutdown an instance?
    def can_shutdown_an_instance?
      minimum_number_of_instances_are_running?
    end
    # Are the minimum number of instances running?
    def minimum_number_of_instances_are_running?
      list_of_running_instances.size > Application.minimum_instances
    end
    # Get the cached running_instances
    def running_instances
      @running_instances ||= update_instance_values
    end
    # Update the instance values
    def update_instance_values
      @running_instances = list_of_running_instances.collect {|a| RemoteInstance.new(a) }.sort
    end
  end
    
end