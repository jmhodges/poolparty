require File.dirname(__FILE__) + '/spec_helper'

describe "Master" do
  before(:each) do
    @master = Master.new
  end  
  it "should launch the first instances and set the first as the master and the rest as slaves" do
    Application.stub!(:minimum_instances).and_return(2)
    @master.stub!(:launch_new_instance!).and_return(
    {:instance_id => "i-5849ba", :ip => "ip-127-0-0-1.aws.amazon.com", :status => "running"},
    {:instance_id => "i-5849bb", :ip => "ip-127-0-0-2.aws.amazon.com", :status => "running"})
    @master.start_cloud!
    @master.master.instance_id.should == "i-5849ba"
    @master.slaves.first.instance_id.should == "i-5849bb"
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
    it "should be able to list the instances" do
      @master.should_receive(:message).once.and_return("")
      @master.list_cloud
    end
  end
end