require File.dirname(__FILE__) + '/spec_helper'

class TestRemote
  include Remoter
  include Callbacks
  attr_accessor :ip
end
describe "Remoter" do
  before(:each) do
    @remoter = TestRemote.new    
    @remoter.stub!(:put).and_return "true"
    @tempfile = Tempfile.new("/tmp") do |f|
      f << "hi"
    end
    Application.stub!(:keypair_path).and_return "app"
    Application.stub!(:username).and_return "root"
  end
end