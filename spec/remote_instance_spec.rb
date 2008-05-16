require File.dirname(__FILE__) + '/spec_helper'

describe "remote instance" do
  before(:each) do
    @instance = RemoteInstance.new({:ip => "127.0.0.1"})
    stat = { 'cpu' => "0.1", 'memory' => "0.1", 'web' => "110.0" }
    @instance.stub!(:status).and_return(stat)
  end
  
  describe "in general" do
    it "should set the ip upon creation" do
      @instance.ip.should == "127.0.0.1"
    end
    it "should be able to tell it's cpu status" do
      @instance.cpu.should == 0.1
    end
    it "should be able to tell it's web status" do
      @instance.web.should == 110.0
    end
    it "should be able to tell it's memory status" do
      @instance.memory.should == 0.1
    end
  end  
  
  describe "when handling proxy requests" do
    before(:each) do
      # @mock_http = mock("http", :code => 200, :body => "hi", :get => "response")      
      @env = Rack::MockRequest.env_for("http://127.0.0.1:7788/")
      res = mock(:code => '200', :body => 'success')
      res.stub!(:code).and_return(200)
      res.stub!(:to_hash).and_return({:code => 200})
      res.stub!(:body).and_return("success")
      @instance.stub!(:get_http_response).and_return( res )
    end
    it "should respond to process call with an array" do
      @instance.process(@env).class.should == Array
    end
    it "should respond to process call with an array of size 3" do
      @instance.process(@env).size.should == 3
    end
  end
end

describe "in groups" do
  before(:each) do
    @instances = []
    @stats = []
    3.times {|i|
      i += 1
      inst = RemoteInstance.new({:ip => "127.0.0.#{i}"})
      stat = { 'cpu' => "0.#{i}", 'memory' => "0.#{i}", 'web' => "1#{i}0.0" }
      inst.stub!(:status).and_return(stat)
      @instances << inst
      @stats << stat
    }
  end
  it "should check the status of the instance when sorting the instances" do
    @instances[0].should_receive(:status).at_least(1).times.and_return(@stats[0])
    @instances.sort
  end
  it "should create a status based off the previous one" do
    (@instances[0].status_level < @instances[1].status_level).should == true
  end
end