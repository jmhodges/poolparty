require File.dirname(__FILE__) + '/spec_helper'

class TestRemote
  include Remoter
  include Callbacks
  attr_accessor :ip
end
describe "Remoter" do
  before(:each) do
    @remoter = TestRemote.new    
    @remoter.stub!(:put).and_return "true"
    @tempfile = Tempfile.new("/tmp") do |f|
      f << "hi"
    end
    Application.stub!(:keypair_path).and_return "app"
    Application.stub!(:username).and_return "root"
  end
  it "should have a rt method" do
    @remoter.respond_to?(:rt).should == true
  end
  describe "executing" do
    it "should call set_hosts before it executes the tasks" do
      @remoter.should_receive(:set_hosts).once
      @remoter.execute_tasks {}
    end
    it "should not call set_hosts before it executes the task if it explicitly doesn't want it to" do
      @remoter.should_not_receive(:set_hosts)
      @remoter.execute_tasks(:dont_set_hosts => true) {}
    end
  end
end