require File.dirname(__FILE__) + '/spec_helper'

class TestRemote
  include Remoter
  include Callbacks
  attr_accessor :ip
end
describe "Remter" do
  before(:each) do
    @remoter = TestRemote.new    
    @remoter.stub!(:put).and_return "true"
    @tempfile = Tempfile.new("/tmp") do |f|
      f << "hi"
    end
    Application.stub!(:keypair_path).and_return "app"
    Application.stub!(:username).and_return "root"
  end
  it "should not create a block if a block is given" do
    Proc.should_not_receive(:new)
    @remoter.scp("filename", "/etc/ha.d") do
      puts "hi"
    end    
  end
  it "should create a block when a block is not given" do
    Proc.should_receive(:new).once
    @remoter.scp("filename", "/etc/")
  end
  it "should open the file given if a block is not given" do
    Proc.should_receive(:new)#.with(open(@tempfile).read).and_return "hi"
    @remoter.scp(@tempfile.path, "/etc")
  end
  it "should run sudo mkdir -p if the :dir => '' is included in the options" do
    @remoter.should_receive(:sudo)
    @remoter.scp(@tempfile.path, "/etc", :dir => "hi")
  end
  it "should run ssh on the system if there is no command given" do
    @remoter.should_receive(:system).with("ssh -i app root@127.0.0.1")
    @remoter.ip = "127.0.0.1"
    @remoter.ssh
  end
  it "should run run on the remote system if there is a command given" do
    @remoter.should_not_receive(:system)
    @remoter.should_receive(:run).with("echo 'hi'").once
    @remoter.ssh("echo 'hi'")
  end
end