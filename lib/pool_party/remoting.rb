module PoolParty
  extend self
  
  class Remoting
    
    def initialize
      case self.class.to_s
      when "Host"
        load_config_from_file!
      when "Instance"
        load_config_from_user_data!
      end
    end
        
    def connect_to_s3!
      @connected ||= AWS::S3::Base.establish_connection!( 
        :access_key_id => access_key_id, 
        :secret_access_key => secret_access_key, 
        :server => "#{server_pool_bucket}.s3.amazonaws.com")
    end

    def config
      @config ||= begin 
        load_config_from_file!
      rescue 
        load_config_from_user_data!
      end
    end
    
    def load_config_from_file!
      YAML.load(open(Application.config_file).read)["#{Application.environment}"]
    end
    
    def load_config_from_user_data!
      YAML.load(URI.parse("http://169.254.169.254/latest/user-data"))
    end
    
    # GENERAL METHODS
    def server_pool_bucket_instances
      server_pool_bucket.bucket_objects.collect {|a| a if a.key != "last_shutdown_time" }
    end
    
    def last_shutdown_time
      server_pool_bucket.bucket_object("last_shutdown_time")
    end
    
    def method_missing(m, *args)
      if config.include?("#{m}")
        eval "self.class.send :attr_reader, :#{m};def #{m};@#{m} ||= '#{config["#{m}"]}';end;#{m}"
      else
        super
      end
    end
    
  end
    
end