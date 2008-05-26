require File.dirname(__FILE__) + '/spec_helper'

# RUN THESE ONE AT A TIME
module PoolParty
  class Master;include EC2Mock;end
  class RemoteInstance; include RemoteInstanceMock;end
end

describe "Master remoting: " do
  before(:each) do
    Application.stub!(:environment).and_return("development") # So it daemonizes
    Application.stub!(:minimum_instances).and_return(2)
    Application.stub!(:maximum_instances).and_return(10)
    Application.stub!(:polling_time).and_return(0.5)
    Application.stub!(:verbose).and_return(false) # Turn off messaging
    
    @master = Master.new
  end
  describe "starting" do
    before(:each) do
      @master.start_cloud!
    end
    it "should start the cloud with instances" do    
      @master.list_of_instances.should_not be_empty
    end
    it "should start the cloud with running instances" do
      @master.list_of_running_instances.should_not be_empty
    end
    it "should start with the minimum_instances running" do
      wait 1 # Give the last one time to get to running
      @master.list_of_running_instances.size.should == Application.minimum_instances
    end    
  end
  describe "maintaining" do
    before(:each) do
      Thread.new {@master.start_monitor!}
    end
    after(:all) do
      `killall -9 ruby`
    end
    it "should maintain the minimum_instances if one goes down" do
      @master.start!
      wait 1.1
      p Application.minimum_instances - @master.number_of_pending_and_running_instances
      @master.terminate_instance!(@master.list_of_running_instances[0][:instance_id])      
      wait 2
      p Application.minimum_instances - @master.number_of_pending_and_running_instances
      @master.number_of_pending_and_running_instances.should == Application.minimum_instances
    end
  end
end