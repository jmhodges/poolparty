require File.dirname(__FILE__) + '/spec_helper'

describe "Host" do
  before(:each) do
    @host = Host.new
    @host.connect_to_s3!
    @host.clear_bucket!
    @host.server_pool_bucket.store_bucket_value "test", "test"
  end
  it "should be able to get a list of the registered instances in the server pool bucket" do
    @host.registered_in_bucket.should_not be_empty
  end
  it "should be able say there are two instances registered in the bucket" do
    @host.registered_in_bucket.size.should == 1
  end
end