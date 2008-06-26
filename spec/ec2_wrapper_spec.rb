require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + "/helpers/ec2_mock"

class EC2Test
  include Ec2Wrapper
  
  def get_non_empty_instances_description
    @resp ||= EC2::Response.parse(:xml => open("#{File.dirname(__FILE__)}/files/describe_response").read)
  end
end
describe "EC2 wrapper" do
  before(:each) do
    @test = EC2Test.new
    @test.stub!(:get_instances_description).and_return @test.get_non_empty_instances_description
  end
  it "should be able to describe an instance by id" do
    puts @test.describe_instance("i-60bc6a09")
  end
  it "should be able to list out the running instances" do
    @test.get_instances_description.should_not be_nil
  end
  it "should return an array of instances" do
    @test.get_instances_description.class.should == Array
  end
  it "should be able to iterate through the instances" do
    @test.get_instances_description.select {|a| a[:keypair] == "auser"}.should_not be_empty
  end
end