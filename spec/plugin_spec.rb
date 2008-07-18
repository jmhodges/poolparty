require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + "/helpers/ec2_mock"

class TestPlugin < PoolParty::Plugin
  after_define_tasks :takss
  after_install :email_updates, :echo_hosts
  before_configure_cloud :echo_hosts  
  after_start :echo_start
  
  def echo_start(master)
    "start"
  end
  def echo_hosts(caller)
    write_out "hosts"
  end
  def email_updates(caller)
    write_out "email_updates"
  end
  def takss(tasks)
    "tasks"
  end
  def write_out(msg="")    
  end
end

describe "Plugin" do
  it "should define run_before method" do
    TestPlugin.methods.include?("before_install").should == true
  end
  it "should define run_after method" do
    TestPlugin.methods.include?("after_install").should == true
  end
  it "should define a singleton method on the plugin'ed class" do
    Master.new.methods.include?("testplugin").should == true
  end
  describe "usage" do
    before(:each) do
      stub_option_load
      @num = 2
      @test, @master, @instances = PoolParty::PluginSpecHelper.define_stubs(TestPlugin, @num)
      @instance = @instances.first
    end
    it "should should call echo_hosts after calling configure" do
      @test.should_receive_at_least_once(:write_out).with("email_updates")
      @instance.install
    end
    describe "installation" do
      before(:each) do
        Application.stub!(:install_on_load?).and_return true        
      end
      it "should call install on each of the instances after calling install_cloud" do
        @test.should_receive(:email_updates).exactly(@num)
        @test.should_receive(:echo_hosts).exactly(@num)
        @master.install_cloud
      end
      it "should call email_updates after calling install" do
        @test.should_receive(:email_updates).twice
        @master.install_cloud
      end
      it "should call echo_hosts before it calls configure" do
        @test.should_receive(:echo_hosts).at_least(1).and_return "hi"
        @master.install_cloud
      end
    end
    it "should say that it started on the master" do
      @master.stub!(:launch_minimum_instances)
      @master.stub!(:wait_for_all_instances_to_boot)
      @master.stub!(:setup_cloud)
      @test.should_receive(:echo_start).at_least(1).and_return "hi"
      @master.start
    end
    it "should not call echo_hosts after if configures" do
      @test.stub!(:echo_hosts).and_return true
      @test.should_not_receive(:email_updates)
      @master.configure_cloud
    end
    describe "user-data" do
      it "should be able to add to the user-data with a string" do
        @test.add_user_data("hollow")
        Application.launching_user_data.should =~ /:user_data: hollow/
      end
      it "should be able to add a hash to the user-data with a hash" do
        @test.add_user_data(:box => "box")
        Application.launching_user_data.should =~ /:box: box/
      end
    end
    describe "instance methods" do
      before(:each) do
        @str = "filename"
        @str.stub!(:read).and_return "filename"
        @test.stub!(:open).and_return @str
      end
      it "should try to open the file with the given filename" do
        @test.should_receive(:open).with("filename").and_return @str
        @test.read_config_file("filename")
      end
      it "should open a yaml file" do
        YAML.should_receive(:load).with("filename").and_return ""
        @test.read_config_file("filename")
      end
      describe "when reading the yaml file" do
        before(:each) do
          @str.stub!(:read).and_return ":username: eddie\n:password: eddie"
        end
        it "should parse the yaml file to a Hash" do
          @str.should_receive(:read).and_return ":username: eddie\n:password: eddie"
          @test.read_config_file("filename").class.should == Hash
        end
        it "should parse the yaml file into the proper hash" do
          @test.read_config_file("filename").should == {:username => "eddie", :password => "eddie"}
        end
      end
    end
  end
end