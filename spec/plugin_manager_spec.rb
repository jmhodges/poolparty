require File.dirname(__FILE__) + '/spec_helper'

describe "Plugin manager" do
  before(:each) do
    FileUtils.stub!(:mkdir_p).and_return true
    Dir["./spec/../lib/../vendor/*"].each {|a| FileUtils.rm_rf a}
  end
  it "should git clone the directory when it is installing a plugin" do
    Git.should_receive(:clone).with("git@github.com:auser/pool-party.git", "./spec/../lib/../vendor/pool-party").and_return true
    PluginManager.install_plugin "git@github.com:auser/pool-party.git"
  end
  it "should keep a list of the installed plugin locations" do
    PluginManager.install_plugin "git@github.com:auser/pool-party-plugins.git"
    PoolParty.installed_plugins.should == ["git@github.com:auser/pool-party.git", "git@github.com:auser/pool-party-plugins.git"]
  end
  it "should be able to rescan the plugin directory and tell which plugins are installed" do
    PluginManager.install_plugin "git@github.com:auser/pool-party-plugins.git"
    PluginManager.scan.should == %w(pool-party-plugins)
  end
  it "should be able to remove a plugin based on the name" do
    PluginManager.install_plugin "git@github.com:auser/pool-party-plugins.git"
    PluginManager.remove_plugin "pool-party-plugins"
    PluginManager.scan.should == %w()
  end
  it "should be able to extract the git repos from the .git/config file" do
    PluginManager.install_plugin "git@github.com:auser/pool-party-plugins.git"
    PoolParty.reset!
    PoolParty.installed_plugins.should == ["git@github.com:auser/pool-party-plugins.git"]
  end
end