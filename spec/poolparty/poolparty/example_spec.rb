require File.dirname(__FILE__) + '/../spec_helper'
require "open-uri"

describe "basic" do
  before(:each) do
    @example_spec_file = ::File.join(::File.dirname(__FILE__), "..", "..", "..", "examples", 'basic.rb')
    PoolParty::Pool::Pool.load_from_file(@example_spec_file)
  end
  it "should have one pool called :app" do
    pool(:application).should_not == nil
    pools[:application].should_not == nil
  end
  it "should have a cloud called :app" do
    clouds[:app].should_not == nil
  end
  it "should have a cloud called :db" do
    pools[:application].clouds[:db].should_not == nil
  end
  it "should set the minimum_instances on the cloud to 2 (overriding the pool options)" do    
    pools[:application].minimum_instances.should == 3
    clouds[:app].minimum_instances.should == 12
  end
  it "should set the maximum_instances on the cloud to 50" do
    clouds[:app].maximum_instances.should == 50
  end
  it "should set the minimum_instances on the db cloud to 3" do
    clouds[:db].minimum_instances.should == 19
    clouds[:app].minimum_instances.should == 12
    pools[:application].minimum_instances.should ==3
  end
  it "should set ambiguous methods on the cloud" do
    clouds[:app].junk_yard_dogs.should == "pains"
    clouds[:db].junk_yard_dogs.should == "are bad"
  end
  it "should set the parent to the pool" do
    clouds[:app].parent.should == pools[:application]
    clouds[:db].parent.should == pools[:application]
    clouds[:db].parent.should_not == pools[:app]
  end
  it "should have the keypair matching /auser/on the db cloud " do
    clouds[:db]._keypairs.select{|a| a.filepath.match(/auser/)}
  end
  it "should have the keypair set for the specific cloud on top of the keypair stack" do
    pending
    #I think this should be the behavior. mf
    # pools[:application].clouds[:db].keypairs.last.filepath.should_match(/auser/)
  end
end