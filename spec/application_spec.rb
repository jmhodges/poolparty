require File.dirname(__FILE__) + '/spec_helper'

describe "Application" do
  it "should have the root_dir defined" do
    Application.root_dir.should_not be_nil
  end
  it "should be able to call on the haproxy_config_file" do
    Application.haproxy_config_file.should_not be_nil
  end
end