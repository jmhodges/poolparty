require File.dirname(__FILE__) + '/spec_helper'

# RUN THESE ONE AT A TIME
module PoolParty
  class Host
    def on_server_exit
      puts "Exiting #{Time.now}"; 
    end
  end
end

describe "Actual remoting" do
  before(:each) do
    @host, @options = PoolParty.server({:config_file => "#{File.dirname(__FILE__)}/../config/config.yml"})
    @starting_size = @host.list_of_running_instances.size
  end
  after(:each) do
    @host.request_termination_of_all_instances
  end
  it "should start up the minimum instances when starting" do
    wait_launch do
      @host.start!
    end
    wait "20.seconds"
    if @starting_size > 0
      @host.list_of_running_instances.size.should == Application.minimum_instances 
    else
      @host.list_of_pending_instances.size.should == Application.minimum_instances
    end
  end
  it "should update_instance_values after the polling_time has passed with new RemoteInstances" do
    wait_launch("50.seconds") do
      @host.start!
    end
    @host.running_instances.class.should == Array
    @host.running_instances[0].class.should == RemoteInstance
  end
  it "should try to add a new instance when he load is getting heavy" do    
    @host.stub!(:global_load).and_return 0.86
    @host.stub!(:terminate_instance_if_load_is_low).at_least(1).and_return false

    Application.stub!(:polling_time).and_return 20
    Application.stub!(:heavy_load).and_return 0.50
    Application.stub!(:maximum_instances).and_return(2)
    Application.stub!(:interval_wait_time).and_return("20.seconds")
    
    @host.launch_minimum_instances
    
    wait "40.seconds"
    
    wait_launch("2.minutes") do
      @host.start!
    end
    
    wait "20.seconds"
    # If the instance already started, we just want to calculate the actual result, so it's either or
    @host.list_of_running_instances.size.should == 2
  end
  
  it "should not add a new instance if the load is not heavy" do    
    @host.stub!(:global_load).and_return 0.30
    Application.stub!(:polling_time).and_return "30.seconds"
    Application.stub!(:heavy_load).and_return 0.80
    Application.stub!(:interval_wait_time).and_return("20.seconds")
    
    @host.launch_minimum_instances
    wait "10.seconds"
    wait_launch("60.seconds") do
      @host.start!
    end
    
    # If the instance already started, we just want to calculate the actual result, so it's either or
    @host.list_of_running_instances.size.should == 1
  end
  it "should try to terminate an instance if the load is low" do
    @host.stub!(:global_load).and_return 0.15
    @host.should_receive(:add_instance_if_load_is_high).and_return false
    
    Application.stub!(:polling_time).and_return "10.seconds"
    Application.stub!(:light_load).and_return 0.20
    Application.stub!(:interval_wait_time).and_return("30.seconds")
    
    @host.launch_minimum_instances
    @host.launch_new_instance! # Force launch one
    
    wait "30.seconds"
    wait_launch("120.seconds") do
      @host.start!
    end
    
    # If the instance already started, we just want to calculate the actual result, so it's either or
    @host.list_of_running_instances.size.should == 1
  end
end