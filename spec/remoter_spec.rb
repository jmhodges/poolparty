require File.dirname(__FILE__) + '/spec_helper'

class TestRemote
  include Remoter
  include Callbacks
  attr_accessor :ip
end
describe "Remoter" do
  before(:each) do
    @instance = RemoteInstance.new
    @master = Master.new
    
    @remoter = TestRemote.new    
    @remoter.stub!(:put).and_return "true"
    # @tempfile = Tempfile.new("/tmp") do |f|
    #   f << "hi"
    # end
    Application.stub!(:ec2_dir).and_return "/Users"
    Application.stub!(:keypair).and_return "app"
    Application.stub!(:username).and_return "root"
  end
  it "should have an ssh method that corresponds to ssm with the keypair" do
    RemoteInstance.ssh_string.should == "ssh -i /Users/id_rsa-app -o StrictHostKeyChecking=no -l root"
  end
  it "should have a list of ssh_tasks" do
    @remoter.ssh_tasks.should == []
  end
  it "should have a list of scp_tasks" do
    @remoter.scp_tasks.should == []
  end
  it "should reset the values to nil when calling reset" do
    @remoter.target_hosts.should_not be_nil
    @remoter.reset!
    @hosts.should be_nil
  end
  describe "executing" do
    it "should call set_hosts before it executes the tasks" do
      @remoter.should_receive(:set_hosts).once
      @remoter.execute_tasks {}
    end
    it "should not call set_hosts before it executes the task if it explicitly doesn't want it to" do
      @remoter.should_not_receive(:set_hosts)
      @remoter.execute_tasks(:dont_set_hosts => true) {}
    end
    
    describe "ssh" do
      before(:each) do
        @arr = []
        @arr << @a = proc{puts "hello"}
        @arr << @b = proc{puts "world"}
        @instance.stub!(:ip).and_return("127.0.0.1")
      end
      it "should run the tasks in an array with run_thread_list" do
        @remoter.should_receive(:run_thread_list).once
        @remoter.run_array_of_tasks(@arr)
      end
      
      it "should be able to collect the list of the target hosts's ips" do
        Master.should_receive(:new).and_return(@master)
        @master.stub!(:nodes).and_return([@instance])
        @remoter.target_hosts.should == %w(127.0.0.1)
      end
    end
  end
end