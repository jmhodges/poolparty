require File.dirname(__FILE__) + '/spec_helper'

describe "Master remoting: " do
  before(:each) do
    Application.stub!(:environment).and_return("test") # So it doesn't daemonize
    Application.stub!(:minimum_instances).and_return(2)
    Application.stub!(:maximum_instances).and_return(10)
    Application.stub!(:polling_time).and_return(0.1)
    Application.stub!(:verbose).and_return(false) # Turn off messaging
    
    @master = Master.new
    @master.launch_new_instance!
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
      wait 0.5 # Give the last one time to get to running
      @master.list_of_running_instances.size.should == Application.minimum_instances
    end
  end
  describe "maintaining" do
    it "should maintain the minimum_instances if one goes down" do
      @master.start_cloud!
      wait 0.2 # Give the two instances time to boot up
      (Application.minimum_instances - @master.number_of_pending_and_running_instances).should == 0
      
      # Kill one off to test how it handles the response
      @master.terminate_instance!(@master.list_of_running_instances[0][:instance_id])
      (Application.minimum_instances - @master.number_of_pending_and_running_instances).should == 1
      @master.launch_minimum_instances # Assume this runs in the bg process

      (Application.minimum_instances - @master.number_of_pending_and_running_instances).should == 0
      @master.number_of_pending_and_running_instances.should == Application.minimum_instances
    end
    it "should launch a new instance when the load gets too heavy set in the configs" do
      @master.stub!(:expand?).and_return true
      @master.start_cloud!
      wait 0.2 # Give the two instances time to boot up
      (Application.minimum_instances - @master.number_of_pending_and_running_instances).should == 0
      @master.scale_cloud!
      @master.nodes.size.should == Application.minimum_instances + 1
    end
    it "should terminate an instance when the load shows that it's too light" do
      @master.stub!(:contract?).and_return true
      @master.start_cloud!
      @master.request_launch_new_instance
      wait 0.5 # Give the two instances time to boot up
      @master.scale_cloud!
      @master.number_of_pending_and_running_instances.should == Application.minimum_instances
    end
  end
  describe "configuring" do
    it "should call configure on all of the nodes when calling reconfigure_running_instances" do
      @master.nodes.each {|a| 
        a.stub!(:status).and_return("running")
        a.should_receive(:configure).and_return true 
      }
      @master.reconfigure_running_instances
    end    
    it "should call restart_with_monit on all of the nodes when calling restart_running_instances_services" do
      @master.nodes.each {|a| a.should_receive(:restart_with_monit).and_return true }
      @master.restart_running_instances_services
    end
    it "should be able to say there are no number_of_unconfigured_nodes left when all the nodes are configured" do
      @master.nodes.each {|a| a.should_receive(:stack_installed?).and_return true }
      @master.number_of_unconfigured_nodes.should == 0
    end
    it "should be able to say that there is an unconfigured node" do
      @master.nodes[-1].should_receive(:stack_installed?).and_return false
      @master.number_of_unconfigured_nodes.should_not == 0
    end
  end
end