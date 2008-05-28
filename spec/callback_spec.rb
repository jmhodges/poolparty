require File.dirname(__FILE__) + '/spec_helper'

class TestCallbacks
  include Callbacks
  attr_reader :str
  def hello
    string << "hello "
  end
  def world
    string << "world"
  end
  def thanks
    string << ", thank you"
  end
  before :world, :hello
  after :world, :thanks
  def pop
    string << "pop"
  end
  def boom
    string << " goes boom"
  end  
  after :pop, :boom
  def string
    @str ||= String.new
  end
end
describe "Callbacks" do
  before(:each) do
    @klass = TestCallbacks.new
  end
  it "should retain it's class identifier" do
    @klass.class.should == TestCallbacks
  end
  it "should callback the method before the method runs" do
    @klass.world.should == "hello world, thank you"
  end
  it "should callback the method before the method runs" do
    @klass.pop.should == "pop goes boom"
  end
end