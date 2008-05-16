require File.dirname(__FILE__) + '/spec_helper'

class TestCallbacks
  include Callbacks    
  def hello
    "hi"
  end
  def world
    "world"
  end    
  before :world, :hello
end
describe "Callbacks" do
  before(:each) do
    @klass = TestCallbacks.new
  end
  it "should retain it's class identifier" do
    @klass.class.should == TestCallbacks
  end
  it "should callback the method before the method runs"
end