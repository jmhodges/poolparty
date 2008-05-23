require File.dirname(__FILE__) + '/spec_helper'

describe "Master" do
  before(:each) do
    @master = Master.new
  end  
  it "should launch the first instances and set the first as the master and the rest as slaves" do
    Application.stub!(:minimum_instances).and_return(2)
    
    @master.stub!(:number_of_running_instances).and_return(0);
    @master.stub!(:number_of_pending_instances).and_return(0);
    
    @master.should_receive(:launch_new_instance!).twice.and_return(
    {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
    @master.start_cloud!
    @master.servers.first.instance_id.should == "i-5849ba"
  end
  describe "with stubbed instances" do
    before(:each) do
      @master.stub!(:list_of_running_instances).and_return([
          {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"},
          {:instance_id => "i-5849bb", :ip => "ip-127-0-0-2.aws.amazon.com", :status => "running"},
          {:instance_id => "i-5849bc", :ip => "ip-127-0-0-3.aws.amazon.com", :status => "pending"}
        ])
    end
    
    it "should be able to go through the instances and assign them numbers" do
      i = 0
      @master.nodes.each do |node|
        node.number.should == i
        i += 1
      end
    end
    it "should be able to say that the master is the master" do
      @master.nodes.first.master?.should == true      
    end
    it "should be able to say that the slave is not a master" do
      @master.nodes[1].master?.should == false
    end
    it "should be able to build a hosts file" do
      open(@master.build_hosts_file.path).read.should == "node-0\tip-127-0-0-1.aws.amazon.com\nnode-1\tip-127-0-0-2.aws.amazon.com\nnode-2\tip-127-0-0-3.aws.amazon.com"
    end
    it "should be able to build a haproxy file" do
      open(@master.build_haproxy_file.path).read.should == "server node-0 ip-127-0-0-1.aws.amazon.com:#{Application.client_port} weight 1 minconn 3 maxconn 6 check inter 30000\nserver node-1 ip-127-0-0-2.aws.amazon.com:#{Application.client_port} weight 1 minconn 3 maxconn 6 check inter 30000\nserver node-2 ip-127-0-0-3.aws.amazon.com:#{Application.client_port} weight 1 minconn 3 maxconn 6 check inter 30000"
    end
    it "should be able to reconfigure the instances (working on two files a piece)" do
      Kernel.should_receive(:system).exactly(6).times.and_return true
      @master.reconfigure_running_instances
    end
    it "should be able to restart the running instances' services" do
      Kernel.should_receive(:system).exactly(3).times.and_return true
      @master.restart_running_instances_services
    end
  end
  describe "monitor!" do
    it "should start the monitor when calling start_monitor!" do
      @master.should_receive(:run_thread_loop).and_return(Proc.new {})
      @master.start_monitor!
      Process.kill("INT", 0)
    end
  end
end