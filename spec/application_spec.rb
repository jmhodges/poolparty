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
  it "should be able to say it is in development mode if it is in dev mode" do
    Application.stub!(:environment).and_return("development")
    Application.development?.should == true
  end
  it "should be able to say it is in production if it is in production" do
    Application.stub!(:environment).and_return("production")
    Application.production?.should == true
  end
  it "should be able to say it's keypair path is in the $HOME/ directory" do
    Application.stub!(:ec2_dir).and_return("~/.ec2")
    Application.stub!(:keypair).and_return("poolparty")
    Application.keypair_path.should == "~/.ec2/id_rsa-poolparty"
  end
end