require File.dirname(__FILE__) + '/../spec_helper'

class MMObject
  include PoolParty::Configurable
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
  it "should be able to set with an = sign" do
    @obj.dojo = "in the houwse"
    @obj.dojo.should == "in the houwse"
  end
  it "should be able to overwrite the currently set value" do
    @obj.hello "bob"
    @obj.hello "marcus"
    @obj.hello.should == "marcus"
  end
  it "should raise error as bank is not defined" do
    lambda {@obj.bank}.should raise_error
  end
end