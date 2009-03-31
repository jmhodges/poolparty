require File.dirname(__FILE__) + '/../spec_helper'

include PoolParty::Resources
require File.dirname(__FILE__) + '/test_plugins/webserver'

describe "Plugin" do
  describe "wrapped" do
    before(:each) do
      cloud :app_for_plugin do
        apache do
          enable_php
          site("heady", {
            :document_root => "/root"
          })
        end
        apache do
          site("boob")
        end
      end
      @plugin = clouds[:app_for_plugin].apache
    end
    it "should not be empty" do
      clouds[:app_for_plugin].apache.class.should == ApacheClass
    end
    it "should set loaded == true" do
      clouds[:app_for_plugin].apache.loaded.should == true
    end
    it "should have enable_php as a method" do
      ApacheClass.new.respond_to?(:enable_php).should == true
    end
    it "should set enable_php" do
      @plugin.enable_php.should == true
    end
    it "should store the plugin in the clouds plugin_store" do
      clouds[:app_for_plugin].plugin_store.should == [@plugin]
      clouds[:app_for_plugin].apache
      clouds[:app_for_plugin].plugin_store.should == [@plugin]
    end
  end
end