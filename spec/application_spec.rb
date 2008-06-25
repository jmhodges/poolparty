require File.dirname(__FILE__) + '/spec_helper'

describe "Application" do
  before(:each) do
    @str=<<-EOS
:access_key:    
  3.14159
    EOS
    @sio = StringIO.new
    StringIO.stub!(:new).and_return @sio
    Application.stub!(:open).with("http://169.254.169.254/latest/user-data").and_return @sio
    @sio.stub!(:read).and_return @str
  end
  it "should be able to send options in the Application.options" do
    options({:optparse => {:banner => "hi"}})
  end
  it "should have the root_dir defined" do
    PoolParty.root_dir.should_not be_nil
  end
  it "should be able to call on the haproxy_config_file" do
    Application.haproxy_config_file.should_not be_nil
  end
  it "should be able to find the client_port" do
    Application.options.should_receive(:client_port).and_return(7788)
    Application.client_port.should == 7788
  end
  it "should always have cloud_master_takeover in the managed services list" do
    Application.master_managed_services.should =~ /cloud_master_takeover/
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
  it "should be able to show the version of the gem" do
    Application.version.should_not be_nil
  end
  it "should show the version as a string" do
    Application.version.class.should == String
  end
  it "should be able to start instances with the the key access information on the user-data" do
    Application.launching_user_data.should =~ /:access_key/
    Application.launching_user_data.should =~ /:secret_access_key/
  end
  it "should parse the yaml in the user-data and return a hash" do
    YAML.should_receive(:load).once.with(@str).and_return({:access_key => "3.14159"})
    Application.local_user_data
  end
  it "should be able to pull out the access_key from the user data" do
    Application.local_user_data[:access_key].should == 3.14159
  end
  it "should overwrite the default_options when passing in to the instance data" do
    Application.stub!(:default_options).and_return({:access_key => 42})
    Application.options.access_key.should == 3.14159
  end
end