require File.dirname(__FILE__) + '/spec_helper'

describe "Master" do
  before(:each) do
    stub_option_load
    Kernel.stub!(:system).and_return true
    Kernel.stub!(:exec).and_return true
    Kernel.stub!(:sleep).and_return true # WHy wait?, just do it
    
    Application.options.stub!(:contract_when).and_return("web > 30.0\n cpu < 0.10")
    Application.options.stub!(:expand_when).and_return("web < 3.0\n cpu > 0.80")
    @master = Master.new
  end  
  after(:all) do
    @master.cleanup_tmp_directory(nil)
  end
  it "should launch the first instances and set the first as the master and the rest as slaves" do
    Application.stub!(:minimum_instances).and_return(1)
    Application.stub!(:verbose).and_return(false) # Hide messages
    Master.stub!(:new).and_return(@master)
    
    @master.stub!(:number_of_running_instances).and_return(0);
    @master.stub!(:number_of_pending_instances).and_return(0);
    @master.stub!(:wait).and_return true
    
    @master.should_receive(:launch_new_instance!).and_return(
    {:instance_id => "i-5849ba", :ip => "127.0.0.1", :status => "running"})
    @master.stub!(:list_of_nonterminated_instances).and_return(
    [{:instance_id => "i-5849ba", :ip => "127.0.0.1", :status => "running"}])
    
    node = RemoteInstance.new({:instance_id => "i-5849ba", :ip => "127.0.0.1", :status => "running"})
    node.stub!(:scp).and_return "true"
    node.stub!(:ssh).and_return "true"
    
    @master.stub!(:number_of_pending_instances).and_return(0)
    @master.stub!(:get_node).with(0).and_return node
    @master.start_cloud!
    
    @master.nodes.first.instance_id.should == "i-5849ba"
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
  describe "with stubbed instances" do
    before(:each) do
      @master.stub!(:list_of_nonterminated_instances).and_return([
          {:instance_id => "i-5849ba", :ip => "127.0.0.1", :status => "running"},
          {:instance_id => "i-5849bb", :ip => "127.0.0.2", :status => "running"},
          {:instance_id => "i-5849bc", :ip => "127.0.0.3", :status => "pending"}
        ])
      Kernel.stub!(:exec).and_return true
      @instance = RemoteInstance.new
      @instance.stub!(:ip).and_return("127.0.0.1")
      @instance.stub!(:name).and_return("node0")
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
      open(@master.build_hosts_file_for(@instance).path).read.should == "127.0.0.1 node0\n127.0.0.1 localhost.localdomain localhost ubuntu\n127.0.0.2 node1\n127.0.0.3 node2"
    end
    it "should be able to build a hosts file for a specific instance" do
      open(@master.build_hosts_file_for(@instance).path).read.should =~ "127.0.0.1 node0"
    end
    it "should be able to build a haproxy file" do
      open(@master.build_haproxy_file.path).read.should =~ "server node0 127.0.0.1:#{Application.client_port}"
    end
    it "should be able to reconfigure the instances (working on two files a piece)" do
      @master.should_receive(:remote_configure_instances).and_return true
      @master.stub!(:number_of_unconfigured_nodes).and_return 1
      @master.reconfigure_cloud_when_necessary
    end
    it "should return the number of unconfigured nodes when asked" do
      @master.nodes.each {|node| node.stub!(:stack_installed?).and_return(true) unless node.master? }
      @master.number_of_unconfigured_nodes.should == 1
    end
    it "should be able to restart the running instances' services" do
      @master.nodes.each {|a| a.should_receive(:restart_with_monit).and_return true }
      @master.restart_running_instances_services
    end
    it "should be able to build a heartbeat auth file" do
      open(@master.build_and_copy_heartbeat_authkeys_file.path).read.should =~ /1 md5/
    end
    describe "configuration" do
      describe "sending configuration files" do
        before(:each) do
          Master.stub!(:new).and_return(@master)
        end
        it "should be able to build a heartbeat resources file for the specific node" do
          open(Master.build_heartbeat_resources_file_for(@master.nodes.first).path).read.should =~ /node0 127/
        end
        it "should be able to build a heartbeat config file" do
          open(Master.build_heartbeat_config_file_for(@master.nodes.first).path).read.should =~ /\nnode node0\nnode node1/
        end      
        it "should be able to say if heartbeat is necessary with more than 1 server or not" do      
          Master.requires_heartbeat?.should == true
        end
        it "should be able to say that heartbeat is not necessary if there is 1 server" do
          @master.stub!(:list_of_nonterminated_instances).and_return([
              {:instance_id => "i-5849ba", :ip => "127.0.0.1", :status => "running"}
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
          @master.should_receive(:configure_cloud).once.and_return(true)
          @master.reconfigure_cloud_when_necessary
        end
        describe "rsync'ing the files to the instances" do
          it "should receive send_config_files_to_nodes after it builds the config files in the temp directory" do
            @master.should_receive(:send_config_files_to_nodes).once
            @master.build_and_send_config_files_in_temp_directory
          end
          it "should run_array_of_tasks(scp_tasks)" do
            @master.should_receive(:run_array_of_tasks).and_return true
            @master.build_and_send_config_files_in_temp_directory
          end
          it "should compile a list of files to rsync" do
            @master.stub!(:run_array_of_tasks).and_return true
            @master.rsync_tasks("#{@master.base_tmp_dir}", "tmp")[0].should =~ /rsync/
          end
        end
        describe "remote configuration" do
          before(:each) do
            @master.stub!(:nodes).and_return [@instance]
          end
          it "should call remote_configure_instances when configuring" do
            @master.should_receive(:remote_configure_instances).and_return true
            @master.configure_cloud
          end
          it "should change the configuration script into an executable and run it" do            
            @master.should_receive(:run_array_of_tasks).and_return true
            @master.remote_configure_instances
          end
        end
        
      end      
    end
    describe "installation" do
      it "should not install on the instances if the application doesn't say it should" do
         Application.stub!(:install_on_load?).and_return false
         Provider.should_not_receive(:install_poolparty)
         @master.install_cloud
      end
      describe "when asked" do
        before(:each) do
          Application.stub!(:install_on_load?).and_return true
          Sprinkle::Script.stub!(:sprinkle).and_return true
          @master.stub!(:execute_tasks).and_return true
        end
        it "should install on the instances if the application says it should" do        
          Provider.should_receive(:install_poolparty)
          @master.install_cloud
        end
        it "should execute the remote tasks on all of the instances" do
          @master.should_receive(:execute_tasks).and_return true
          @master.install_cloud
        end
        describe "stubbing installation" do
          before(:each) do
            @master.stub!(:execute_tasks).and_return true          
          end
          it "should install poolparty" do
            Provider.should_receive(:install_poolparty).and_return true
            Provider.should_receive(:install_userpackages).and_return true
            @master.install_cloud
          end
          it "should install the user packages" do
            Provider.should_receive(:install_poolparty).and_return true
            Provider.should_receive(:install_userpackages).and_return true
            @master.install_cloud
          end
        end
      end
    end
    describe "displaying" do
      it "should be able to list the cloud instances" do
        @master.list.should =~ /CLOUD \(/
      end
    end
    it "should be able to grab a list of the instances" do
      @master.cloud_ips.should == %w(127.0.0.1 127.0.0.2 127.0.0.3)
    end
    describe "starting" do
      it "should request to launch the minimum number of instances" do
        Application.stub!(:minimum_instances).and_return 3
        @master.stub!(:number_of_pending_and_running_instances).and_return 1
        @master.should_receive(:request_launch_new_instances).with(2).and_return true
        @master.launch_minimum_instances
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
        @master.stub!(:web).and_return(31.2)
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
    describe "scaling" do
      it "should try to add a new instance" do
        @master.should_receive(:add_instance_if_load_is_high).and_return true
        @master.scale_cloud!
      end
      it "should try to terminate an instance" do
        @master.should_receive(:terminate_instance_if_load_is_low).and_return true
        @master.scale_cloud!
      end
      it "should try to grow the cloud by 1 node when asked" do
        @master.should_receive(:request_launch_new_instance).once.and_return true
        @master.should_receive(:configure_cloud).once.and_return true
        @master.grow_by(1)
      end
      it "should try to shrink the cloud by 1 when asked" do
        @master.should_receive(:request_termination_of_instance).and_return true
        @master.should_receive(:configure_cloud).and_return true
        @master.shrink_by(1)
      end
    end
  end
  describe "Configuration" do
    before(:each) do
      @instance = RemoteInstance.new
    end
    it "should be able to build the haproxy file" do
      @master.build_haproxy_file
    end
    describe "by copying files to the poolpartytmp directory" do
      it "should build and copy files to the tmp directory" do
        @master.build_and_send_config_files_in_temp_directory
        File.directory?(@master.base_tmp_dir).should == true
      end
      it "should copy the cloud_master_takeover script to the tmp directory" do
        @master.should_receive(:get_config_file_for).at_least(1).and_return "true"
        File.should_receive(:copy).exactly(3).and_return true
        @master.build_and_send_config_files_in_temp_directory
      end
      describe "get configs" do
        before(:each) do
          @master.stub!(:user_dir).and_return("user")
          @master.stub!(:root_dir).and_return("root")
        end
        it "should try to get the config file in the user directory before the root_dir" do
          File.should_receive(:exists?).with("#{@master.user_dir}/config/config.yml").and_return true
          @master.get_config_file_for("config.yml").should == "user/config/config.yml"
        end
        it "should try to get the config file in the root directory if it doesn't exist in the user directory" do
          File.should_receive(:exists?).with("#{@master.user_dir}/config/config.yml").and_return false
          @master.get_config_file_for("config.yml").should == "root/config/config.yml"
        end
      end
      it "should copy the config file if it exists" do
        Application.stub!(:config_file).and_return "config.yml"
        File.stub!(:exists?).and_return true        
        File.should_receive(:copy).exactly(5).times.and_return true
        @master.build_and_send_config_files_in_temp_directory
      end
      describe "with copy_config_files_in_directory_to_tmp_dir method" do
        before(:each) do
          @instance2 = RemoteInstance.new
          @instance2.stub!(:ip).and_return "127.0.0.2"
          Master.stub!(:new).and_return @master
          @master.stub!(:nodes).and_return [@instance, @instance2]
        end
        it "should be able to clean up after itself" do
          File.open("#{@master.base_tmp_dir}/test", "w+") {|f| f << "hello world"}
          @master.cleanup_tmp_directory(nil)
          File.file?("#{@master.base_tmp_dir}/test").should == false
        end
        it "should check to see if there is a directory in the user directory to grab the files from" do
          File.stub!(:directory?).with("/Users/auser/Sites/work/citrusbyte/internal/gems/pool-party/pool/tmp/resource.d").and_return false
          File.should_receive(:directory?).at_least(1).with("#{user_dir}/config/resource.d").at_least(1).and_return true
          @master.copy_config_files_in_directory_to_tmp_dir("config/resource.d")
        end
        it "should copy all the files that are in the directory" do
          Dir.stub!(:[]).and_return ["1","2","3"]
          File.should_receive(:copy).exactly(3).times.and_return true
          @master.copy_config_files_in_directory_to_tmp_dir("config/resource.d")
        end
        it "should copy all the resource.d files from the monit directory to the tmp directory" do
          @master.stub!(:copy_config_files_in_directory_to_tmp_dir).with("config/resource.d").and_return true
          @master.should_receive(:copy_config_files_in_directory_to_tmp_dir).at_least(1).with("config/monit.d").and_return true
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should build the authkeys file for haproxy" do
          @master.should_receive(:build_and_copy_heartbeat_authkeys_file).and_return true
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should build the haproxy configuration file" do
          @master.should_receive(:build_haproxy_file).and_return true
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should build the hosts file for nodes" do
          @master.should_receive(:build_hosts_file_for).at_least(1).and_return true
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should build the ssh reconfigure script" do
          @master.should_receive(:build_reconfigure_instances_script_for).at_least(1).and_return ""
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should be able to build the hosts file for the nodes" do
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should build global files" do
          Master.should_receive(:build_user_global_files).once
          @master.build_and_send_config_files_in_temp_directory
        end
        it "should build user node files" do
          Master.should_receive(:build_user_node_files_for).at_least(1)
          @master.build_and_send_config_files_in_temp_directory
        end
        describe "when the cloud requires heartbeat" do
          before(:each) do
            Master.stub!(:requires_heartbeat?).and_return true
          end
          it "should build the heartbeat configuration file" do
              @master.should_receive(:build_heartbeat_config_file_for).at_least(1).and_return true
              @master.build_and_send_config_files_in_temp_directory
          end
        end
      end
      describe "user define files" do
        it "should have access to global_user_files as an array" do
          Master.global_user_files.class.should == Array
        end
        it "should be able to add a global file to the array" do
          Master.define_global_user_file(:box) {"box"}
          Master.global_user_files.size.should == 1
        end        
        it "should have access to user_node_files as an array" do
          Master.user_node_files.class.should == Array
        end
        it "should be able to add a node file to the array" do
          Master.define_node_user_file(:box) {|a| "#{a}.box"}
          Master.user_node_files.size.should == 1          
        end
        it "should write_to_file_for for each of the global_user_files" do
          Master.should_receive(:write_to_file_for).once.and_return true
          Master.build_user_global_files
        end
        it "should write_to_file_for for each of the user_node_files" do
          Master.should_receive(:write_to_file_for).once.and_return true
          Master.build_user_node_files_for(@instance)
        end
      end
    end
  end
end