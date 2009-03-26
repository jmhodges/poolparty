require "rubygems"
require "spec"
require File.dirname(__FILE__) + '/../../lib/poolparty/schema'

include PoolParty

describe "Schema" do
  it "should not fail when called with a hash" do
    lambda {Schema.new({:a => "a"})}.should_not raise_error
  end
  describe "methods" do
    before(:each) do
      @schema = Schema.new :a => "b", :b => {:a => "a in b", :b => {:a => "a in b.b"}}
    end
    it "should be able to call a method that's in the hash on the schema" do
      @schema.a.should == "b"
    end
    it "should be able to call deeply into the hash" do
      @schema.b.a.should == "a in b"
    end
    it "should be able to call really deep into the hash" do
      @schema.b.b.a.should == "a in b.b"
    end
  end
end