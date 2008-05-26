require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/ec2_mock'

# RUN THESE ONE AT A TIME
module PoolParty
  class Master
    include EC2Mock
  end
end

describe "Actual remoting" do
  before(:each) do
    Application.stub!(:minimum_instances).and_return(2)
    Application.stub!(:maximum_instances).and_return(10)
    Application.stub!(:verbose).and_return(false) # Turn off messaging
    
    @master = Master.new
  end
  describe "Starting" do
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
      @master.list_of_running_instances.size.should == Application.minimum_instances
    end
  end
end