module PoolParty
  class Provider
    include Sprinkle
    
    class << self
      require "sprinkle"
      attr_accessor :user_packages      
    end
    
    def self.install_poolparty
      PoolParty.message "Installing required poolparty paraphernalia"
      load_packages
      user_packages.map {|blk| blk.call if blk }

      policy :poolparty, :roles => :app do
        requires :git
        requires :ruby
        requires :failover
        requires :proxy
        requires :s3fs
        requires :rsync
        requires :required_gems
        
        PoolParty::Provider.user_install_packages.each do |req|
          requires req.to_sym
        end
      end
      
      set_start_with_sprinkle
      sprinkle
    end
        
    def self.define_custom_package name=:userpackages, &block
      (user_install_packages << name).uniq!
      user_packages << block
    end
    
    def self.singleton
      @klass ||= new
    end
    
    def self.user_packages
      @user_packages ||= []
    end
    
    def self.user_install_packages
      @load_strings ||= []
    end
    
    def self.load_packages
      Dir["#{File.expand_path(File.dirname(__FILE__))}/provider/*"].each {|f| singleton.instance_eval f }
    end
    
    def self.set_start_with_sprinkle
      
      deployment do
        delivery :vlad do
          set :user, "#{Application.username}"
    
          PoolParty::Provider.string_roles_from_ips
        end
  
        source do
          prefix   '/usr/local'
          archives '/root/sources'
          builds   '/root/builds'
        end
    
      end
    end
        
    def self.string_roles_from_ips
      Master.cloud_ips.collect do |ip|
        "role :app, '#{Application.username}@#{ip}'"
      end.join("\n")
    end
    
  end
end