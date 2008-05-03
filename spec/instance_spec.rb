require File.dirname(__FILE__) + '/helper'

context "when running" do
  setup do
    @instance = Instance.new
  end
  specify "should be able to start with the bucket" do
    @instance.should_not be_nil
  end
  specify "should not register when started" do
    @instance.registered?.should == true
  end
end
context "when starting or stopping" do
  setup do
    @ec2 = EC2::Base.new(:access_key_id => Planner.access_key_id, :secret_access_key => Planner.secret_access_key)
    # Coordinator.shutdown_all!
    @instance = Instance.new
  end
  specify "should be able to start itself" do
    @instance.start!
    @instance.state.should == "running"
    @instance.stop!
  end
  specify "should be able to shut itself off" do
    @instance.start!
    @instance.stop!
    @instance.state.should =~ /shutting/
  end
end
context "a running instance" do
  setup do
    Coordinator.init
    @instance = Coordinator.add! "hoax"
  end
  specify "should be able to grab it's external ip address" do
    @instance.start!
    @instance.external_ip.should_not be_nil
    @instance.external_ip.should =~ /amazon/
    @instance.stop!
  end
  specify "should be able to set it's external_ip address after updating registration" do
    @instance.start!
    ip = AWS::S3::S3Object.value @instance.instance_id, @bucket
    ip.should_not be_nil
    @instance.external_ip.should == ip.split("\n")[0]
    @instance.stop!
  end
end