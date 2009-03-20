require File.dirname(__FILE__) + '/../spec_helper'

class TestGitClass < PoolParty::Cloud::Cloud
end

describe "Remote Instance" do
  describe "wrapped" do
    before(:each) do
      @tc = cloud :test_git_class_cloud do
        has_git_repos(:at => "/var/www/", :name => "gitrepos.git", :source => "git://source.git", :requires_user => "finger")
        puts "services: #{services.git_repos_class}"
      end
      @compiled = PuppetResolver.new(@tc.to_properties_hash).compile
    end
    it "should be a string" do
      puts "<pre>"+@tc.to_properties_hash.inspect+"</pre>"
      @compiled.should =~ /exec/
    end
    it "should included the flushed out options" do
      @compiled.should =~ /finger@git:/
    end
    it "should not include the user if none is given" do
      @compiled.should =~ /git clone git:/
    end
    describe "in resource" do
      before(:each) do
        @tc.instance_eval do
          has_git_repos(:name => "gittr") do
            source "git://source.git"
            path "/var/www/xnot.org"
            symlink "/var/www/xnot.org/public"
            at "/var/www"
          end
        end
      end
      it "should have the path set within the resource" do
        @tc.resource(:git_repos).first.to_string.should =~ /exec \{ \"git-gittr/
      end
    end
  end
end