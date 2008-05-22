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
      @master.stub!(:master).and_return(RemoteInstance.new({:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"}))
      @master.stub!(:slaves).and_return(
        [{:instance_id => "i-5849bb", :ip => "ip-127-0-0-2.aws.amazon.com", :status => "running"}].collect do |slave|
          RemoteInstance.new(slave)
        end
      )
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