require File.dirname(__FILE__) + '/../spec_helper'
require "lib/poolparty/monitors/cpu"

describe "monitors" do
  describe "when included" do
    before(:each) do      
      @master = Master.new
      @instance = RemoteInstance.new
    end
    it "should include them in the Monitors module" do
      @master.methods.include?("cpu").should == true
    end
    it "should also include the new methods in the remote model" do
      RemoteInstance.new.methods.include?("cpu").should == true
    end
    describe "master" do
      before(:each) do
        @master.stub!(:list_of_nonterminated_instances).and_return(
        [{:instance_id => "i-abcdde1"}]
        )
      end
      it "should try to collect the cpu for the entire set of remote instances when calling cpu" do
        @master.nodes.should_receive(:inject).once.and_return 0.0
        @master.cpu
      end
    end
    describe "remote instance" do
      it "should try to ssh into the remote instance" do
        @instance.should_receive(:ssh).once.with("uptime")
        @instance.cpu
      end
      it "should be able to find the exact amount of time the processor has been up" do
        @instance.stub!(:ssh).once.with("uptime").and_return("18:55:31 up 5 min,  1 user,  load average: 0.32, 0.03, 0.00")
        @instance.cpu.should == 0.32
      end
    end
  end
end