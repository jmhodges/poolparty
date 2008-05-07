module PoolParty
  extend self
  
  class Remoting
    include Ec2Wrapper
    
    def initialize(i=nil)
      load_config!
    end
    
    # Connect to the s3 bucket with the values provided from the config
    def connect_to_s3!
      @connected ||= AWS::S3::Base.establish_connection!( 
        :access_key_id => access_key_id,
        :secret_access_key => secret_access_key, 
        :server => "#{server_pool_bucket}.s3.amazonaws.com")
    end

    # Load the configuration from the file, if it's a server or from the user-data if it's on the client
    def load_config!
      @config ||= begin
        load_config_from_file!
      rescue Exception => e
        load_config_from_user_data!
      end      
    end
    
    # Load the config from the file specified on the Application
    def load_config_from_file!
      @config ||= YAML.load(open(Application.config_file).read)["#{Application.environment}"]
    end
    
    # Load the configuration parameters from the user-data when launched
    def load_config_from_user_data!
      @config ||= YAML.load(URI.parse("http://169.254.169.254/latest/user-data"))
    end
    
    # == GENERAL METHODS
    # Gets the instances registered in the bucket
    def server_pool_bucket_instances
      @bucket_instances ||= server_pool_bucket.bucket_objects.select {|a| a unless bucket_flag_includes?(a.key) }
    end
    
    # Get the last_shutdown_time from the bucket
    def last_shutdown_time
      @last_shutdown_time ||= (
        get_bucket_flag("last_shutdown_time").value || update_bucket_flag("last_shutdown_time")
      )
    end
    # Get the last_startup_time from the bucket
    def last_startup_time
      @last_startup_time ||= (
        get_bucket_flag("last_startup_time").value || update_bucket_flag("last_startup_time")
      )
    end
    
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
    # == LAUNCHING
    # Request to launch a new instance
    # Will only luanch if the last_startup_time has been cleared
    # Clear the last_startup_time if instance does launch
    def request_launch_new_instance
      if can_start_a_new_instance?
        update_bucket_flag("last_startup_time")
        request_launch_one_instance_at_a_time
        return true
      else
        return false
      end
    end
    private
    def can_start_a_new_instance?
      get_bucket_flag("last_startup_time").nil? || get_bucket_flag("last_startup_time") >= eval(interval_wait_time).ago
    end
    public
    # Request to launch a number of instances
    def request_launch_new_instances(num=1)
      num.times {request_launch_one_instance_at_a_time}
    end
    # Launch one instance at a time
    def request_launch_one_instance_at_a_time
      if number_of_pending_instances.zero?
        request_launch_new_instance
        return true
      else
        sleep 2
        request_launch_one_instance_at_a_time
      end
    end
    # == SHUTDOWN
    # Terminate all running instances
    def request_termination_of_running_instances
      list_of_running_instances.each {|a| terminate_instance!(a[:instance_id])}
    end
    # Terminate instance by id
    def request_termination_of_instance(id)
      if get_bucket_flag("last_shutdown_time") >= eval(interval_wait_time).ago
        update_bucket_flag("last_shutdown_time")
        terminate_instance! id
        return true
      else
        return false
      end
    end
    
    # == MONITORING METHODS
    # Are the minimum number of instances running?
    def are_the_minimum_number_of_instances_running?
      list_of_running_instances.size >= minimum_instances
    end
    # Are the maximum number of instances running?
    def are_the_maximum_number_of_instances_running?
      list_of_running_instances.size == maximum_instances
    end
    
    # Flush the caches
    def reset!
      %w(
      @bucket_instances @instances_description @last_startup_time @last_shutdown_time
      ).each {|a| a = nil }
    end
    
    # Defines the configuration key as a method on the class if
    # the method does not exist
    def method_missing(m, *args)
      if @config.include?("#{m}")
        eval "self.class.send :attr_reader, :#{m};def #{m};@#{m} ||= '#{@config["#{m}"]}';end;#{m}"
      else
        super
      end
    end
    
  end
    
end