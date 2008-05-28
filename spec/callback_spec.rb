require File.dirname(__FILE__) + '/spec_helper'

class TestCallbacks
  include Callbacks
  def hello
    "hello "
  end
  def world
    "world"
  end
  def pop
    "pop"
  end
  def boom
    " goes boom"
  end
  before :world, :hello
  after :pop, :boom
end
describe "Callbacks" do
  before(:each) do
    @klass = TestCallbacks.new
  end
  it "should retain it's class identifier" do
    @klass.class.should == TestCallbacks
  end
  it "should callback the method before the method runs" do
    @klass.world.should == "hello world"
  end
  it "should callback the method before the method runs" do
    @klass.pop.should == "pop goes boom"
  end
end