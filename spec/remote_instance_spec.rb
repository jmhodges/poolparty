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
  end
end