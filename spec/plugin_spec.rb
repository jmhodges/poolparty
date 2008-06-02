require File.dirname(__FILE__) + '/spec_helper'

class TestPlugin < PoolParty::Plugin
  after_install :echo_hosts, :email_updates
  before_configure :echo_hosts
  
  def self.echo_hosts
    "hosts"
  end
  def self.email_updates
    "email"
  end
end

describe "Plugin" do
  it "should define run_before method" do
    Plugin.methods.include?("before_install").should == true
  end
  it "should define run_after method" do
    Plugin.methods.include?("after_install").should == true
  end
  describe "usage" do
    before(:each) do
      @instance = RemoteInstance.new
      @instance.stub!(:ssh).and_return "true"
      @instance.stub!(:scp).and_return "true"
      Kernel.stub!(:system).and_return "true"
    end
    it "should should call echo_hosts after calling configure" do
      TestPlugin.should_receive(:echo_hosts).at_least(1)
      @instance.install
    end
    it "should call email_updates after calling install" do
      TestPlugin.should_receive(:email_updates).at_least(1)
      @instance.install
    end
    it "should call echo_hosts before it calls configure" do
      TestPlugin.should_receive(:echo_hosts).at_least(1).and_return "hi"
      @instance.configure      
    end
  end
end