require File.dirname(__FILE__) + '/../spec_helper'
require "open-uri"

describe "basic" do
  before(:each) do
    @example_dir = ::File.join(::File.dirname(__FILE__), "..", "..", "..", "examples")
    reset!
    PoolParty::Script.inflate File.read(@example_dir + "/basic.rb")
  end
  it "should have one pool called :app" do
    pool(:application).should_not be_nil
  end
  it "should have a cloud called :app" do
    pool(:application).cloud(:app).should_not be_nil
  end
  it "should have a cloud called :db" do
    pool(:application).cloud(:db).should_not be_nil
  end
  it "should set the minimum_instances on the cloud to 2 (overriding the pool options)" do
    pool(:application).cloud(:app).minimum_instances.should == 2
  end
  it "should set the maximum_instances on the cloud to 5" do
    pool(:application).cloud(:app).maximum_instances.should == 5
  end
  it "should set the minimum_instances on the db cloud to 3" do
    require 'rubygems'; require 'ruby-debug'; debugger
    puts "<pre>#{cloud(:db).to_properties_hash.to_yaml}</pre>"
    pool(:application).cloud(:db).minimum_instances.should == 3
  end
end