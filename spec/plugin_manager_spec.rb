require File.dirname(__FILE__) + '/spec_helper'

describe "Plugin manager" do
  before(:each) do
    FileUtils.stub!(:mkdir_p).and_return true
  end
  it "should try to create a new repository on git when calling for a new one" do
    Git.should_receive(:open).and_return true
    PluginManager.new_plugin("name")
  end
  it "should be able to rescan the plugin directory and tell which plugins are installed" do
    PluginManager.scan.should == %w(install_sinatra logging)
  end
  it "should git clone the directory when it is installing a plugin" do
    Git.should_receive(:clone).with("git@github.com:auser/pool-party.git", "./spec/../lib/../plugins/pool-party").and_return true
    PluginManager.install_plugin "git@github.com:auser/pool-party.git"
  end
end