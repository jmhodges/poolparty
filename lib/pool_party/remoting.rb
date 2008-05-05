module PoolParty
  extend self
  
  class Remoting
    include Ec2Wrapper
    
    def initialize
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
      server_pool_bucket.bucket_objects.select {|a| a unless bucket_flag_includes?(a.key) }
    end
    
    # Get the last_shutdown_time from the bucket
    def last_shutdown_time
      get_bucket_flag("last_shutdown_time")
    end
    # Get the last_startup_time from the bucket
    def last_startup_time
      get_bucket_flag("last_startup_time")
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
    # == LAUNCHING
    # Request to launch a new instance
    def request_launch_new_instance
      
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