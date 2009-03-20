require File.dirname(__FILE__) + '/../spec_helper'

include PoolParty::Resources
require File.dirname(__FILE__) + '/test_plugins/webserver'

describe "Plugin" do
  describe "wrapped" do
    before(:each) do
      cloud :app_for_plugin do
      end      
      @c = cloud(:app_for_plugin)
      @plugin = @c.apache do
        enable_php
        site("heady", {
          :document_root => "/root"
        })
      end
    end
    it "should not be empty" do
      @plugin.class.should == ApacheClass
    end
    it "should have enable_php as a method" do
      ApacheClass.new.respond_to?(:enable_php).should == true
    end    
  end
end