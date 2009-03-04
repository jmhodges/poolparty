require File.dirname(__FILE__) + '/../spec_helper'

class DependencyResolverCloudExtensionsSpecBase
  include PoolParty::Configurable
  include PoolParty::DependencyResolverCloudExtensions
  
  def services
    @services ||= {}
  end
  def resources
    @resources ||= {}
  end
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

@cloud_reference_hash = {
  :options => {:name => "dog", :keypair => "bob"},
  :resources => {
    :file =>  [
                {:name => "/etc/motd", :content => "Welcome to the cloud"},
                {:name => "/etc/profile", :content => "profile info"}
              ],
    :directory => [
                    {:name => "/var/www"}
                  ]    
  },
  :services => {
    :apache => {
      :options => {:listen => "8080"},
      :resources => {
                      :file => [
                          {:name => "/etc/apache2/apache2.conf", :template => "/absolute/path/to/template", :content => "rendered template string"}
                        ]
                    },
      :services => {}
    }
  }
}

describe "Resolution spec" do
  before(:each) do
    @apache_file = DependencyResolverSpecTestResource.new
    @apache_file.name "/etc/apache2/apache2.conf"
    @apache_file.template "/absolute/path/to/template"
    @apache_file.content "rendered template string"
    
    @apache = DependencyResolverSpecTestService.new
    @apache.listen "8080"
    @apache.resources[:file] = []
    @apache.resources[:file] << @apache_file
        
    @cloud = DependencyResolverSpecTestCloud.new
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
      @cloud.to_properties_hash[:resources].first.class.should == Hash      
    end
    it "should have services on the cloud as an array of hashes" do
      @cloud.to_properties_hash[:services].first.class.should == Hash      
    end
    it "have options set on the cloud as a hash" do
      @cloud.to_properties_hash[:options].class.should == Hash
    end
  end

  describe "defined cloud" do
    before(:each) do
      @file = "Hello <%= name %>"
      @file.stub!(:read).and_return @file
      Template.stub!(:open).and_return @file
      
      @cloud = cloud :dog do
        keypair "bob"
        has_file :name => "/etc/motd", :content => "Welcome to the cloud"
        has_file :name => "/etc/profile", :content => "profile info"
        has_directory :name => "/var/www"
        # parent = cloud
        apache do
          # parent = apache
          listen "8080"
          has_file :name => "/etc/apache2/apache2.conf", :template => "/absolute/path/to/template"
        end
      end      
    end
    
    it "should have the method to_properties_hash on the cloud" do
      cloud(:dog).respond_to?(:to_properties_hash).should == true
    end
    it "should have resources on the cloud as an array of hashes" do
      puts cloud(:dog).to_properties_hash
      cloud(:dog).to_properties_hash[:resources].first.class.should == Hash
    end
  end
end