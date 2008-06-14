require File.dirname(__FILE__) + '/spec_helper'

describe "Application options" do
  it "should parse and use a config file if it is given for the options" do
    YAML.should_receive(:load).and_return({:config_file => "config/sample-config.yml"})
    Application.make_options(:config_file => "config/sample-config.yml")
  end
  it "should require all the plugin's init files in the plugin directory" do
    PoolParty.should_receive(:load_plugins).once
    Application.options
  end
end