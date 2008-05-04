=begin rdoc
  Host
  This is the basis of the server for Pool Party
=end
module PoolParty
  extend self
  
  class Host < Remoting
    attr_reader :bucket_instances
    
    # The remote instance with the lightest load
    def instance_with_lightest_load
      registered_in_bucket.sort {|a,b| a.load <=> b.load }[0]
    end
    
    # A collection of RemoteInstances for every registered instance in the bucket
    def registered_in_bucket
      server_pool_bucket_instances.collect do |instance|
        instances << RemoteInstance.new(instance) unless instance_ids.include?(instance.key)
      end
      instances
    end
    
    # :nodoc:
    def instance_ids
      instances.collect {|a| a }
    end
    # :nodoc:
    def instances
      @bucket_instances ||= []
    end
    
    # Resets this class's variables to reload
    def reset!
      @bucket_instances = nil
    end
    
    # Remove all the registered instances from the bucket
    def clear_bucket!
      server_pool_bucket.bucket_objects.each {|a| server_pool_bucket.delete_bucket_value a.key }
    end
    
    # Gives us the usage of method calling for the configuration
    def method_missing(m,*args)
      if config.include?("#{m}") 
        config["#{m}"]
      else
        super
      end
    end
    
  end
end