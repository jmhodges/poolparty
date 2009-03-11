require File.dirname(__FILE__) + '/../spec_helper'
require "open-uri"

describe "basic" do
  before(:each) do
    @example_dir = ::File.join(::File.dirname(__FILE__), "..", "..", "..", "examples")
    reset!
    PoolParty::Script.inflate File.read(@example_dir + "/basic.rb")
  end
  it "should have one pool called :app" do

    pools[:application].should_not be_nil
  end
  it "should have a cloud called :app" do
    pools[:application].cloud(:app).should_not be_nil
  end
  it "should have a cloud called :db" do
    pools[:application].cloud(:db).should_not be_nil
  end
  it "should set the minimum_instances on the cloud to 2 (overriding the pool options)" do
    pools[:application].cloud(:app).minimum_instances.should == 2
  end
  it "should set the maximum_instances on the cloud to 5" do
    pools[:application].cloud(:app).maximum_instances.should == 5
  end
  it "should set the minimum_instances on the db cloud to 3" do
    pools[:application].clouds[:db].minimum_instances.should == 3
  end
  it "should have the keypair matching /auser/on the db cloud " do
    pools[:application].clouds[:db].keypairs.select{|a| a.filepath.match (/auser/)}
  end
  it "should have the keypair set for the specific cloud on top of the keypair stack" do
    pending
    #I think this should be the behavior. mf
    # pools[:application].clouds[:db].keypairs.last.filepath.should_match(/auser/)
  end
  
end