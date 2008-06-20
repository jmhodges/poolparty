require File.dirname(__FILE__) + '/spec_helper'

describe "Pool binary" do
  describe "running" do
    it "should call PoolParty.options" do
      options = PoolParty.options(:optsparse => {:banner => "Usage: pool [OPTIONS] {start | stop | list | maintain | restart}"  })
    end
    
  end
end