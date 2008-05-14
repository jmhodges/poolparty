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
    wait_launch(@starting_size) do
      @host.start!
    end
    if @starting_size > 0
      @host.list_of_running_instances.size.should == Application.minimum_instances
    else
      @host.list_of_pending_instances.size.should == Application.minimum_instances
    end
  end
  it "should update_instance_values after the polling_time has passed with new RemoteInstances" do
    wait_launch(@starting_size, "50.seconds") do
      @host.start!
    end
    @host.running_instances.class.should == Array
    @host.running_instances[0].class.should == RemoteInstance
  end
  it "should try to add a new instance when he load is getting heavy" do
    @host.launch_minimum_instances
    Application.stub!(:polling_time).and_return 20
    sleep 10
    @host.should_receive(:global_load).and_return 0.86
    @host.should_receive(:request_launch_new_instance).once.and_return true
    wait_launch(1, "1.minute") do
      @host.start!
    end
    sleep 10
    
    # If the instance already started, we just want to calculate the actual result, so it's either or
    @host.list_of_running_instances.size.should == 2
  end
end