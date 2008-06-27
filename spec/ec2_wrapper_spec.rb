require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + "/helpers/ec2_mock"

class EC2Test
  include Ec2Wrapper
  
  def get_non_empty_instance_description
    @resp ||= EC2::Response.parse(:xml => open("#{File.dirname(__FILE__)}/files/describe_response").read)
  end
  def get_non_empty_instances_description
    @resp2 ||= EC2::Response.parse(:xml => open("#{File.dirname(__FILE__)}/files/multi_describe_response").read)
  end
end
describe "EC2ResponseObject" do
  before(:each) do
    @test = EC2Test.new
    @r = @test.get_non_empty_instance_description
    @rs = @test.get_non_empty_instances_description
  end
  describe "single instance" do
    it "should be able to get the response object from the query" do
      EC2ResponseObject.get_response_from(@r).should_not be_nil
    end
    it "should return an EC2:Response from EC2ResponseObject.get_response_from" do
      EC2ResponseObject.get_response_from(@r).class.should == EC2::Response
    end
    it "should be able to grab the keypair name from the response object" do
      EC2ResponseObject.get_response_from(@r).instancesSet.item.instanceId.should == "i-60bc6a09"
    end
    it "should be able to list out the running instances" do
      EC2ResponseObject.get_descriptions(@r)
    end
    it "should return an array of instances" do
      EC2ResponseObject.get_descriptions(@r).class.should == Array
    end
    it "should be able to iterate through the instances" do
      EC2ResponseObject.get_descriptions(@r).select {|a| a[:keypair] == "auser"}.should_not be_empty
    end
  end
  describe "multiple responses" do
    it "should be able to get the response object from the query" do
      EC2ResponseObject.get_response_from(@r).should_not be_nil
    end
    it "should return an EC2:Response from EC2ResponseObject.get_response_from" do
      EC2ResponseObject.get_response_from(@r).class.should == EC2::Response
    end
    it "should be able to grab the keypair name from the response object" do
      EC2ResponseObject.get_response_from(@r).instancesSet.item.instanceId.should == "i-60bc6a09"
    end
    it "should be able to list out the running instances" do
      EC2ResponseObject.get_descriptions(@r)
    end
    it "should return an array of instances" do
      EC2ResponseObject.get_descriptions(@r).class.should == Array
    end
    it "should be able to iterate through the instances" do
      EC2ResponseObject.get_descriptions(@r).select {|a| a[:keypair] == "auser"}.should_not be_empty
    end
  end
end