require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + "/../helpers/ec2_mock"
require File.dirname(__FILE__) + "/../../plugins/logging/init"

describe "Logging plugin" do
  before(:each) do
    Kernel.stub!(:system).and_return true
    Application.stub!(:environment).and_return("test") # So it doesn't daemonize
    Application.stub!(:minimum_instances).and_return(2)
    Application.stub!(:maximum_instances).and_return(10)
    Application.stub!(:polling_time).and_return(0.2)
    Application.stub!(:verbose).and_return(false) # Turn off messaging    
    
    @logging = Logging.new
    Logging.stub!(:new).and_return @logging
    @master = Master.new
  end
  
  it "should be loaded as a subclass of PoolParty::Plugin" do
    Logging.superclass.should == PoolParty::Plugin
  end
  it "should receive log_start after starting the cloud" do
    @logging.should_receive(:log_start)
    @master.start
  end
  it "should log the start into a log" do
    @master.start
    open("logs/#{Application.environment.to_s}").read.should =~ /START/
  end
  it "should receive log_new_stats after a a check_stats" do
    @logging.should_receive(:log_new_stats).once
    @master.check_stats
  end
  it "should log the check_stats stats" do
    @master.check_stats
    open("logs/#{Application.environment.to_s}").read.should =~ /STATS/
  end
  it "should have access to the master variables when calling log_new_instance" do
    @logging.should_receive(:log_new_instance)
    @master.add_instance
  end
end