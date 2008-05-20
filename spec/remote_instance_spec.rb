require File.dirname(__FILE__) + '/spec_helper'

describe "remote instance" do
  before(:each) do
    @instance = RemoteInstance.new({:ip => "127.0.0.1"})
  end
  
  describe "in general" do
    it "should set the ip upon creation" do
      @instance.ip.should == "127.0.0.1"
    end

  end
end