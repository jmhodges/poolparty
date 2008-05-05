require File.dirname(__FILE__) + '/spec_helper'

describe "Remoting" do
  before(:each) do
    @remoting = Remoting.new
  end
  
  it "should be able to get the last_startup_time" do
    @remoting.last_startup_time.should_not be_nil
  end
  it "should be able to get the last_shutdown_time" do
    @remoting.last_shutdown_time.should_not be_nil
  end  
  it "should be able to list all the instances as instance ids" do
    @remoting.list_of_running_instances.class.should == Array
  end
  it "should be able to start an instance" do
    size = @remoting.list_of_pending_instances.size
    @remoting.launch_new_instance!
    @remoting.list_of_pending_instances.size.should == size + 1
  end
  
  describe "Host" do
    it "should be able to connect to s3 when required" do
      @remoting.connect_to_s3!.should_not be_nil
    end
    it "should be able to fetch the config from the specified file" do
      @remoting.access_key_id.should_not be_nil
    end
  end
  describe "Client remoting" do
    it "should be able to connect to s3 when required, from the user-data"
  end
end