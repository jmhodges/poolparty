require File.dirname(__FILE__) + '/spec_helper'

describe "Plugin manager" do
  before(:each) do
    FileUtils.stub!(:mkdir_p).and_return true
  end
  it "should be able to create a new repository on git when calling for a new one" do
    Git.should_receive(:open).and_return true
    PluginManager.new_plugin("name")
  end
end