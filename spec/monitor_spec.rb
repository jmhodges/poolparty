require File.dirname(__FILE__) + '/helper'

# PoolParty.server("config/config.yml")

context "convenience methods" do
  setup do
    @host = Host.new :dont_start_server => true, :dont_monitor => true
  end
  specify "should be able to show that there is one instance in the bucket" do
    Planner.server_pool_bucket.store_bucket_value("i-9e9e9w9", "test")
    Host.number_of_running_instances.should == 1
  end
  specify "should be able to show that there is still only one instance when the last_shutdown_time is in the bucket" do
    Planner.server_pool_bucket.store_bucket_value("last_shutdown_time", Time.now.to_s)
    Host.number_of_running_instances.should == 1
  end
  specify "should be able to load the number of instances in the bucket, without the last_shutdown_time" do
    Planner.server_pool_bucket.bucket_objects.each {|a| Planner.server_pool_bucket.delete_bucket_value a.key}
    Host.number_of_running_instances.zero?.should == true
  end
end