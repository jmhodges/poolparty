require File.dirname(__FILE__) + '/../spec_helper'

describe "Os node" do
  before(:each) do
    @node = Os::Node.new
  end
  it "should assign at minimum the 127.0.0.1 to the hosts file" do
    @node.host_entries.should =~ /127\.0\.0\.1/
  end
end