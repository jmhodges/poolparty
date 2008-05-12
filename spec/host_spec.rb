require File.dirname(__FILE__) + '/spec_helper'

describe "Host" do
  before(:each) do
    @host = Host.new
    @env = Rack::MockRequest.env_for("http://127.0.0.1:7788/")
    
    @ec2 = EC2::Base.new( :access_key_id => "not a key", :secret_access_key => "not a secret" )
    @host.stub!(:launch_new_instance!).and_return({:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
    
    @host.stub!(:ec2).and_return(@ec2)
    @host.stub!(:get_instances_description).and_return([])
  end
  
  describe "in general" do
    it "should have options that are the same options as the Application for configuration reasons" do
      @host.options.should == Application.options
    end
    it "should have the same options on the Application for the port" do
      @host.port.should == Application.host_port
    end
  end
  
  describe "dealing with instances" do
    it "should be able to launch a new instance with launch_new_instance!" do
      @host.launch_new_instance!.should == {:instance_id=>"i-5849ba", :ip=>"ip-127-0-0-1.aws.amazon.com", :status=>"running"}
    end
    it "should be able to get the minimum number of instances running from the config file and the actual running data" do
      @host.stub!(:get_instances_description).and_return([])
      (Application.minimum_instances - @host.number_of_running_instances).should == 1
      @host.stub!(:get_instances_description).and_return([{:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}])
      (Application.minimum_instances - @host.number_of_running_instances).should == 0
    end
    it "should be able to launch_minimum_instances" do
      @host.launch_minimum_instances
    end
  end
  
  describe "error reporting" do
    it "should be able to respond with a 404" do
      @host.return_error(404, @env, "error").should == [404, {"Content-Type"=>"text/html"}, "<h1>Error</h1><br />error"]
    end
  end
  
end