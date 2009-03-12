require File.dirname(__FILE__) + '/../spec_helper'

class MMObject
  include PoolParty::Configurable
  def parent
    nil
  end
end

describe "MethodMissingSugar" do
  before(:each) do
    @obj = MMObject.new
    @obj.hello "world"
  end
  it "should set a value on the instance when called with an arg" do    
    @obj.hello.should == "world"
  end
  it "should override the value set on the instance if called with an arg again" do
    @obj.hello "party"
    @obj.hello.should == "party"
  end
  it "should return nil if the value has not been set yet" do
    @obj.bank.should == nil
  end
  describe "with parent" do
    before(:each) do
      @@parent = MMObject.new
      class MMObject2 < MMObject
        def parent
          @@parent
        end
      end
      @obj = MMObject2.new
    end
    it "should send the query up the parent" do
      @@parent.should_receive(:bank).and_return "of PoolParty"
      @obj.bank.should == "of PoolParty"
    end
    it "shoudl query the parent and return nil if the parent' doesn't have it defined" do
      @@parent.should_receive(:bank).and_return nil
      @obj.bank.should == nil
    end
  end
end