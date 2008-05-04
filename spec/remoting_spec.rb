require File.dirname(__FILE__) + '/spec_helper'

describe "Remoting" do
  before(:each) do
    @remoting = Remoting.new
  end
  describe "Host" do
    it "should be able to connect to s3 when required" do
      @remoting.connect_to_s3!.should_not be_nil
    end
    it "should be able to fetch the config from the specified file" do
      @remoting.access_key_id.should_not be_nil
    end
  end
  describe "Client remoting" do
    it "should be able to connect to s3 when required, from the user-data"
  end
end