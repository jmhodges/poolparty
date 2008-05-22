require File.dirname(__FILE__) + '/spec_helper'

class TestServer
  extend Server
end

describe "Server" do
  it "should be able to call server_loop as a proc" do
    TestServer.server_loop.class.should == Proc
  end
  it "should be able to call start_server! and call the server_loop" do
    TestServer.should_receive(:server_loop).and_return TestServer.server_loop
    TestServer.start_server!
  end
end