require File.dirname(__FILE__) + '/spec_helper'

describe "remote instance" do
  before(:each) do
    @instance = RemoteInstance.new({:ip => "127.0.0.1"})
    @instance.stub!(:ssh).and_return "true"
    @instance.stub!(:scp).and_return "true"
    @master = Master.new
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
    it "should call configure after it calls install_stack" do
      @instance.should_receive(:configure).once.and_return(true)
      @instance.install_stack
    end
    it "should call restart_with_monit after it calls configure" do
      @instance.should_receive(:restart_with_monit).once.and_return(true)
      @instance.configure
    end
  end
  describe "in failover" do
    it "should be able to become master " do
      @instance.stub!(:configure).and_return true
      @instance.number = 1
      @instance.become_master
      @instance.number.should == 0
    end
    it "should reconfigure after becoming master" do
      @instance.should_receive(:configure).and_return true
      @instance.become_master
    end
    it "should say that it is the master after becoming master" do
      @instance.stub!(:configure).and_return true
      @instance.become_master
      @instance.master?.should == true
    end
  end
end