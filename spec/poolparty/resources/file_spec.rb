require File.dirname(__FILE__) + '/../spec_helper'

describe "File" do
  describe "instances" do
    before(:each) do
      @tc = TestBaseClass.new do
        file({:name => "/etc/apache2/puppetmaster.conf", :owner => "herman"}) do
          mode 755
        end
      end
      @file = @tc.resource(:file).first
    end
    it "have the name in the options" do
      @file.name.should == "/etc/apache2/puppetmaster.conf"
    end
    it "should store the owner's name as well" do
      @file.owner.should == "herman"
    end
    it "should store the mode (from within the block)" do
      @file.mode.should == 755
    end
    describe "into PuppetResolver" do
      before(:each) do
        @compiled = PuppetResolver.new(@tc.to_properties_hash).compile
      end
      it "should set the filename to the name of the file" do
        @compiled.should match(/file \{ "\/etc\/apache2\/puppetmaster\.conf"/)
      end
      it "set the owner as the owner" do
        @compiled.should match(/owner => "herman"/)
      end
      it "have the mode set in the puppet output" do
        @compiled.should match(/mode => 755/)
      end
    end
  end
end
