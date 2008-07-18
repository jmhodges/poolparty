require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + "/helpers/ec2_mock"

describe "Master remoting: " do
  before(:each) do
    stub_option_load
    
    Kernel.stub!(:system).and_return true
    Application.stub!(:environment).and_return("test") # So it doesn't daemonize
    Application.stub!(:minimum_instances).and_return(2)
    Application.stub!(:maximum_instances).and_return(10)
    Application.stub!(:polling_time).and_return(0.1)
    Application.stub!(:verbose).and_return(false) # Turn off messaging
    
    @master = Master.new
    @master.launch_new_instance!
  end
  describe "listing" do
    before(:each) do
      Application.stub!(:keypair).and_return("alist")
      @a1={:instance_id => "i-a1", :ip => "127.0.0.1", :status => "running", :launching_time => 10.minutes.ago, :keypair => "alist"}
      @a2={:instance_id => "i-a2", :ip => "127.0.0.3", :status => "running", :launching_time => 2.hours.ago, :keypair => "alist"}
      @a3={:instance_id => "i-a3", :ip => "127.0.0.3", :status => "terminated", :launching_time => 2.hours.ago, :keypair => "alist"}
      @a4={:instance_id => "i-a4", :ip => "127.0.0.4", :status => "pending", :launching_time => 2.hours.ago, :keypair => "alist"}
      
      @b1={:instance_id => "i-b1", :ip => "127.0.0.2", :status => "terminated", :launching_time => 55.minutes.ago, :keypair => "blist"}
      @c1={:instance_id => "i-c1", :ip => "127.0.0.4", :status => "pending", :launching_time => 2.days.ago, :keypair => "clist"}
      @master.stub!(:get_instances_description).and_return [@a1, @a2, @a3, @a4, @b1, @c1]
    end
    it "should pull out the list those instances with the keypair requested" do      
      @master.list_of_instances.collect {|a| a[:instance_id]}.should == ["i-a1", "i-a2", "i-a3", "i-a4"]
    end
    it "should pull out the list with the blist keypair" do
      Application.stub!(:keypair).and_return("blist")
      @master.list_of_instances.collect {|a| a[:instance_id]}.should == ["i-b1"]
    end
    it "should be able to pull out the list_of_nonterminated_instances" do
      @master.list_of_nonterminated_instances.should == [@a1, @a2, @a4]
    end
    it "should be able to pull the list of list_of_pending_instances" do
      @master.list_of_pending_instances.should == [@a4]
    end
    it "should be able to pull the list of list_of_running_instances" do
      @master.list_of_running_instances.should == [@a1, @a2]
    end
    it "should be able to get the number_of_pending_instances" do
      @master.number_of_pending_instances.should == 1
    end
    it "should be able to grab the number_of_running_instances" do
      @master.number_of_running_instances.should == 2
    end
    it "should be able to grab the entire list of instances" do
      @master.list_of_all_instances.should == [@a1, @a2, @a3, @a4, @b1, @c1]
    end
    it "should be able to grab the entire list sorted by keypair" do
      @master.cloud_keypairs.should == ["alist", "blist", "clist"]
    end
  end
  describe "starting" do
    before(:each) do
      @master.start_cloud!
      
      @a1={:instance_id => "i-a1", :ip => "127.0.0.1", :status => "running", :launching_time => 10.minutes.ago, :keypair => "alist"}
      @a2={:instance_id => "i-a2", :ip => "127.0.0.3", :status => "running", :launching_time => 2.hours.ago, :keypair => "alist"}
      @a3={:instance_id => "i-a3", :ip => "127.0.0.3", :status => "terminated", :launching_time => 2.hours.ago, :keypair => "alist"}
      @a4={:instance_id => "i-a4", :ip => "127.0.0.4", :status => "pending", :launching_time => 2.hours.ago, :keypair => "alist"}
      
      @b1={:instance_id => "i-b1", :ip => "127.0.0.2", :status => "terminated", :launching_time => 55.minutes.ago, :keypair => "blist"}
      @c1={:instance_id => "i-c1", :ip => "127.0.0.4", :status => "pending", :launching_time => 2.days.ago, :keypair => "clist"}
      @master.stub!(:get_instances_description).and_return [@a1, @a2, @a3, @a4, @b1, @c1]
      
      Application.stub!(:keypair).and_return "alist"
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
    before(:each) do
      Application.stub!(:keypair).and_return "alist"
    end
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
      wait 0.5 # Give the two instances time to boot up
      (Application.minimum_instances - @master.number_of_pending_and_running_instances).should == 0
      @master.scale_cloud!
      @master.nodes.size.should == Application.minimum_instances + 1
    end
    it "should terminate an instance when the load shows that it's too light" do
      @master.stub!(:contract?).and_return true
      @master.start_cloud!
      @master.request_launch_new_instance
      wait 0.5 # Give the two instances time to boot up
      @master.number_of_pending_and_running_instances.should == Application.minimum_instances + 1
      @master.scale_cloud!
      @master.number_of_pending_and_running_instances.should == Application.minimum_instances
    end
  end
  describe "configuring" do
    before(:each) do
      @instance = RemoteInstance.new
      @instance.stub!(:ip).and_return "127.0.0.1"
      @instance.stub!(:name).and_return "node0"
      Master.stub!(:new).and_return @master
      @master.stub!(:nodes).and_return [@instance]
    end
    it "should call configure on all of the nodes when calling reconfigure_running_instances" do
      @master.nodes.each {|a| 
        a.stub!(:status).and_return("running")
        a.should_receive(:configure).and_return true 
      }
      @master.configure_cloud
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