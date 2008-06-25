require File.dirname(__FILE__) + '/../spec_helper'
require "lib/poolparty/monitors/web"

describe "monitors" do
  describe "when included" do
    before(:each) do      
      stub_option_load
      Application.stub!(:client_port).and_return 8001
      @master = Master.new
      @instance = RemoteInstance.new
    end
    it "should include them in the Monitors module" do
      @master.methods.include?("web").should == true
    end
    it "should also include the new methods in the remote model" do
      @instance.methods.include?("web").should == true
    end
    describe "master" do
      before(:each) do
        @master.stub!(:list_of_nonterminated_instances).and_return(
        [{:instance_id => "i-abcdde1"}]
        )
      end
      it "should try to collect the cpu for the entire set of remote instances when calling cpu" do
        @master.nodes.should_receive(:inject).once.and_return 0.0
        @master.web
      end
    end
    describe "remote instance" do
      it "should try to ssh into the remote instance" do
        @instance.should_receive(:ssh).once.with("httperf --server localhost --port #{Application.client_port} --num-conn 3 --timeout 5 | grep 'Request rate'")
        @instance.web
      end
      it "should be able to find the exact amount of time the processor has been up" do
        @instance.stub!(:ssh).once.and_return("Request rate: 1.5 req/s (649.9 ms/req)")
        @instance.web.round_to(2).should == 1.5
      end
    end
  end
end