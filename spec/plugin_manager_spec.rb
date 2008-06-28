require File.dirname(__FILE__) + '/spec_helper'

describe "Plugin manager" do
  before(:each) do
    FileUtils.stub!(:mkdir_p).and_return true
    Dir["./spec/../lib/../vendor/*"].each {|a| FileUtils.rm_rf a}
  end
  it "should git clone the directory when it is installing a plugin" do
    File.stub!(:directory?).and_return false
    Git.should_receive(:clone).with("git@github.com:auser/PoolParty.git", "/Users/auser/Sites/work/citrusbyte/internal/gems/poolparty/pool/vendor/poolparty").and_return true
    PluginManager.install_plugin "git@github.com:auser/PoolParty.git"
  end
  it "should keep a list of the installed plugin locations" do
    PluginManager.install_plugin "git@github.com:auser/poolparty-plugins.git"
    PoolParty.installed_plugins.should == ["git@github.com:auser/poolparty-plugins.git"]
  end
  it "should be able to rescan the plugin directory and tell which plugins are installed" do
    PluginManager.install_plugin "git@github.com:auser/poolparty-plugins.git"
    PluginManager.scan.should == %w(poolparty-plugins)
  end
  it "should be able to remove a plugin based on the name" do
    PluginManager.install_plugin "git@github.com:auser/poolparty-plugins.git"
    PluginManager.remove_plugin "poolparty-plugins"
    PluginManager.scan.should == %w()
  end
  it "should be able to extract the git repos from the .git/config file" do
    PluginManager.install_plugin "git@github.com:auser/poolparty-plugins.git"
    PoolParty.reset!
    PoolParty.installed_plugins.should == ["git@github.com:auser/poolparty-plugins.git"]
  end
end