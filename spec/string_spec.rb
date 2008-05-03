require File.dirname(__FILE__) + '/helper'

context "hasherize" do
  specify "should be able to hasherize a string" do
    str = "\n\n \n \n r-fc23dc95\n 768739572088\n \n \n default\n \n \n \n \n i-e2b5738b\n ami-226e8b4b\n \n 16\n running\n \n ip-10-251-35-177.ec2.internal\n ec2-67-202-51-121.compute-1.amazonaws.com\n \n causecast-ec2\n 0\n \n m1.small\n 2008-04-10T18:14:10.000Z\n \n us-east-1b\n \n \n \n \n \n r-3033cd59\n 768739572088\n \n \n default\n \n \n \n \n i-dbee2fb2\n ami-807396e9\n \n 16\n running\n \n ip-10-251-111-38.ec2.internal\n ec2-75-101-143-0.compute-1.amazonaws.com\n \n 0\n \n m1.small\n 2008-04-16T21:06:08.000Z\n \n us-east-1b\n \n \n \n \n \n"
    str.hasherize([:reservation_id, :id, :group, :instance_id, :ami, :mins, :status,:internal_ip,:external_ip,:name]).should == {
      :reservation_id => "r-fc23dc95", :id => "768739572088", :group => "default",
      :instance_id => "i-e2b5738b", :ami => "ami-226e8b4b", :mins=>"16",
      :name=>"causecast-ec2", :status=>"running",
      :internal_ip=>"ip-10-251-35-177.ec2.internal",
      :external_ip=>"ec2-67-202-51-121.compute-1.amazonaws.com",
      :id=>"768739572088", :instance_id=>"i-e2b5738b"
    }
  end
end