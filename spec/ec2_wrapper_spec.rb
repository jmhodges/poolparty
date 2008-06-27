require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + "/helpers/ec2_mock"

class EC2Test
  include Ec2Wrapper
  
  def get_non_empty_instance_description
    @resp ||= EC2::Response.parse(:xml => read_file("describe_response"))
  end
  def get_non_empty_instances_description
    @resp2 ||= EC2::Response.parse(:xml => read_file("multi_describe_response"))
  end
  def get_remote_inst_desc
    @resp3 = EC2::Response.parse(:xml => read_file("remote_desc_response"))
  end
  def read_file(name)
    open("#{File.dirname(__FILE__)}/files/#{name}").read
  end
end
describe "EC2ResponseObject" do
  before(:each) do
    @test = EC2Test.new
    @r = @test.get_non_empty_instance_description
    @rs = @test.get_non_empty_instances_description
    @rst = @test.get_remote_inst_desc
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
  describe "multiple responses" do
    it "should be able to get the response object from the query" do
      EC2ResponseObject.get_response_from(@rst).should_not be_nil
    end
    it "should return an EC2:Response from EC2ResponseObject.get_response_from" do
      EC2ResponseObject.get_response_from(@rst).class.should == EC2::Response
    end
    it "should be able to grab the keypair name from the response object" do
      EC2ResponseObject.get_response_from(@rst).instancesSet.item.instanceId.should == "i-94f82efd"
    end
    it "should be able to list out the running instances" do
      EC2ResponseObject.get_descriptions(@rst)
    end
    it "should return an array of instances" do
      EC2ResponseObject.get_descriptions(@rst).class.should == Array
    end
    it "should be able to iterate through the instances" do
      EC2ResponseObject.get_descriptions(@rst).select {|a| a[:keypair] == "auser"}.should_not be_empty
    end
  end
end