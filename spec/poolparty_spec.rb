require File.dirname(__FILE__) + '/spec_helper'

module TestMonitor
  module Master      
  end
  module Remote
  end    
end

describe "Application options" do
  before(:each) do
    stub_option_load
  end
  it "should be able to say that the plugin directory is the current directory" do
    File.basename(PoolParty.plugin_dir).should == "plugin"
  end
  it "should not load plugins if the directory doesn't exist" do
    File.stub!(:directory?).with(plugin_dir).and_return false
    Dir.should_not_receive(:[])
    PoolParty.load_plugins
  end
  it "should load the plugins if the directory exists" do
    File.stub!(:directory?).with(plugin_dir).and_return true
    Dir.should_receive(:[]).and_return %w()
    PoolParty.load_plugins
  end
  describe "monitors" do
    before(:each) do
      PoolParty.reset!
    end
    it "should load a monitor and store it into the registered monitor's array" do
      PoolParty.register_monitor TestMonitor
      PoolParty.registered_monitors.include?(TestMonitor).should == true
    end
    it "should be able to ask if the monitor is a registered monitor" do
      PoolParty.register_monitor TestMonitor
      PoolParty.registered_monitor?(TestMonitor).should == true
    end
    it "should not register a monitor more than once" do
      PoolParty::Monitors.should_receive(:extend).once
      PoolParty.register_monitor TestMonitor
      PoolParty.register_monitor TestMonitor
    end
    it "should try to load from the user directory before the root lib directory" do
      File.should_receive_at_least_once(:directory?).with("#{user_dir}/monitors").and_return true
      Dir.should_receive(:[]).with("#{user_dir}/monitors/*").and_return([])
      PoolParty.load_app
    end
    it "should try to load from the root directory if the user directory monitors don't exist" do
      File.should_receive_at_least_once(:directory?).with("#{user_dir}/monitors").and_return false
      Dir.should_receive(:[]).with("#{Application.root_dir}/lib/poolparty/monitors/*").and_return([])
      PoolParty.load_app
    end
    it "should load the monitors and the plugins" do
      PoolParty.should_receive(:load_plugins)
      PoolParty.should_receive(:load_monitors)
      PoolParty.load_app
    end
  end
end