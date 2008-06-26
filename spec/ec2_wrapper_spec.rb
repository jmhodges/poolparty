require File.dirname(__FILE__) + '/spec_helper'

class EC2Test
  include Ec2Wrapper
end
describe "EC2 wrapper" do
  before(:each) do
    @test = EC2Test.new
  end
  it "should be able to list out the running instances" do
    @test.get_instances_description.should_not be_nil
  end
  it "should return an array of instances" do
    @test.get_instances_description.class.should == Array
  end
  it "should be able to iterate through the instances" do
    @test.get_instances_description.select {|a| a[:keypair] == "auser"}
  end
end