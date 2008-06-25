require File.dirname(__FILE__) + '/spec_helper'

describe "Pool binary" do
  describe "running" do
    before(:each) do
      stub_option_load
    end
    it "should call PoolParty.options" do
      options = PoolParty.options(:optsparse => {:banner => "Usage: pool [OPTIONS] {start | stop | list | maintain | restart}"  })
    end
    
  end
end