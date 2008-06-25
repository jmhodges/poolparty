require File.dirname(__FILE__) + '/spec_helper'

describe "Application options" do
  before(:each) do
    # stub_option_load
  end
  it "should parse and use a config file if it is given for the options" do
    YAML.should_receive(:load).and_return({:config_file => "config/sample-config.yml"})
    Application.make_options(:config_file => "config/sample-config.yml")
  end
  it "should be able to say that the plugin directory is the current directory" do
    File.basename(PoolParty.plugin_dir).should == "vendor"
  end
end