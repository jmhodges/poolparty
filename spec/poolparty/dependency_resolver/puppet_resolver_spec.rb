require File.dirname(__FILE__) + '/../spec_helper'

describe "PuppetResolver" do
  before :all do
    @cloud_reference_hash = {
      :options => {:name => "dog", :keypair => "bob", :users => ["ari", "michael"]},
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
  end
  
  it "throw an exception if not given a hash" do
    lambda { PuppetResolver.compile()}.should raise_error
  end
  it "accept a hash" do
    lambda { PuppetResolver.compile({})}.should_not raise_error
  end
  
  describe "when passed a valid cloud hash" do
    before(:all) do
      @dr = PuppetResolver.new(@cloud_reference_hash)
      @compiled = @dr.compile
    end
    it "output options as puppet variables" do
      @compiled.should match(/bob/)
      @compiled.instance_of?(String).should == true
      @compiled.should match(/\$users = \[ \".* \]/)
    end
  end
end