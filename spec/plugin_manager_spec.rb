require File.dirname(__FILE__) + '/spec_helper'

describe "Plugin manager" do
  before(:each) do
    FileUtils.stub!(:mkdir_p).and_return true
    Dir["./spec/../lib/../vendor/*"].each {|a| FileUtils.rm_rf a}
    Git.stub!(:clone).and_return true
    PluginManager.stub!(:extract_git_repos_from_plugin_dirs).and_return %w(git@github.com:auser/poolparty-plugins.git)
  end
  it "should git clone the directory when it is installing a plugin" do
    File.stub!(:directory?).and_return false
    Git.should_receive(:clone).with("git@github.com:auser/poolparty.git", "/Users/auser/Sites/work/citrusbyte/internal/gems/pool-party/pool/vendor/poolparty").and_return true
    PluginManager.install_plugin "git@github.com:auser/poolparty.git"
  end
  it "should keep a list of the installed plugin locations" do    
    PluginManager.should_receive(:install_plugin).and_return true
    PluginManager.install_plugin "git@github.com:auser/poolparty-plugins.git"
    PoolParty.installed_plugins.should == ["git@github.com:auser/poolparty-plugins.git"]
  end
  it "should be able to rescan the plugin directory and tell which plugins are installed"
  it "should be able to remove a plugin based on the name"
  it "should be able to extract the git repos from the .git/config file"
end