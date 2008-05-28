require File.dirname(__FILE__) + '/spec_helper'

describe "Master" do
  before(:each) do
    Application.options.stub!(:contract_when).and_return("web_requests > 30.0\n cpu_usage < 0.10")
    Application.options.stub!(:expand_when).and_return("web_requests < 3.0\n cpu_usage > 0.80")
    @master = Master.new
  end  
  it "should launch the first instances and set the first as the master and the rest as slaves" do
    Application.stub!(:minimum_instances).and_return(1)
    Application.stub!(:verbose).and_return(false) # Hide messages
    Master.stub!(:new).and_return(@master)
    
    @master.stub!(:number_of_running_instances).and_return(0);
    @master.stub!(:number_of_pending_instances).and_return(0);
    
    @master.should_receive(:launch_new_instance!).and_return(
    {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
    @master.stub!(:list_of_nonterminated_instances).and_return(
    [{:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}])
    @master.start_cloud!
    @master.nodes.first.instance_id.should == "i-5849ba"
  end
  describe "with stubbed instances" do
    before(:each) do
      @master.stub!(:list_of_nonterminated_instances).and_return([
          {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"},
          {:instance_id => "i-5849bb", :ip => "ip-127-0-0-2.aws.amazon.com", :status => "running"},
          {:instance_id => "i-5849bc", :ip => "ip-127-0-0-3.aws.amazon.com", :status => "pending"}
        ])
      Kernel.stub!(:exec).and_return true
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
    it "should be able to get a specific node in the nodes from the master" do
      @master.get_node(2).instance_id.should == "i-5849bc"
    end
    it "should be able to build a hosts file" do
      open(@master.build_hosts_file.path).read.should == "node0\tip-127-0-0-1.aws.amazon.com\nnode1\tip-127-0-0-2.aws.amazon.com\nnode2\tip-127-0-0-3.aws.amazon.com"
    end
    it "should be able to build a haproxy file" do
      open(@master.build_haproxy_file.path).read.should =~ "server node0 ip-127-0-0-1.aws.amazon.com:#{Application.client_port}"
    end
    it "should be able to reconfigure the instances (working on two files a piece)" do
      @master.nodes.each {|a| a.should_receive(:configure).and_return true }
      @master.reconfigure_running_instances
    end
    it "should be able to restart the running instances' services" do
      @master.nodes.each {|a| a.should_receive(:restart_with_monit).and_return true }
      @master.restart_running_instances_services
    end
    it "should be able to build a heartbeat auth file" do
      open(@master.build_heartbeat_authkeys_file).read.should =~ /1 md5/
    end
    describe "configuring" do
      before(:each) do
        Master.should_receive(:new).and_return(@master)
      end
      it "should be able to build a heartbeat resources file for the specific node" do
        open(Master.build_heartbeat_resources_file_for(@master.nodes.first)).read.should =~ /node0\tip-127/
      end
      it "should be able to build a heartbeat config file" do
        open(Master.build_heartbeat_config_file_for(@master.nodes.first)).read.should =~ /\nnode node0\nnode node1/
      end      
      it "should be able to say if heartbeat is necessary with more than 1 server or not" do      
        Master.requires_heartbeat?.should == true
      end
      it "should be able to say that heartbeat is not necessary if there is 1 server" do
        @master.stub!(:list_of_nonterminated_instances).and_return([
            {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}
          ])
        Master.requires_heartbeat?.should == false
      end
    end
    describe "displaying" do
      it "should be able to list the cloud instances" do
        @master.list.should =~ /CLOUD \(/
      end
    end
    describe "monitoring" do
      it "should start the monitor when calling start_monitor!" do
        @master.should_receive(:run_thread_loop).and_return(Proc.new {})
        @master.start_monitor!
      end
      it "should request to launch a new instance" do
        @master.should_receive(:add_instance_if_load_is_high).and_return(true)
        @master.add_instance_if_load_is_high
      end
      it "should request to terminate a non-master instance if the load" do
        @master.should_receive(:request_termination_of_instance).and_return(true)
        @master.terminate_instance_if_load_is_low
      end
    end
    describe "expanding and contracting" do      
      it "should be able to say that it should not contract" do            
        @master.stub!(:web_requests).and_return(10.2)
        @master.stub!(:cpu_usage).and_return(0.32)
        
        @master.valid_rules?(:contract_when).should == false
      end
      it "should be able to say that it should contract" do      
        @master.stub!(:web_requests).and_return(30.2)
        @master.stub!(:cpu_usage).and_return(0.05)

        @master.valid_rules?(:contract_when).should == true
      end
      it "should be able to say that it should not expand if it shouldn't expand" do
        @master.stub!(:web_requests).and_return(30.2)
        @master.stub!(:cpu_usage).and_return(0.92)

        @master.valid_rules?(:expand_when).should == false
      end
      it "should be able to say that it should expand if it should expand" do
        @master.stub!(:web_requests).and_return(1.2)
        @master.stub!(:cpu_usage).and_return(0.92)

        @master.valid_rules?(:expand_when).should == true
      end
    end
  end
end