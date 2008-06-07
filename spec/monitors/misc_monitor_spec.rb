require File.dirname(__FILE__) + '/../spec_helper'

module Database
  module Master
    def db
      nodes.inject(0) {|i,inst| i * inst.db} / nodes.size
    end
  end
  module Remote
    def db
      5.0
    end
  end
end

PoolParty.register_monitor Database

describe "monitors (random, to spec the inclusion)" do
  describe "when included" do
    before(:each) do      
      @master = Master.new
      @instance = RemoteInstance.new
    end
    it "should include them in the Monitors module" do
      @master.methods.include?("db").should == true
    end
    it "should also include the new methods in the remote model" do
      @instance.methods.include?("db").should == true
    end
    describe "master" do
      before(:each) do
        @master.stub!(:list_of_nonterminated_instances).and_return(
        [{:instance_id => "i-abcdde1"}]
        )
      end
      it "should try to collect the cpu for the entire set of remote instances when calling cpu" do
        @master.nodes.should_receive(:inject).once.and_return 5.0
        @master.db.should == 5.0
      end
    end
    describe "remote instance" do
      it "should try to ssh into the remote instance" do
        @instance.db.should == 5.0
      end
      it "should be able to find the exact amount of time the processor has been up" do
        @instance.db.round_to(2).should == 5.0
      end
    end
  end
end