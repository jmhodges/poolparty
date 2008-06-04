require File.dirname(__FILE__) + '/spec_helper'

class TestCallbacks
  include Callbacks
  attr_reader :str
  
  before :world, :hello
  after :world, :thanks
  
  def hello
    string << "hello "
  end
  def world
    string << "world"
  end
  def thanks
    string << ", thank you"
  end
  after :pop, :boom
  def pop
    string << "pop"
  end
  def boom
    string << " goes boom"
  end    
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
class TestMultipleCallbacks
  include Callbacks
  attr_reader :str
  def hi
    string << "hi, "
  end
  def hello
    string << "hello "
  end
  def world
    string << "world"
  end
  def string
    @str ||= String.new
  end
  before :world, :hi, :hello
end
describe "Multiple callbacks" do
  before(:each) do
    @klass = TestMultipleCallbacks.new
  end
  it "should be able to have multiple callbacks on the same call" do
    @klass.world.should == "hi, hello world"
  end
end
class OutsideClass
  def hello
    puts "hello"
  end
end
class TestOutsideClass
  include Callbacks
  before :world, {:hello => OutsideClass}
  def world
    "world"
  end
end
describe "Options" do
  before(:each) do
    @c = TestOutsideClass.new
  end
  it "should be able to pass external class options to the callback" do
    OutsideClass.should_receive(:hello).and_return "hello"
    @c.world
  end
end
class BlockClass
  include Callbacks
  before :world do
    string << "hello "
  end
  def world
    string << "world"
  end
  def string
    @string ||= ""
  end
end
describe "Block callbacks" do
  it "should call the block on the callback" do
    BlockClass.new.world.should == "hello world"
  end
end
class BlockAndMethodClass
  include Callbacks
  before :world, :hi do
    string << "hello "
  end
  def world
    string << "world"
  end
  def hi
    string << "hi, "
  end
  def string
    @string ||= ""
  end
end
describe "Block and method callbacks" do
  it "should call the block on the callback and add the block" do
    BlockAndMethodClass.new.world.should == "hi, hello world"
  end
end
class ExternalMethodCallClass
  include Callbacks
  before :world, :hello
  after :hello, :peter
  def world
    string << "world"
  end
  def hello
    string << "hello "
  end
  def peter
    string << "peter "
  end
  def peter
    string << "peter "
  end
  def string
    @string ||= ""
  end
end
describe "External method callbacks inside a method" do
  it "should call the block on the callback and add the " do
    ExternalMethodCallClass.new.world.should == "hello peter world"
  end
end
class OutsideBindingClass
  def hello
    string << "hello"
  end
end
class BindingClass
  include Callbacks
  before :world, :hello
  def world
    string << "#{@hello} world"
  end
  def hello
    @hello = "hello"
  end
  def string
    @string ||= ""
  end
end
describe "Methods" do
  it "should have access to the local variables of the call" do
    BindingClass.new.world.should == "hello world"
  end
end