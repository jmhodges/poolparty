require File.dirname(__FILE__) + '/spec_helper'

describe "Proxy" do

  before(:each) do
    @proxy = Proxy.new
  end
  
  describe "in general" do
    it "should be able to return the list_of_proxies as an Array" do
      @proxy.list_of_proxies.class.should == Array
    end
  end
end