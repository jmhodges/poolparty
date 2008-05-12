require File.dirname(__FILE__) + '/spec_helper'

describe "Host" do
  before(:each) do
    @host = Host.new
    @env = Rack::MockRequest.env_for("http://127.0.0.1:7788/")
    
    @ec2 = EC2::Base.new( :access_key_id => "not a key", :secret_access_key => "not a secret" )
    @host.stub!(:launch_new_instance!).and_return({:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
    
    @host.stub!(:ec2).and_return(@ec2)
    @host.stub!(:get_instances_description).and_return([{:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}])
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
    it "should update the instance values and should return an array" do
      @host.update_instance_values.class.should == Array
    end
    it "should return update_instance_values an array of RemoteInstances" do
      @host.update_instance_values.first.class.should == RemoteInstance
    end
    it "should not update the instance values if it is already set" do
      @host.update_instance_values
      @host.should_not_receive(:list_of_running_instances)
      @host.running_instances
    end
    it "should be able to launch_minimum_instances" do
      @host.stub!(:number_of_running_instances).and_return 0
      @host.stub!(:number_of_pending_instances).and_return 0
      @host.should_receive(:launch_new_instance!).and_return({:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
      @host.launch_minimum_instances
    end
    it "should keep track of the current load"
    it "should add_instance_if_load_is_high"
    it "should terminate_instance_if_load_is_low"
  end
  
  describe "when shutting down an instance" do
    before(:each) do
      Application.stub!(:interval_wait_time).and_return "30.seconds"
    end
    it "should be able to shut down an instance with request_termination_of_instance" do
      @host.stub!(:can_shutdown_an_instance?).and_return true
      @host.should_receive(:terminate_instance!).and_return true
      @host.request_termination_of_instance("i-5849ba")
    end
    it "should check with can_shutdown_an_instance? to shutdown an instance" do
      @host.should_receive(:shutdown_time).once.and_return Time.now
      @host.can_shutdown_an_instance?.should == false
    end
    it "should not return true for can_shutdown_an_instance? if the minimum instances aren't running" do
      @host.should_receive(:shutdown_time).once.and_return eval("10.minutes.ago")
      @host.should_receive(:minimum_number_of_instances_are_running?).and_return false
      @host.can_shutdown_an_instance?.should == false
    end
    it "should return true if the minimum instances are running and the interval-wait-time has passed" do
      @host.should_receive(:shutdown_time).once.and_return eval("10.minutes.ago")
      @host.should_receive(:minimum_number_of_instances_are_running?).and_return true
      @host.can_shutdown_an_instance?.should == true
    end
  end
  
  describe "monitoring the instances" do
    before(:each) do
      @host.stub!(:get_instances_description).and_return([
        {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"},
        {:instance_id => "i-5849bb", :ip => "ip-127-0-0-2.aws.amazon.com", :status => "running"}
        ])
    end
    it "should run_thread_loop when calling start_monitor!" do
      @host.should_receive(:run_thread_loop).once.and_yield lambda {}
      @host.start_monitor!
    end
    it "should cycle through the list of the RemoteInstances on get_next_instance_for_proxy" do
      # Stub those darn RemoteInstances
      running = []
      @host.get_instances_description.each {|a| running << RemoteInstance.new(a)}
      running.each {|a| a.stub!(:status_level).and_return(0.2) }
      @host.stub!(:running_instances).and_return(running)
      @host.get_next_instance_for_proxy.instance_id.should == "i-5849ba"
      @host.get_next_instance_for_proxy.instance_id.should == "i-5849bb"
      @host.get_next_instance_for_proxy.instance_id.should == "i-5849ba"
    end
    it "should start monitoring the servers when calling start!" do
      @host.should_receive(:launch_minimum_instances).once
      @host.should_receive(:start_monitor!).once
      @host.should_receive(:start_server!).once
      @host.start!
    end
  end
  
  describe "error reporting" do
    it "should be able to respond with a 404" do
      @host.return_error(404, @env, "error").should == [404, {"Content-Type"=>"text/html"}, "<h1>Error</h1><br />error"]
    end
  end
  
end