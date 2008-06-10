require File.dirname(__FILE__) + '/../spec_helper'
require "lib/poolparty/monitors/memory"

describe "monitors" do
  describe "when included" do
    before(:each) do      
      @master = Master.new
      @instance = RemoteInstance.new
    end
    it "should include them in the Monitors module" do
      @master.methods.include?("memory").should == true
    end
    it "should also include the new methods in the remote model" do
      @instance.methods.include?("memory").should == true
    end
    describe "master" do
      before(:each) do
        @master.stub!(:list_of_nonterminated_instances).and_return(
        [{:instance_id => "i-abcdde1"}]
        )
      end
      it "should try to collect the cpu for the entire set of remote instances when calling cpu" do
        @master.nodes.should_receive(:inject).once.and_return 0.0
        @master.memory
      end
    end
    describe "remote instance" do
      it "should try to ssh into the remote instance" do
        @instance.should_receive(:ssh).once.with("free -m | grep -i mem")
        @instance.memory
      end
      it "should be able to find the exact amount of time the processor has been up" do
        @instance.stub!(:ssh).once.with("free -m | grep -i mem").and_return("Mem:          1700         546       1644          0          2         18")
        @instance.memory.round_to(2).should == 0.32
      end
    end
    # it "should web monitor should be able to extract the amount of the requests it can handle" do
    #   str = "Request rate: 1.5 req/s (649.9 ms/req)"
    #   # Monitors::Web.monitor_from_string(str).should == 1.5
    # end
    # it "should be able to monitor the percentage of memory available on the server" do
    #   str = "Mem:          1700         56       1644          0          2         18"
    #   # Monitors::Memory.monitor_from_string(str).to_s.should =~ /0.032/
    # end
    # it "should be able to show the load on the cpu available on the server" do
    #   str = "18:55:31 up 5 min,  1 user,  load average: 0.32, 0.03, 0.00"
    #   # Monitors::Cpu.monitor_from_string(str).should == 0.32
    # end
  end
end