require File.dirname(__FILE__) + '/../spec_helper'

extend Os
include Os

describe "Bootstrap" do
  before(:each) do    
    @ri = RemoteInstance.new({:ip => "127.0.0.1"})
    @bootstrap = Os::Bootstrap.new(@ri)
    @bootstrap.stub!(:system).and_return true
    @bootstrap.respond_to?(:exec_remote).should == true
    @bootstrap.setup
  end
  it "should be able to exec_remote" do    
  end
  describe "haproxy" do
    it "should be able to create the basic haproxy install command" do      
      @bootstrap.install_haproxy[1].should =~ /wget http:\/\/haproxy\.1wt\.eu/
    end
    it "should call exec_remote to exec it on the RemoteInstance" do
      @bootstrap.should_receive(:exec_remote).once.and_return true
      @bootstrap.install_haproxy
    end
    it "should be able to configure haproxy" do
      p @bootstrap.configure_haproxy[1]
      @bootstrap.configure_haproxy[1].should =~ /listen web_proxy 127\.0\.0\.1/
    end
  end
end