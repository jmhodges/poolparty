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
    stub_option_load
    @instance = RemoteInstance.new({:ip => "127.0.0.1", :instance_id => "i-abcdef1"})
    @instance.stub!(:ssh).and_return true
    @instance.stub!(:scp).and_return true
    Kernel.stub!(:system).and_return true
    
    @master = Master.new
  end
  
  describe "scping" do
  end
  describe "ssh'ing" do
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
  end
    describe "new configuration style (build scripts)" do
      before(:each) do
        @tempfile = Tempfile.new("/tmp")
        Kernel.stub!(:system).and_return true
        stub_option_load
      end
      describe "with a public ip" do
        before(:each) do
          Application.stub!(:public_ip).and_return "127.0.0.1"
          Master.stub!(:new).and_return @master
          @master.stub!(:nodes).and_return [@instance]
        end
        it "should call configure on the instances after configure_cloud" do
          @instance.should_receive(:configure).and_return true
          @master.configure_cloud
        end
        it "should run associate_address if there is a public_ip set in the Application.options" do
          @instance.should_receive(:associate_address_with).with(Application.public_ip, @instance.instance_id).at_least(1).and_return true
          @master.configure_cloud
        end
        it "should not run associate_address_with if the public_ip is empty" do
          Application.stub!(:public_ip).and_return ""
          @instance.should_not_receive(:associate_address_with)
          @master.configure_cloud
        end
        it "should untar and move plugin directories around" do
          dir = File.basename Application.plugin_dir
          @instance.update_plugin_string.should == "if [[ -f plugins.tar.gz ]]; then mkdir -p #{dir} && tar -zxf plugins.tar.gz -C #{dir}; fi"
        end
        it "should be able to build the configuration tasks each, as runnable" do
          @instance.configure_tasks.should == ["mv ~/tmp/config.yml ~/.config >/dev/null 2>/dev/null &&         mkdir -p ~/.ec2 >/dev/null 2>/dev/null &&         mv ~/tmp/keypair ~/.ec2/id_rsa- >/dev/null 2>/dev/null", "mkdir -p /etc/ha.d/resource.d >/dev/null 2>/dev/null &&         mv ~/tmp/cloud_master_takeover /etc/ha.d/resource.d >/dev/null 2>/dev/null &&         mv ~/tmp/resource.d/* /etc/ha.d/resource.d >/dev/null 2>/dev/null", "mv ~/tmp/node0-hosts /etc/hosts >/dev/null 2>/dev/null &&         hostname -v node0 >/dev/null 2>/dev/null", "mv ~/tmp/haproxy /etc/haproxy.cfg >/dev/null 2>/dev/null &&         sed -i \"s/ENABLED=0/ENABLED=1/g\" /etc/default/haproxy >/dev/null 2>/dev/null &&         sed -i 's/SYSLOGD=\"\"/SYSLOGD=\"-r\"/g' /etc/default/syslogd >/dev/null 2>/dev/null &&         echo \"local0.* /var/log/haproxy.log\" >> /etc/syslog.conf && /etc/init.d/sysklogd restart >/dev/null 2>/dev/null &&         /etc/init.d/haproxy restart >/dev/null 2>/dev/null", "mv ~/tmp/node0-hosts /etc/hosts >/dev/null 2>/dev/null &&         hostname -v node0 >/dev/null 2>/dev/null", "", "if [[ -f plugins.tar.gz ]]; then mkdir -p plugins && tar -zxf plugins.tar.gz -C plugins; fi >/dev/null 2>/dev/null", "", "pool maintain -c ~/.config -l ~/plugins >/dev/null 2>/dev/null", "mv ~/tmp/monitrc /etc/monit/monitrc >/dev/null 2>/dev/null &&         mkdir -p /etc/monit.d/ >/dev/null 2>/dev/null &&         mv ~/tmp/monit.d/* /etc/monit.d/ >/dev/null 2>/dev/null &&         chown root /etc/monit/monitrc >/dev/null 2>/dev/null &&         chmod 700 /etc/monit/monitrc >/dev/null 2>/dev/null", "", "mkdir -p /etc/ha.d >/dev/null 2>/dev/null &&         mv ~/tmp/authkeys /etc/ha.d/ >/dev/null 2>/dev/null"]
          
        end
    end
  end  
  describe "in failover" do
    before(:each) do
      Master.stub!(:new).and_return @master
    end
    it "should be able to become master " do
      @instance.stub!(:configure).and_return true
      @instance.number = 1
      @instance.become_master
      @instance.number.should == 0
    end
    it "should reconfigure after becoming master" do      
      @master.should_receive(:configure_cloud).and_return true
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
    
    describe "when installing the poolparty software" do
      before(:each) do
        @instance.stub!(:run).and_return false
      end
      it "should be able to detect if the stack_installed? == false" do
        @instance.stack_installed?.should == false
      end
      it "should set the stack_installed? once installed" do
        @instance.install
        @instance.stack_installed?.should == true
      end
    end
    
  end
end