require File.dirname(__FILE__) + '/../spec_helper'

class ResourcerTestClass < PoolParty::Cloud::Cloud  
  default_options({
    :minimum_runtime => 50.minutes
  })
  
  # Stub keypair
  def keypair
    "rangerbob"
  end
end
class TestParentClass < PoolParty::Cloud::Cloud  
  def services
    @services ||= []
  end
  def add_service(s)
    services << s
  end
end
describe "CloudResourcer" do
  before(:each) do
    @tc = ResourcerTestClass.new :bank do
    end
  end
  it "should have the method instances" do
    @tc.respond_to?(:instances).should == true
  end
  it "should be able to accept a range and set the first to the minimum instances" do
    @tc.instances 4..10
    @tc.minimum_instances.should == 4
  end
  it "should be able to accept a Fixnum and set the minimum_instances and maximum_instances" do
    @tc.instances 1
    @tc.minimum_instances.should == 1
    @tc.maximum_instances.should == 1
  end
  it "should set the max to the maximum instances to the last in a given range" do
    @tc.instances 4..10
    @tc.maximum_instances.should == 10
  end
  it "should have default minimum_runtime of 50 minutes (3000 seconds)" do
    Base.stub!(:minimum_runtime).and_return 50.minutes
    @tc.minimum_runtime.should ==  50.minutes
  end
  it "should have minimum_runtime" do
    @tc.minimum_runtime 40.minutes
    @tc.minimum_runtime.should == 40.minutes
  end
  describe "keypair_path" do
    before(:each) do
    end
    it "should look for the file in the known directories it should reside in" do
      @tc.should_receive(:keypair_paths).once.and_return []
      @tc.keypair_path
    end
    it "should see if the file exists" do
      @t = "#{File.expand_path(Base.base_keypair_path)}"
      ::File.should_receive(:exists?).with(@t+"/id_rsa-rangerbob").and_return false
      ::File.stub!(:exists?).with(@t+"/rangerbob").and_return false
      @tc.should_receive(:keypair_paths).once.and_return [@t]
      @tc.keypair_path
    end
    it "should fallback to the second one if the first doesn't exist" do
      @t = "#{File.expand_path(Base.base_keypair_path)}"
      @q = "#{File.expand_path(Base.base_config_directory)}"
      ::File.stub!(:exists?).with(@t+"/id_rsa-rangerbob").and_return false
      ::File.stub!(:exists?).with(@t+"/rangerbob").and_return false
      ::File.stub!(:exists?).with(@q+"/id_rsa-rangerbob").and_return false
      ::File.should_receive(:exists?).with(@q+"/rangerbob").and_return true
      @tc.should_receive(:keypair_paths).once.and_return [@t, @q]
      @tc.keypair_path.should == "/etc/poolparty/rangerbob"
    end
    describe "exists" do
      before(:each) do
        @t = "#{File.expand_path(Base.base_keypair_path)}"
        ::File.stub!(:exists?).with(@t+"/id_rsa-rangerbob").and_return false
        ::File.stub!(:exists?).with(@t+"/rangerbob").and_return true
      end
      it "should have the keypair_path" do
        @tc.respond_to?(:keypair_path).should == true
      end
      it "should set the keypair to the Base.keypair_path" do      
        @tc.keypair_path.should =~ /\.ec2\/rangerbob/
      end
      it "should set the keypair to have the keypair set" do
        @tc.keypair.should =~ /rangerbob/
      end
      it "should set it to the Base keypair_path and the keypair" do
        @tc.keypair_path.should == "#{File.expand_path(Base.base_keypair_path)}/#{@tc.keypair}"
      end
    end
  end
  describe "parents" do
    before(:each) do
      @testparent = TestParentClass.new :parent_of_bob do
        test_option "blankity blank blank"
        
        ResourcerTestClass.new :bob do
        end
      end      
    end
    describe "setting" do
      it "set 1 service on the parent class" do
        @testparent.services.size.should == 1
      end
      it "set the service as a ResourcerTestClass named bob" do
        @testparent.services.first.name.should == :bob
      end
      it "set the parent's options on the child" do
        @testparent.services.first.test_option.should == "blankity blank blank"
      end
    end
  end
end