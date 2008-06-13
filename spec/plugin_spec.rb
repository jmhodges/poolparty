require File.dirname(__FILE__) + '/spec_helper'

class TestPlugin < PoolParty::Plugin
  after_define_tasks :takss
  after_install :echo_hosts, :email_updates
  before_configure :echo_hosts  
  after_start :echo_start
  
  def echo_start(master)
    "start"
  end
  def echo_hosts(caller)
    "hosts"
  end
  def email_updates(caller)
    "email"
  end
  def takss(tasks)
    "tasks"
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
      @instance = RemoteInstance.new
      @master = Master.new
      
      @test = TestPlugin.new
      @test.stub!(:echo_hosts).and_return("true")
      @test.stub!(:email_updates).and_return("true")
      @test.stub!(:echo_start).and_return("true")
      TestPlugin.stub!(:new).and_return(@test)
      Kernel.stub!(:wait).and_return true
      
      @master.stub!(:launch_minimum_instances).and_return true
      @master.stub!(:number_of_pending_instances).and_return 0
      @master.stub!(:get_node).with(0).and_return @instance
      
      @instance.stub!(:ssh).and_return "true"
      @instance.stub!(:scp).and_return "true"
      Kernel.stub!(:system).and_return "true"
    end
    it "should should call echo_hosts after calling configure" do      
      @test.should_receive(:echo_hosts).at_least(1)
      @instance.install
    end
    it "should call email_updates after calling install" do
      @test.should_receive(:email_updates).at_least(1)
      @instance.install
    end
    it "should call echo_hosts before it calls configure" do
      @test.should_receive(:echo_hosts).at_least(1).and_return "hi"
      @instance.configure
    end
    it "should not call echo_hosts after if configures" do
      @test.should_not_receive(:email_updates)
      @instance.configure
    end
    it "should say that it started on the master" do
      @test.should_receive(:echo_start).at_least(1).and_return "hi"
      @master.start
    end
  end
end