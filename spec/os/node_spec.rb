require File.dirname(__FILE__) + '/../spec_helper'

describe "Os node" do
  before(:each) do
    @node = Os::Node.new({:ip => "ip-127-0-0-1-aws.amazonaws.com", :name => "node1"})
  end
  it "should assign at minimum the 127.0.0.1 to the hosts file" do
    @node.host_entry.should == "node1\tip-127-0-0-1-aws.amazonaws.com"
  end
end