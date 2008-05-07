require File.dirname(__FILE__) + '/spec_helper'

describe "Host" do
  before(:each) do
    @host = Host.new
    @host.connect_to_s3!
    @host.clear_bucket!
    inst = @host.server_pool_bucket.store_bucket_value "test", "127.0.0.1\n0.4\n#{Time.now}"
  end
  it "should be able to get a list of the registered instances in the server pool bucket" do
    @host.registered_in_bucket.should_not be_empty
  end
  it "should be able say there are two instances registered in the bucket" do
    @host.registered_in_bucket.size.should == 1
  end
  it "should not push a remote instance in the registered_in_bucket twice" do
    @host.server_pool_bucket.store_bucket_value "test", "127.0.0.1\n0.4\n#{Time.now}"
    @host.server_pool_bucket.store_bucket_value "test", "127.0.0.1\n0.4\n#{Time.now}"
    @host.server_pool_bucket.store_bucket_value "test", "127.0.0.1\n0.4\n#{Time.now}"
    @host.registered_in_bucket.size.should == 1
  end
  it "should be able to get the instance with the lightest load" do
    @host.server_pool_bucket.store_bucket_value "test", "127.0.0.1\n0.4\n#{Time.now}"
    @host.server_pool_bucket.store_bucket_value "test2", "127.0.0.1\n0.8\n#{Time.now}"
    @host.server_pool_bucket.store_bucket_value "test3", "127.0.0.1\n0.2\n#{Time.now}"
    @host.instance_with_lightest_load.key.should == "test3"
  end
  it "should launch the minimum number of instances and no more when requested" do
    # 1 = minimum_instances
    @host.request_termination_of_running_instances
    @host.are_the_minimum_number_of_instances_running?.should == false
    @host.launch_minimum_instances
    @host.are_the_minimum_number_of_instances_running?.should == true
  end
end