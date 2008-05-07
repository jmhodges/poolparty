=begin rdoc
  Special flags that sit in the bucket
=end
module PoolParty
  extend self
      
  class BucketFlag < Remoting
    attr_reader :name
    
    def initialize(name)
      @name = name
      super
    end
    def value
      @config["server_pool_bucket"].bucket_object(name)
    end
  end
  
  @@bucket_flags = [
    BucketFlag.new("last_startup_time"),
    BucketFlag.new("last_shutdown_time")
  ]
  
  def get_bucket_flag(name)
    flag = @@bucket_flags.select {|a| a.name == name }.first
    flag ? flag.value : nil
  end
  
  def update_bucket_flag(name)
    val = Time.now.to_s
    server_pool_bucket.store_bucket_value("last_shutdown_time", val)
    val
  end
  
  def clear_bucket_flag(name)
    get_bucket_flag(name).value = nil
  end
  
  def bucket_flag_includes?(t)
    @@bucket_flags.select {|a| a.name != t }.empty?
  end
  
end