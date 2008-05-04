module PoolParty
  extend self
  
  class Host < Remoting
    
    def registered_in_bucket
      server_pool_bucket.bucket_objects.collect {|a| a if a.key != "last_shutdown_time" }
    end
    
    def clear_bucket!
      server_pool_bucket.bucket_objects.each {|a| server_pool_bucket.delete_bucket_value a.key }
    end
    
    def method_missing(m,*args)
      if config.include?("#{m}") 
        config["#{m}"]
      else
        super
      end
    end
    
  end
end