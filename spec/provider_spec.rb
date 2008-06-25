require File.dirname(__FILE__) + '/spec_helper'

describe "Provider" do
  before(:each) do
    stub_option_load
    @ips = ["127.0.0.1"]
  end
  it "should be able to make a roles from the ips" do
    Provider.string_roles_from_ips(@ips).should == "role :app, '127.0.0.1'"
  end
  describe "running" do
    it "should be able to run with the provided packages" do
      Sprinkle::Script.should_receive(:sprinkle).once.and_return true
      Provider.should_receive(:string_roles_from_ips).with(@ips).and_return ""
      Provider.install_poolparty(@ips)
    end
  end
end