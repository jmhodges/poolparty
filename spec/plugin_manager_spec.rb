require File.dirname(__FILE__) + '/spec_helper'

describe "Plugin manager" do
  it "should be able to create a new repository on git when calling for a new one" do
    PluginManager.new("name")
  end
end