require File.dirname(__FILE__) + '/spec_helper'

describe "Application options" do
  before(:each) do
    # stub_option_load
  end
  it "should be able to say that the plugin directory is the current directory" do
    File.basename(PoolParty.plugin_dir).should == "vendor"
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
end