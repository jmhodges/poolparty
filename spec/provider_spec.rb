require File.dirname(__FILE__) + '/spec_helper'

describe "Provider" do
  before(:each) do
    stub_option_load
    Sprinkle::Script.stub!(:sprinkle).and_return true
    @ips = ["127.0.0.1"]
    Master.stub!(:cloud_ips).and_return @ips
  end
  it "should load the packages in the package directory" do
    Dir.should_receive(:[]).and_return []
    Provider.new.load_packages
  end
  it "should load the packages defined in the user directory" 
  describe "running" do
    describe "server packages" do
      before(:each) do
        @provider = Provider.new
        @str = "new"
        @str.stub!(:process).and_return true
        @provider.stub!(:set_start_with_sprinkle).and_return @str
        Provider.stub!(:new).and_return @provider
        Master.stub!(:cloud_ips).and_return ["127.0.0.1"]
      end
      it "should use the loaded packages to install" do
        @provider.should_receive(:load_packages).and_return []
        @provider.install_poolparty
      end
      it "should load the install script when installing" do
        @provider.should_receive(:set_start_with_sprinkle).and_return true
        @provider.install_poolparty
      end
    end
    describe "user packages" do
      describe "defining" do
        before(:each) do
          Provider.define_custom_package(:sprinkle) do
            package :sprinkle, :provides => :package do
              description 'Sprinkle'
              apt %w( sprinkle )
            end
          end
        end
        it "should be able to define user packages with blocks and pass those into the user_packages" do
          Provider.user_packages.size.should == 1
        end
        it "should define the user packages as strings" do
          Provider.user_packages.first.class.should == Proc
        end
      end
      describe "defining custom packages" do
        before(:each) do
          Provider.reset!
          Provider.define_custom_package(:custom) do
            <<-EOE
              package :custom do
                description 'custom packages'
              end
            EOE
          end
        end
        it "should be able to define a custom package with a name" do
          Provider.user_packages.size.should > 1
        end
        it "should have the name of the custom package built in" do
          Provider.user_install_packages.sort {|a,b| a.to_s <=> b.to_s }.should == [:custom, :sprinkle]
        end
      end
    end
  end
end