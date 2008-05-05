=begin rdoc
  Special flags that sit in the bucket
=end
module PoolParty
  extend self
      
  class BucketFlag
    attr_reader :name, :value
    
    def initialize(name, value)
      @name = name
      @value = value
    end
  end
  
  @@bucket_flags = [
    BucketFlag.new("last_startup_time", nil),
    BucketFlag.new("last_shutdown_time", nil)
  ]
  
  def get_bucket_flag(name)
    @@bucket_flags.select {|a| a.name == name }.first
  end
  
  def bucket_flag_includes?(t)
    @@bucket_flags.select {|a| a.name != t }.empty?
  end
  
end