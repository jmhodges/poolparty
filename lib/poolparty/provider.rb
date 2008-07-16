module PoolParty
  class Provider
    include Sprinkle
        
    def install_poolparty
      PoolParty.message "Installing required poolparty paraphernalia"
      load_packages
      user_packages.map {|blk| blk.call if blk }

      policy :poolparty, :roles => :app do
        requires :git
        requires :ruby
        requires :heartbeat
        requires :haproxy
        requires :s3fs
        requires :rsync
        requires :required_gems
        
        PoolParty::Provider.user_install_packages.each do |req|
          requires req.to_sym
        end
      end
      
      set_start_with_sprinkle
      @deployment.process if @deployment
    end
        
    def self.define_custom_package name=:userpackages, &block
      (user_install_packages << name).uniq!
      user_packages << block
    end
    
    def user_packages
      self.class.user_packages
    end
    
    def user_install_packages
      self.class.user_install_packages
    end
    
    def self.user_packages
      @user_packages ||= []
    end
    
    def self.user_install_packages
      @load_strings ||= []
    end
    
    def load_packages
      Dir["#{File.expand_path(File.dirname(__FILE__))}/provider/*"].each do |f| 
        load f
      end
    end
    
    def set_start_with_sprinkle
      deployment do
        delivery :vlad do
          set :user, "#{Application.username}"
          
          Master.cloud_ips.each do |ip|
            role :app, "#{Application.username}@#{ip}"
          end
        end
  
        source do
          prefix   '/usr/local'
          archives '/root/sources'
          builds   '/root/builds'
        end    
      end
      
    end
            
    class << self
      require "sprinkle"
            
      def install_poolparty
        singleton.install_poolparty
      end
      def singleton
        @singleton ||= new
      end
    end
    
  end
end