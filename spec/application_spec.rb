require File.dirname(__FILE__) + '/spec_helper'

describe "Application" do
  it "should have the root_dir defined" do
    Application.root_dir.should_not be_nil
  end
  it "should be able to call on the haproxy_config_file" do
    Application.haproxy_config_file.should_not be_nil
  end
  it "should be able to find the client_port" do
    Application.options.should_receive(:client_port).and_return(7788)
    Application.client_port.should == 7788
  end
  it "should always have haproxy in the managed services list" do
    Application.managed_services =~ /haproxy/
  end
end