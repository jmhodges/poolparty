require File.dirname(__FILE__) + '/spec_helper'

class RemoteInstance
  def scp(src="", dest="", opts={})
    "true"
  end
  # Ssh into the instance or run a command, if the cmd is set
  def ssh(cmd="")
    "true"
  end
end
describe "remote instance" do
  before(:each) do
    @instance = RemoteInstance.new({:ip => "127.0.0.1"})
    @instance.stub!(:ssh).and_return ""
    @instance.stub!(:scp).and_return ""
    @master = Master.new
  end
  
  describe "in general" do
    it "should set the ip upon creation" do
      @instance.ip.should == "127.0.0.1"
    end
    it "should be able to tell if it is the master" do
      @instance.master?.should == true
    end
    it "should be able to say that it isn't secondary?" do
      @instance.secondary?.should_not be_true
    end
    it "should be able to build itself a haproxy_resources_entry" do
      @instance.haproxy_resources_entry.should =~ /node0/
    end
    it "should be able to build a list of the heartbeat nodes" do
      @instance.node_entry.should =~ /node0/
    end
    it "should be able to build a hosts_entry for self" do
      @instance.hosts_entry.should =~ /node0/
    end
    it "should be able to have local_hosts_entry with 127.0.0.01" do
      @instance.local_hosts_entry.should =~ /127\.0\.0\.1/
    end
    it "should have a heartbeat_entry" do
      @instance.heartbeat_entry.should =~ /127\.0\.0\.1/
      @instance.heartbeat_entry.should =~ /#{Application.managed_services}/
    end
    it "should be able to build a haproxy_entry" do
      @instance.haproxy_entry.should =~ /server/
    end
    it "should call configure after it calls install_stack" do
      @instance.should_receive(:configure).once.and_return(true)
      @instance.install_stack
    end
    it "should call restart_with_monit after it calls configure" do
      @instance.should_receive(:restart_with_monit).once.and_return(true)
      @instance.configure
    end
  end
  describe "configuration" do
    it "should be able to configure_ruby" do
      @instance.should_receive(:install_ruby).and_return true
      @instance.should_receive(:install_rubygems).and_return true
      @instance.should_receive(:install_required_gems).and_return true
      @instance.configure_ruby.should == ""
    end
    it "should be able to configure_master" do
      @instance.should_receive(:ssh).with("pool maintain -c ~/.config").and_return true
      @instance.configure_master
    end
    it "should be able to build configure_master_failover" do
      @instance.should_receive(:ssh).with("mkdir /etc/ha.d/resource.d/").and_return true
      @instance.configure_master_failover
    end
    it "should be able to configure_linux" do
      @instance.should_receive(:ssh).with("hostname -v node0").and_return true
      @instance.configure_linux
    end
    it "should be able to configure_hosts" do
      file = Tempfile.new("/tmp")
      Master.should_receive(:build_hosts_file_for).with(@instance).and_return file
      @instance.should_receive(:scp).and_return true
      @instance.configure_hosts
    end
    it "should be able to configure_haproxy" do
      @instance.should_receive(:install_haproxy).and_return true
      @instance.should_receive(:scp).and_return true
      @instance.configure_haproxy
    end
    it "should be able to configure_heartbeat" do
      file = Tempfile.new("/tmp")
      @instance.should_receive(:install_heartbeat).and_return true
      @instance.should_receive(:write_to_temp_file).and_return file
      
      Master.should_receive(:build_heartbeat_config_file_for).and_return file
      Master.should_receive(:build_heartbeat_resources_file_for).and_return file
      
      @instance.should_receive(:ssh).with("mkdir /etc/ha.d/resource.d/").and_return true
      @instance.should_receive(:ssh).with("/etc/init.d/heartbeat start").and_return true
      
      @instance.configure_heartbeat
    end
    it "should be able to configure_s3fuse" do
      Application.should_receive(:shared_bucket).twice.and_return "test_bucketz"
      @instance.should_receive(:install_s3fuse).and_return true
      @instance.should_receive(:ssh).at_least(1).and_return true
      @instance.configure_s3fuse
    end
    it "should be able to configure_monit" do
      @instance.should_receive(:install_monit).and_return true
      @instance.should_receive(:ssh).with("mkdir /etc/monit.d").and_return true
      @instance.should_receive(:scp).twice.and_return true
      @instance.configure_monit
    end
    it "should be able to configure the stack" do
      @instance.should_receive(:configure_ruby).and_return true
      @instance.should_receive(:configure_master).and_return true
      @instance.should_not_receive(:configure_master_failover)
      @instance.should_receive(:configure_linux).and_return true
      @instance.should_receive(:configure_hosts).and_return true
      @instance.should_receive(:configure_haproxy).and_return true
      Master.should_receive(:requires_heartbeat?).and_return true
      @instance.should_receive(:configure_heartbeat).and_return true
      @instance.should_receive(:configure_s3fuse).and_return true
      @instance.should_receive(:configure_monit).and_return true
      @instance.configure
    end
    describe "new configuration style (build scripts)" do
      before(:each) do
        @tempfile = Tempfile.new("/tmp")
      end
      it "should try to run the scp build file" do
        Master.should_receive(:build_scp_instances_script_for).with(@instance).and_return @tempfile
        @instance.new_configure
      end
      it "should scp the reconfigure file to the remote instance"
      it "should ssh and execute the reconfigure file on the remote instance"

    end
  end  
  describe "in failover" do
    it "should be able to become master " do
      @instance.stub!(:configure).and_return true
      @instance.number = 1
      @instance.become_master
      @instance.number.should == 0
    end
    it "should reconfigure after becoming master" do
      @instance.should_receive(:configure).and_return true
      @instance.become_master
    end
    it "should say that it is the master after becoming master" do
      @instance.stub!(:configure).and_return true
      @instance.become_master
      @instance.master?.should == true
    end
    it "should be able to detect is_not_master_and_master_is_not_running? and return false when the server is the master" do
      @instance.is_not_master_and_master_is_not_running?.should == false
    end
    it "should be able to detect is_not_master_and_master_is_not_running? and return false when the master server is responding" do
      Master.stub!(:is_master_responding?).and_return true
      @instance.is_not_master_and_master_is_not_running?.should == false
    end
    it "should be able to detect is_not_master_and_master_is_not_running? and return false when the master server is responding" do
      @instance.stub!(:master?).and_return false
      Master.stub!(:is_master_responding?).and_return false
      @instance.is_not_master_and_master_is_not_running?.should == true
    end
    it "should be able to detect if the stack_installed?" do
      @instance.stack_installed?.should == false
    end
  end
end