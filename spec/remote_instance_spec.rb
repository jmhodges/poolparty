require File.dirname(__FILE__) + '/spec_helper'

describe "remote instance" do
  before(:each) do
    @instance = RemoteInstance.new({:ip => "127.0.0.1"})
    @instance.stub!(:ssh).and_return true
    
  end
  
  describe "in general" do
    it "should set the ip upon creation" do
      @instance.ip.should == "127.0.0.1"
    end
    it "should be able to tell if it is the master or not" do
      @instance.master?.should == true
    end
    it "should be able to build a list of the heartbeat nodes" do
      @instance.node_entry.should =~ /node/
    end
    it "should be able to collect the list of the status_loads" do
      @instance.stub!(:web_status_level).and_return(32.2)
      @instance.stub!(:cpu_status_level).and_return(0.32)
      @instance.stub!(:memory_status_level).and_return(0.4)
      
      ("%0.2f" % @instance.status_load).should == "10.97"
    end
  end
end