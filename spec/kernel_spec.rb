require File.dirname(__FILE__) + '/spec_helper'

describe "Kernel extensions" do
  before(:each) do
    @host = Master.new
  end
  it "should eval the string into time" do
    @host.should_receive(:sleep).once.and_return true
    @host.wait "10.seconds"
  end
end