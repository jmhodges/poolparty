require File.dirname(__FILE__) + '/spec_helper'

describe "Master" do
  before(:each) do
    Kernel.stub!(:system).and_return true
    Kernel.stub!(:exec).and_return true
    Kernel.stub!(:sleep).and_return true # WHy wait?
    
    Application.options.stub!(:contract_when).and_return("web > 30.0\n cpu < 0.10")
    Application.options.stub!(:expand_when).and_return("web < 3.0\n cpu > 0.80")
    @master = Master.new
  end  
  it "should launch the first instances and set the first as the master and the rest as slaves" do
    Application.stub!(:minimum_instances).and_return(1)
    Application.stub!(:verbose).and_return(false) # Hide messages
    Master.stub!(:new).and_return(@master)
    
    @master.stub!(:number_of_running_instances).and_return(0);
    @master.stub!(:number_of_pending_instances).and_return(0);
    @master.stub!(:wait).and_return true
    
    @master.should_receive(:launch_new_instance!).and_return(
    {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
    @master.stub!(:list_of_nonterminated_instances).and_return(
    [{:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}])
    
    node = RemoteInstance.new({:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"})
    node.stub!(:scp).and_return "true"
    node.stub!(:ssh).and_return "true"
    
    @master.stub!(:number_of_pending_instances).and_return(0)
    @master.stub!(:get_node).with(0).and_return node
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
      open(@master.build_hosts_file.path).read.should == "ip-127-0-0-1.aws.amazon.com node0\nip-127-0-0-2.aws.amazon.com node1\nip-127-0-0-3.aws.amazon.com node2"
    end
    it "should be able to build a hosts file for a specific instance" do
      open(@master.build_hosts_file_for(@master.nodes.first).path).read.should =~ "127.0.0.1 node0"
    end
    it "should be able to build a haproxy file" do
      open(@master.build_haproxy_file.path).read.should =~ "server node0 ip-127-0-0-1.aws.amazon.com:#{Application.client_port}"
    end
    it "should be able to reconfigure the instances (working on two files a piece)" do
      @master.nodes.each {|a| a.should_receive(:configure).and_return true if a.status =~ /running/}
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
        Master.stub!(:new).and_return(@master)
      end
      it "should be able to build a heartbeat resources file for the specific node" do
        open(Master.build_heartbeat_resources_file_for(@master.nodes.first)).read.should =~ /node0 ip-127/
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
      it "should only install the stack on nodes that don't have it marked locally as installed" do
        @master.nodes.each {|i| i.should_receive(:stack_installed?).and_return(true)}
        @master.should_not_receive(:reconfigure_running_instances)
        @master.reconfigure_cloud_when_necessary
      end
      it "should install the stack on all the nodes (because it needs reconfiguring) if there is any node that needs the stack" do
        @master.nodes.first.should_receive(:stack_installed?).and_return(false)
        @master.should_receive(:reconfigure_running_instances).once.and_return(true)
        @master.reconfigure_cloud_when_necessary
      end
      describe "with new configuration and installation (build scripts)" do
        before(:each) do
          @node = @master.nodes.first
        end
        it "should be able to build_scp_instances_script_for" do
          @node.should_receive(:scp_string).exactly(10).times.and_return("true")
          Master.build_scp_instances_script_for(@node)
        end
        it "should be able to build_scp_instances_script_for and contain scp 10 times" do
          open(Master.build_scp_instances_script_for(@node)).read.scan(/scp/).size.should == 10
        end
        it "should be able to build_reconfigure_instances_script_for" do          
          str = open(Master.build_reconfigure_instances_script_for(@node)).read
          str.should =~ /hostname -v node0/
          str.should =~ /mkdir \/etc\/ha\.d\/resource\.d/
          str.should =~ /pool\ maintain\ \-c \~\/\.config/
        end        
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
        @master.should_receive(:contract?).and_return(true)
        @master.should_receive(:request_termination_of_instance).and_return(true)
        @master.terminate_instance_if_load_is_low
      end
    end
    describe "expanding and contracting" do      
      it "should be able to say that it should not contract" do            
        @master.stub!(:web).and_return(10.2)
        @master.stub!(:cpu).and_return(0.32)
        
        @master.contract?.should == false
      end
      it "should be able to say that it should contract" do      
        @master.stub!(:web).and_return(30.2)
        @master.stub!(:cpu).and_return(0.05)

        @master.contract?.should == true
      end
      it "should be able to say that it should not expand if it shouldn't expand" do
        @master.stub!(:web).and_return(30.2)
        @master.stub!(:cpu).and_return(0.92)

        @master.expand?.should == false
      end
      it "should be able to say that it should expand if it should expand" do
        @master.stub!(:web).and_return(1.2)
        @master.stub!(:cpu).and_return(0.92)

        @master.expand?.should == true
      end      
    end
  end
  describe "Singleton methods" do
    before(:each) do
      @master = Master.new
      @instance = RemoteInstance.new
      @blk = Proc.new {puts "new"}
      Master.stub!(:new).once.and_return @master
    end
    it "should be able to run with_nodes" do      
      Master.should_receive(:new).once.and_return @master
      @master.should_receive(:nodes).once.and_return []
      Master.with_nodes &@blk
    end
    it "should run the block on each node" do      
      collection = [@instance]
      @master.should_receive(:nodes).once.and_return collection
      collection.should_receive(:each).once
      Master.with_nodes &@blk
    end
  end
end