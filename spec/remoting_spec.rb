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
    @remoting.reset!
    @remoting.list_of_pending_instances.size.should == size + 1
  end
  it "should be able to shutdown an instance" do       
    instance = @remoting.request_launch_new_instance
    instance[:status].should =~ /pending/
    sleep 1
    
    BucketFlag.new("last_shutdown_time").value = nil
    @remoting.request_termination_of_instance instance[:instance_id]
    sleep 2
    instance = @remoting.describe_instance instance[:instance_id]
    instance[:status].should =~ /shutting/
    @remoting.list_of_pending_instances.include?(instance).should == false
  end
  it "should only launch one instance at a time when requested to do so" do
    @remoting.request_termination_of_running_instances
    sleep 1
    size = @remoting.list_of_pending_instances.size
    @remoting.request_launch_one_instance_at_a_time
    @remoting.number_of_pending_instances.should == 1
    @remoting.request_termination_of_running_instances
  end  
end