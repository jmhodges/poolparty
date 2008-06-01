require File.dirname(__FILE__) + '/spec_helper'

class TestPlugin < PoolParty::Plugin
  run_before :new_configure, :echo_hosts
    
  def echo_hosts
    puts "hosts"
  end
end

describe "Plugin" do
  it "should define run_before method" do
    Plugin.methods.include?("run_before").should == true
  end
  it "should define run_after method" do
    Plugin.methods.include?("run_after").should == true
  end
  describe "usage" do
    before(:each) do
      @instance = RemoteInstance.new
      @instance.stub!(:ssh).and_return "true"
      @instance.stub!(:scp).and_return "true"
      Kernel.stub!(:system).and_return "true"
    end
    it "should should call echo_hosts after calling configure" do
      TestPlugin.should_receive(:echo_hosts).and_return "echo"
      @instance.new_configure
    end
  end
end