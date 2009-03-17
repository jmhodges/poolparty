require File.dirname(__FILE__) + '/../spec_helper'
require "open-uri"

describe "basic" do
  before(:each) do
    @example_dir = ::File.join(::File.dirname(__FILE__), "..", "..", "..", "examples")
    PoolParty::Script.inflate File.read(@example_dir + "/basic.rb")
  end
  it "should have one pool called :app" do
    pool(:application).should_not be_nil
  end
  it "should have a cloud called :app" do
    clouds[:app].should_not be_nil
  end
  it "should have a cloud called :db" do
    pools[:application].clouds[:db].should_not be_nil
  end
  it "should set the minimum_instances on the cloud to 2 (overriding the pool options)" do    
    # puts "app = #{clouds[:app].minimum_instances} = #{pools[:application].options - clouds[:app].options}"
    # puts "inner = #{clouds[:inner].minimum_instances}"
    # puts "app parent = #{clouds[:app].parent.minimum_instances}"
    # puts "db = #{clouds[:db].minimum_instances} = #{clouds[:db].options.minimum_instances}"
    # puts clouds[:db].junk_yard_dogs
    puts clouds[:app].junk_yard_dogs
    puts clouds[:db].junk_yard_dogs
    clouds[:app].minimum_instances.should == 1
  end
  it "should set the maximum_instances on the cloud to 50" do
    clouds[:app].maximum_instances.should == 50
  end
  it "should set the minimum_instances on the db cloud to 3" do
    clouds[:db].minimum_instances.should == 3
    clouds[:app].minimum_instances.should == 12
    clouds[:inner].minimum_instances.should == 14
    pools[:application].minimum_instances.should ==3
  end
  it "should set the parent to the pool" do
    clouds[:app].parent.should == pools[:application]
    clouds[:db].parent.should == pools[:application]
    clouds[:db].parent.should_not == pools[:app]
  end
  it "should have the keypair matching /auser/on the db cloud " do
    puts clouds[:db].maximum_instances
    clouds[:db]._keypairs.select{|a| a.filepath.match(/auser/)}
  end
  it "should have the keypair set for the specific cloud on top of the keypair stack" do
    pending
    #I think this should be the behavior. mf
    # pools[:application].clouds[:db].keypairs.last.filepath.should_match(/auser/)
  end
  
end