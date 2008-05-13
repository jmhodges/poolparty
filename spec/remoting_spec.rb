require File.dirname(__FILE__) + '/spec_helper'

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
    wait_launch(@starting_size, eval(Application.polling_time)+30) do
      @host.start!
    end
    @host.running_instances.class.should == Array
    @host.running_instances[0].class.should == RemoteInstance
  end
end