require File.dirname(__FILE__) + '/../spec_helper'

class DependencyResolverCloudExtensionsSpecBase < PoolParty::PoolPartyBaseClass
  include PoolParty::Configurable  
end

# files, directories, etc...
class DependencyResolverSpecTestResource
  include PoolParty::Configurable
  include PoolParty::DependencyResolverResourceExtensions
end

# plugins, base_packages
class DependencyResolverSpecTestService < DependencyResolverCloudExtensionsSpecBase
  
end

# clouds, duh
class DependencyResolverSpecTestCloud < DependencyResolverCloudExtensionsSpecBase
end

class JunkClassForDefiningPlugin
  plugin :apache do  
  end  
end

describe "Resolution spec" do
  before(:each) do
    @apache_file = DependencyResolverSpecTestResource.new
    @apache_file.name "/etc/apache2/apache2.conf"
    @apache_file.template "/absolute/path/to/template"
    @apache_file.content "rendered template string"
    
    @apache = DependencyResolverSpecTestService.new :apache_file
    @apache.listen "8080"
    @apache.resources[:file] = []
    @apache.resources[:file] << @apache_file
        
    @cloud = DependencyResolverSpecTestCloud.new :cloud
    @cloud.keypair "bob"
    @cloud.name "dog"
    
    @cloud.services[:apache] = @apache

    @cloud_file_motd = DependencyResolverSpecTestResource.new
    @cloud_file_motd.name "/etc/motd"
    @cloud_file_motd.content "Welcome to the cloud"
    
    @cloud_file_profile = DependencyResolverSpecTestResource.new
    @cloud_file_profile.name "/etc/profile"
    @cloud_file_profile.content "profile info"
        
    @cloud.resources[:file] = []
    @cloud.resources[:file] << @cloud_file_motd
    @cloud.resources[:file] << @cloud_file_profile
    
    @cloud_directory_var_www = DependencyResolverSpecTestResource.new
    @cloud_directory_var_www.name "/var/www"
    
    @cloud.resources[:directory] = []
    @cloud.resources[:directory] << @cloud_directory_var_www    
  end
  it "be able to call to_properties_hash" do
    @cloud.respond_to?(:to_properties_hash).should == true
  end
  describe "to_properties_hash" do
    it "should output a hash" do
      @cloud.to_properties_hash.class.should == Hash
      # puts "<pre>#{@cloud.to_properties_hash.to_yaml}</pre>"
    end
    it "should have resources on the cloud as an array of hashes" do
      @cloud.to_properties_hash[:resources].class.should == Hash      
    end
    it "should have services on the cloud as an array of hashes" do
      @cloud.to_properties_hash[:services].class.should == Hash      
    end
    it "have options set on the cloud as a hash" do
      @cloud.to_properties_hash[:options].class.should == Hash
    end
  end

  describe "defined cloud" do
    before(:each) do
      @file = "Hello <%= friends %> on port <%= listen %>"
      @file.stub!(:read).and_return @file
      Template.stub!(:open).and_return @file
      
      @cloud = cloud :dog do
        keypair "bob"
        has_file :name => "/etc/motd", :content => "Welcome to the cloud"
        has_file :name => "/etc/profile", :content => "profile info"
        has_directory :name => "/var/www"
        has_package :name => "bash"
        # parent == cloud
        apache do
          # parent == apache
          listen "8080"
          has_file :name => "/etc/apache2/apache2.conf", :template => "/absolute/path/to/template", :friends => "bob"
        end
      end
      @properties = cloud(:dog).to_properties_hash
    end
    
    it "should have the method to_properties_hash on the cloud" do
      cloud(:dog).respond_to?(:to_properties_hash).should == true
    end
    it "should have resources on the cloud as an array of hashes" do
      # puts "<pre>#{cloud(:dog).to_properties_hash.to_yaml}</pre>"
      @properties[:resources].class.should == Hash
    end
    it "contain content in the template's hash" do
      apache_key = cloud(:dog).to_properties_hash[:services].keys.first.to_sym
      puts @properties[:services][apache_key].resources
      @properties[:services][apache_key].resources[:file].first[:content].should == "Hello bob on port 8080"
    end
    it "contain the files in a hash" do
      # puts "<pre>#{@properties.to_yaml}</pre>"
      @properties[:resources][:file].map {|a| a[:name] }.include?("/etc/motd").should == true
    end
    it "contain the directory named /var/www" do
      @properties[:resources][:directory].map {|a| a[:name] }.include?("/var/www").should == true
    end
  end
end